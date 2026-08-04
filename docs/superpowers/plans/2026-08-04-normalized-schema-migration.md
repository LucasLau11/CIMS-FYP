# Normalized Schema Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a new Supabase project whose schema exactly matches the normalized ERD at `C:\Users\Lucas\Downloads\CIMS_ERD.xml` (28 tables, incl. subtype tables for each profile role and split review/interview tables), rewire the existing Flutter app's 9 database-access service files to it, and preserve every existing feature and screen with no UI changes.

**Architecture:** `PROFILES` becomes a thin base table (shared columns only); each of the six roles gets its own 1:1 subtype table keyed by `profile_id`. `INTERNSHIPS` splits into `JOB_POSTINGS` + `CATEGORIES`. `APPLICATIONS` sheds its interview columns into `INTERVIEWS`. `REPORTS` sheds both review stages into `ACADEMIC_REPORT_REVIEWS` and `COMPANY_REPORT_REVIEWS`. `DOCUMENTS` sheds its review stage into `DOCUMENT_REVIEWS`. `CONVERSATIONS.participant_a/b` becomes the `PROFILE_CONVERSATIONS` junction table. Everything else keeps its current shape plus the columns the live schema already has that the diagram-only version was missing. Screens are untouched — all DB access is already isolated to `lib/services/*.dart`, confirmed by a full-codebase grep (9 files, 183 query call sites, zero direct Supabase calls from screens).

**Tech Stack:** Supabase (Postgres 17, RLS, Storage, Edge Functions), Flutter/Dart (`supabase_flutter`), OneSignal (push), tracked SQL migrations under `supabase/migrations/`.

## Global Constraints

- Every schema change in this plan is a numbered file under `supabase/migrations/`, committed to git — no ad-hoc SQL applied directly and left untracked. This is the durability fix the whole project is built around: future tutor-requested ERD changes become one new migration file, not a rebuild.
- The new project must be validated on a disposable free-tier "scratch" project (or directly, if the user accepts the row-count-zero risk) before being treated as final — this plan assumes the target IS the final project, per the user's decision to accept full reconfiguration.
- No screen file (`lib/screens/**`) may be modified except where a screen currently reads a field that changed name/location (verified case-by-case in Task 25's regression pass) — the UI layer must stay behavior-identical.
- All Supabase access stays confined to the 9 files in `lib/services/`. No screen may call `Supabase.instance.client` directly.
- Every table gets RLS enabled; no table ships with RLS off.
- Reuse (do not regenerate): OneSignal App ID and REST API key values. Everything else (Supabase URL/keys, storage buckets, Edge Function deployment, Database Webhooks, `auth.users`, all rows) is created fresh.
- Verification per task: `flutter analyze` must show zero new errors, `mcp__<supabase>__get_advisors` (security + performance) must show zero new findings introduced by this migration, and any RLS-sensitive change gets a manual `execute_sql` check impersonating each affected role before being marked done.

---

## Task 1: Bootstrap new Supabase project with tracked migrations

**Files:**
- Create: `supabase/config.toml` (via `supabase init`)
- Create: `supabase/migrations/` directory
- Modify: `lib/main.dart` (placeholder URL/key — real values wired in Task 20)

**Steps:**
- [ ] Create the new Supabase project (new org or existing, user's call) via `create_project`. Record its `project_id`, URL, and anon/publishable key.
- [ ] In the Flutter project root, run `npx supabase init` to scaffold `supabase/config.toml` and `supabase/migrations/`.
- [ ] Run `npx supabase login`, then `npx supabase link --project-ref <new-project-id>`.
- [ ] Commit the scaffold: `git add supabase/config.toml supabase/migrations/.gitkeep && git commit -m "chore: initialize tracked Supabase migrations"`.
- [ ] Verify: `npx supabase migration list` runs without error against the linked project.

---

## Task 2: Core identity schema — PROFILES + 6 subtype tables

**Files:**
- Create: `supabase/migrations/00001_profiles_and_subtypes.sql`

**Interfaces:**
- Produces: `profiles(profile_id uuid PK)`, `students`, `academic_supervisors`, `parents`, `company_hr`, `company_supervisors`, `administrators` — every later table's `student_id`/`reviewer_id`/`supervisor_id`/etc. FK references land on `profiles.profile_id` (the shared identity space), never on a subtype table's PK directly, since a subtype PK *is* `profiles.profile_id` (shared-PK pattern).
- Consumes: nothing (first table group).

```sql
create table profiles (
  profile_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('student','academic_supervisor','company_hr','company_supervisor','parent','admin')),
  email text not null,
  full_name text,
  avatar_url text,
  phone text,
  date_of_birth date,
  address_text text,
  address_lat double precision,
  address_lng double precision,
  language text not null default 'English',
  notification_prefs jsonb not null default '{"messages": true, "report_deadlines": true, "application_updates": true, "supervisor_feedback": false}'::jsonb,
  theme_mode text not null default 'system' check (theme_mode in ('light','dark','system')),
  created_at timestamptz not null default now()
);

create table companies (
  company_id uuid primary key default gen_random_uuid(),
  name text not null,
  industry text,
  location text,
  hr_contact_name text,
  hr_contact_email text,
  hr_contact_phone text,
  status text not null default 'pending' check (status in ('pending','verified')),
  created_at timestamptz not null default now()
);

create table students (
  profile_id uuid primary key references profiles(profile_id) on delete cascade,
  academic_supervisor_id uuid references profiles(profile_id),
  programme text,
  semester integer,
  faculty text,
  cgpa numeric,
  skills text[] not null default '{}',
  resume_path text,
  resume_filename text,
  resume_size_bytes bigint,
  resume_uploaded_at timestamptz,
  student_reg_no text
);

create table academic_supervisors (
  profile_id uuid primary key references profiles(profile_id) on delete cascade
);

create table parents (
  profile_id uuid primary key references profiles(profile_id) on delete cascade
);

create table company_hr (
  profile_id uuid primary key references profiles(profile_id) on delete cascade,
  company_id uuid references companies(company_id)
);

create table company_supervisors (
  profile_id uuid primary key references profiles(profile_id) on delete cascade,
  company_id uuid references companies(company_id)
);

create table administrators (
  profile_id uuid primary key references profiles(profile_id) on delete cascade
);

-- role-consistency guard: a profile can only have a row in the subtype table matching its role
create or replace function assert_subtype_role(p_profile_id uuid, p_expected_role text)
returns void language plpgsql as $$
begin
  if not exists (select 1 from profiles where profile_id = p_profile_id and role = p_expected_role) then
    raise exception 'profile % is not role %', p_profile_id, p_expected_role;
  end if;
end;
$$;

create or replace function trg_check_student_role() returns trigger language plpgsql as $$
begin perform assert_subtype_role(new.profile_id, 'student'); return new; end; $$;
create trigger check_student_role before insert or update on students
  for each row execute function trg_check_student_role();

create or replace function trg_check_academic_supervisor_role() returns trigger language plpgsql as $$
begin perform assert_subtype_role(new.profile_id, 'academic_supervisor'); return new; end; $$;
create trigger check_academic_supervisor_role before insert or update on academic_supervisors
  for each row execute function trg_check_academic_supervisor_role();

create or replace function trg_check_parent_role() returns trigger language plpgsql as $$
begin perform assert_subtype_role(new.profile_id, 'parent'); return new; end; $$;
create trigger check_parent_role before insert or update on parents
  for each row execute function trg_check_parent_role();

create or replace function trg_check_company_hr_role() returns trigger language plpgsql as $$
begin perform assert_subtype_role(new.profile_id, 'company_hr'); return new; end; $$;
create trigger check_company_hr_role before insert or update on company_hr
  for each row execute function trg_check_company_hr_role();

create or replace function trg_check_company_supervisor_role() returns trigger language plpgsql as $$
begin perform assert_subtype_role(new.profile_id, 'company_supervisor'); return new; end; $$;
create trigger check_company_supervisor_role before insert or update on company_supervisors
  for each row execute function trg_check_company_supervisor_role();

create or replace function trg_check_administrator_role() returns trigger language plpgsql as $$
begin perform assert_subtype_role(new.profile_id, 'admin'); return new; end; $$;
create trigger check_administrator_role before insert or update on administrators
  for each row execute function trg_check_administrator_role();
```

**RLS + helper functions:**

```sql
create or replace function current_user_role() returns text
language sql stable security definer set search_path = public as $$
  select role from profiles where profile_id = auth.uid();
$$;

create or replace function is_academic_supervisor_of(p_student_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from students where profile_id = p_student_id and academic_supervisor_id = auth.uid());
$$;

create or replace function is_approved_parent_of(p_student_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from parent_child_links
    where student_id = p_student_id and parent_id = auth.uid() and status = 'approved'
  );
$$;

create or replace function is_my_company(p_company_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from company_hr where profile_id = (select auth.uid()) and company_id = p_company_id
    union
    select 1 from company_supervisors where profile_id = (select auth.uid()) and company_id = p_company_id
  );
$$;

alter table profiles enable row level security;
alter table companies enable row level security;
alter table students enable row level security;
alter table academic_supervisors enable row level security;
alter table parents enable row level security;
alter table company_hr enable row level security;
alter table company_supervisors enable row level security;
alter table administrators enable row level security;

create policy profiles_select_authenticated on profiles for select to authenticated using (true);
create policy profiles_update_own_or_admin on profiles for update to authenticated
  using (profile_id = (select auth.uid()) or (select current_user_role()) = 'admin')
  with check (profile_id = (select auth.uid()) or (select current_user_role()) = 'admin');
create policy profiles_insert_own on profiles for insert to authenticated
  with check (profile_id = (select auth.uid()));

create policy companies_select_authenticated on companies for select to authenticated using (true);
create policy companies_update_own_staff on companies for update to authenticated
  using (is_my_company(company_id) or (select current_user_role()) = 'admin')
  with check (is_my_company(company_id) or (select current_user_role()) = 'admin');
create policy companies_insert_self_service on companies for insert to authenticated
  with check ((select current_user_role()) in ('company_hr','company_supervisor','admin'));

-- Subtype tables: readable same as base profile row; writable by the profile owner or admin.
create policy students_select_authenticated on students for select to authenticated using (true);
create policy students_update_own_or_staff on students for update to authenticated
  using (profile_id = (select auth.uid()) or (select current_user_role()) = 'admin'
         or is_academic_supervisor_of(profile_id));
create policy students_insert_own on students for insert to authenticated
  with check (profile_id = (select auth.uid()));

create policy academic_supervisors_select_authenticated on academic_supervisors for select to authenticated using (true);
create policy academic_supervisors_insert_own on academic_supervisors for insert to authenticated
  with check (profile_id = (select auth.uid()));

create policy parents_select_authenticated on parents for select to authenticated using (true);
create policy parents_insert_own on parents for insert to authenticated
  with check (profile_id = (select auth.uid()));

create policy company_hr_select_authenticated on company_hr for select to authenticated using (true);
create policy company_hr_update_own on company_hr for update to authenticated
  using (profile_id = (select auth.uid()) or (select current_user_role()) = 'admin');
create policy company_hr_insert_own on company_hr for insert to authenticated
  with check (profile_id = (select auth.uid()));

create policy company_supervisors_select_authenticated on company_supervisors for select to authenticated using (true);
create policy company_supervisors_update_own on company_supervisors for update to authenticated
  using (profile_id = (select auth.uid()) or (select current_user_role()) = 'admin');
create policy company_supervisors_insert_own on company_supervisors for insert to authenticated
  with check (profile_id = (select auth.uid()));

create policy administrators_select_authenticated on administrators for select to authenticated using (true);
create policy administrators_insert_admin_only on administrators for insert to authenticated
  with check ((select current_user_role()) = 'admin');
```

> **Post-review correction (applied live, plan text updated to match):** the
> original draft here used a `same_company_as(target_profile_id)` helper
> that compared the caller against themselves when called as
> `same_company_as(auth.uid())` — it never referenced the row being
> evaluated, so it collapsed to "does the caller belong to any company at
> all," letting any company_hr/company_supervisor update *every* company's
> row. Replaced with `is_my_company(company_id)`, called against the actual
> row's `company_id` column everywhere it's used (here, and in Tasks 3–4
> below). Also wrapped bare `auth.uid()`/`current_user_role()` calls in
> `(select ...)` throughout (Postgres `auth_rls_initplan` — evaluates once
> per query instead of once per row) and merged `profiles`' two UPDATE
> policies into one (`multiple_permissive_policies`). Apply the same
> `(select ...)` wrapping pattern to every RLS policy in Tasks 5–9 as they're
> written, not just 2–4.

- [ ] Write the migration file with the SQL above.
- [ ] Apply via `apply_migration` (or `npx supabase db push`).
- [ ] Verify: `list_tables` shows all 8 tables with `rls_enabled: true`; `get_advisors` (security **and performance**) returns no new findings for these tables (the 5 helper functions being `authenticated`-executable is an accepted, unavoidable residual — see Task 2's ledger).
- [ ] Verify: as a test student (once Task 22 seed data exists), `execute_sql` impersonation confirms a student can update their own `students` row but not another student's, and that a company_hr/company_supervisor can update their own company's row but not another company's.
- [ ] Index every FK column added in this task's DDL if `get_advisors(performance)` flags it unindexed.
- [ ] Commit.

---

## Task 3: Categories + Job Postings + Applications + Interviews

**Files:**
- Create: `supabase/migrations/00002_postings_and_applications.sql`

**Interfaces:**
- Consumes: `profiles`, `students`, `companies` (Task 2).
- Produces: `job_postings.job_posting_id`, `applications.application_id` — consumed by Task 4 (reports don't reference these, but `document_submissions` and messaging don't either; this group is self-contained downstream of Task 2).

```sql
create table categories (
  category_id uuid primary key default gen_random_uuid(),
  category_name text not null unique
);

create table job_postings (
  job_posting_id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(company_id),
  category_id uuid references categories(category_id),
  status text not null default 'open' check (status in ('open','closed')),
  title text not null,
  description text,
  location text,
  duration_months integer,
  allowance_month numeric,
  required_skills text[] not null default '{}',
  job_type text,
  application_deadline date,
  posting_closes_at timestamptz,
  posted_at timestamptz not null default now()
);

create table applications (
  application_id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(profile_id),
  job_posting_id uuid not null references job_postings(job_posting_id),
  status text not null default 'pending' check (status in ('pending','interview','active','rejected')),
  cover_letter text,
  skills text[] not null default '{}',
  applied_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table interviews (
  interview_id uuid primary key default gen_random_uuid(),
  application_id uuid not null references applications(application_id),
  scheduled_at timestamptz,
  mode text check (mode in ('online','in_person')),
  location text
);

alter table categories enable row level security;
alter table job_postings enable row level security;
alter table applications enable row level security;
alter table interviews enable row level security;

create policy categories_select_authenticated on categories for select to authenticated using (true);
create policy categories_write_admin on categories for all to authenticated
  using ((select current_user_role()) = 'admin') with check ((select current_user_role()) = 'admin');

create policy job_postings_select_authenticated on job_postings for select to authenticated using (true);
create policy job_postings_write_own_company on job_postings for all to authenticated
  using (is_my_company(company_id) or (select current_user_role()) = 'admin')
  with check (is_my_company(company_id) or (select current_user_role()) = 'admin');

create policy applications_select_involved on applications for select to authenticated
  using (
    student_id = (select auth.uid())
    or (select current_user_role()) = 'admin'
    or exists (select 1 from job_postings jp where jp.job_posting_id = applications.job_posting_id and is_my_company(jp.company_id))
    or is_academic_supervisor_of(student_id)
    or is_approved_parent_of(student_id)
  );
create policy applications_insert_own on applications for insert to authenticated
  with check (student_id = (select auth.uid()));
create policy applications_update_involved on applications for update to authenticated
  using (
    student_id = (select auth.uid())
    or (select current_user_role()) = 'admin'
    or exists (select 1 from job_postings jp where jp.job_posting_id = applications.job_posting_id and is_my_company(jp.company_id))
  );

create policy interviews_select_involved on interviews for select to authenticated
  using (exists (
    select 1 from applications a where a.application_id = interviews.application_id
    and (a.student_id = (select auth.uid()) or (select current_user_role()) = 'admin'
         or exists (select 1 from job_postings jp where jp.job_posting_id = a.job_posting_id and is_my_company(jp.company_id)))
  ));
create policy interviews_write_company on interviews for all to authenticated
  using (exists (
    select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
    where a.application_id = interviews.application_id and (is_my_company(jp.company_id) or (select current_user_role()) = 'admin')
  ));

create index if not exists idx_job_postings_company_id on job_postings(company_id);
create index if not exists idx_job_postings_category_id on job_postings(category_id);
create index if not exists idx_applications_student_id on applications(student_id);
create index if not exists idx_applications_job_posting_id on applications(job_posting_id);
create index if not exists idx_interviews_application_id on interviews(application_id);
```

- [ ] Write, apply, verify (`list_tables`, `get_advisors` security **and performance**, RLS impersonation for student/HR/company_supervisor).
- [ ] Commit.

---

## Task 4: Reports + Academic/Company Report Reviews

**Files:**
- Create: `supabase/migrations/00003_reports_and_reviews.sql`

```sql
create table reports (
  report_id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(profile_id),
  type text not null check (type in ('monthly','final')),
  period_label text not null,
  notes text,
  storage_path text,
  file_name text,
  file_size_bytes bigint,
  submitted_at timestamptz not null default now()
);

create table academic_report_reviews (
  academic_report_review_id uuid primary key default gen_random_uuid(),
  report_id uuid not null unique references reports(report_id),
  reviewer_id uuid references profiles(profile_id),
  status text not null default 'submitted' check (status in ('submitted','approved','rejected')),
  feedback text,
  reviewed_at timestamptz
);

create table company_report_reviews (
  company_report_review_id uuid primary key default gen_random_uuid(),
  report_id uuid not null unique references reports(report_id),
  reviewer_id uuid references profiles(profile_id),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  feedback text,
  reviewed_at timestamptz
);

alter table reports enable row level security;
alter table academic_report_reviews enable row level security;
alter table company_report_reviews enable row level security;

create policy reports_select_involved on reports for select to authenticated
  using (student_id = (select auth.uid()) or (select current_user_role()) = 'admin'
         or is_academic_supervisor_of(student_id) or is_approved_parent_of(student_id)
         or exists (select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
                     where a.student_id = reports.student_id and is_my_company(jp.company_id)));
create policy reports_insert_own on reports for insert to authenticated with check (student_id = (select auth.uid()));

create policy academic_report_reviews_select_involved on academic_report_reviews for select to authenticated
  using (exists (select 1 from reports r where r.report_id = academic_report_reviews.report_id
                 and (r.student_id = (select auth.uid()) or (select current_user_role()) = 'admin' or is_academic_supervisor_of(r.student_id))));
create policy academic_report_reviews_write_supervisor on academic_report_reviews for all to authenticated
  using ((select current_user_role()) = 'admin'
         or exists (select 1 from reports r where r.report_id = academic_report_reviews.report_id and is_academic_supervisor_of(r.student_id)));

create policy company_report_reviews_select_involved on company_report_reviews for select to authenticated
  using (exists (select 1 from reports r where r.report_id = company_report_reviews.report_id
                 and (r.student_id = (select auth.uid())
                      or exists (select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
                                  where a.student_id = r.student_id and is_my_company(jp.company_id)))));
create policy company_report_reviews_write_company_supervisor on company_report_reviews for all to authenticated
  using (exists (select 1 from reports r join applications a on a.student_id = r.student_id
                 join job_postings jp on jp.job_posting_id = a.job_posting_id
                 where r.report_id = company_report_reviews.report_id and is_my_company(jp.company_id)
                 and (select current_user_role()) = 'company_supervisor'));

create index if not exists idx_reports_student_id on reports(student_id);
create index if not exists idx_academic_report_reviews_reviewer_id on academic_report_reviews(reviewer_id);
create index if not exists idx_company_report_reviews_reviewer_id on company_report_reviews(reviewer_id);
```

> Note: per the earlier RLS finding, admin does **not** get `company_report_reviews` write access — that boundary is intentional (confirmed by the user) and preserved here.
>
> **Post-review correction (see Task 2's note):** replaced `same_company_as(auth.uid())` with `is_my_company(jp.company_id)`, correlated against the joined `job_postings` row rather than the caller compared to themselves. Wrapped bare `auth.uid()`/`current_user_role()` calls in `(select ...)`.

- [ ] Write, apply, verify (impersonate student/academic_supervisor/company_supervisor/admin — confirm admin is blocked from writing `company_report_reviews`, matching current live-schema behavior).
- [ ] Verify `get_advisors` security **and performance** are both clean before marking this task done — the plan's own bar (see Task 2's ledger for why this matters).
- [ ] Commit.

---

## Task 5: Documents + Document Reviews

**Files:**
- Create: `supabase/migrations/00004_documents_and_reviews.sql`

```sql
create table documents (
  document_id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(profile_id),
  category text not null check (category in ('offer_letter','indemnity_letter','company_acceptance_letter','insurance_certificate','other')),
  status text not null default 'submitted' check (status in ('submitted','approved','rejected')),
  title text,
  storage_path text not null,
  file_name text not null,
  file_size_bytes bigint not null,
  uploaded_at timestamptz not null default now()
);

create table document_reviews (
  document_review_id uuid primary key default gen_random_uuid(),
  document_id uuid not null unique references documents(document_id),
  reviewer_id uuid references profiles(profile_id),
  feedback text,
  reviewed_at timestamptz
);

alter table documents enable row level security;
alter table document_reviews enable row level security;

create policy documents_select_involved on documents for select to authenticated
  using (student_id = auth.uid() or current_user_role() = 'admin'
         or is_academic_supervisor_of(student_id) or is_approved_parent_of(student_id));
create policy documents_insert_own on documents for insert to authenticated with check (student_id = auth.uid());
create policy documents_update_supervisor on documents for update to authenticated
  using (current_user_role() = 'admin' or is_academic_supervisor_of(student_id) or student_id = auth.uid());

create policy document_reviews_select_involved on document_reviews for select to authenticated
  using (exists (select 1 from documents d where d.document_id = document_reviews.document_id
                 and (d.student_id = auth.uid() or current_user_role() = 'admin' or is_academic_supervisor_of(d.student_id))));
create policy document_reviews_write_academic_or_admin on document_reviews for all to authenticated
  using (current_user_role() = 'admin'
         or exists (select 1 from documents d where d.document_id = document_reviews.document_id and is_academic_supervisor_of(d.student_id)));
```

> Per the earlier finding: `company_supervisor` is deliberately excluded — document review is internal (academic supervisor + admin only).

- [ ] Write, apply, verify.
- [ ] Commit.

---

## Task 6: Evaluations, Work Experiences, Company Reviews, Parent-Child Links

**Files:**
- Create: `supabase/migrations/00005_evaluations_experience_reviews_links.sql`

```sql
create table evaluations (
  evaluation_id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(profile_id),
  supervisor_id uuid not null references profiles(profile_id),
  type text not null default 'academic' check (type in ('academic','workplace')),
  scores jsonb,
  average_score numeric,
  comments text,
  created_at timestamptz not null default now()
);

create table work_experiences (
  work_experience_id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(profile_id),
  company_name text not null,
  position text not null,
  description text,
  start_year integer,
  end_year integer,
  is_current boolean not null default false,
  created_at timestamptz not null default now()
);

create table company_reviews (
  company_review_id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies(company_id),
  student_id uuid not null references students(profile_id),
  rating integer not null check (rating between 1 and 5),
  review text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table parent_child_links (
  pc_link_id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references parents(profile_id),
  student_id uuid not null references students(profile_id),
  relationship text check (relationship in ('father','mother','guardian')),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  requested_at timestamptz not null default now(),
  responded_at timestamptz
);

alter table evaluations enable row level security;
alter table work_experiences enable row level security;
alter table company_reviews enable row level security;
alter table parent_child_links enable row level security;

create policy evaluations_select_involved on evaluations for select to authenticated
  using (student_id = auth.uid() or supervisor_id = auth.uid() or current_user_role() = 'admin'
         or is_approved_parent_of(student_id));
create policy evaluations_insert_supervisor on evaluations for insert to authenticated
  with check (supervisor_id = auth.uid()
              and current_user_role() in ('academic_supervisor','company_supervisor','admin'));

create policy work_experiences_select_authenticated on work_experiences for select to authenticated using (true);
create policy work_experiences_write_own on work_experiences for all to authenticated
  using (student_id = auth.uid()) with check (student_id = auth.uid());

create policy company_reviews_select_authenticated on company_reviews for select to authenticated using (true);
create policy company_reviews_write_own on company_reviews for all to authenticated
  using (student_id = auth.uid()) with check (student_id = auth.uid());

create policy parent_child_links_select_involved on parent_child_links for select to authenticated
  using (parent_id = auth.uid() or student_id = auth.uid() or current_user_role() = 'admin');
create policy parent_child_links_insert_parent on parent_child_links for insert to authenticated
  with check (parent_id = auth.uid());
create policy parent_child_links_update_student_or_admin on parent_child_links for update to authenticated
  using (student_id = auth.uid() or current_user_role() = 'admin');
```

- [ ] Write, apply, verify.
- [ ] Commit.

---

## Task 7: Conversations, Profile Conversations, Messages

**Files:**
- Create: `supabase/migrations/00006_messaging.sql`

**Interfaces:**
- Produces: `profile_conversations(conversation_id, profile_id)` as the membership + per-participant-state table — replaces the old flat `participant_a/b` + `archived_a/b`/`muted_a/b`/`blocked_by_a/b` design. Any service method that used to check `participant_a = X or participant_b = X` now joins through `profile_conversations`.

```sql
create table conversations (
  conversation_id uuid primary key default gen_random_uuid(),
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table profile_conversations (
  conversation_id uuid not null references conversations(conversation_id) on delete cascade,
  profile_id uuid not null references profiles(profile_id) on delete cascade,
  archived boolean not null default false,
  muted boolean not null default false,
  blocked_by boolean not null default false,
  primary key (conversation_id, profile_id)
);

create table messages (
  message_id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(conversation_id) on delete cascade,
  sender_id uuid not null references profiles(profile_id),
  body text,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  attachment_path text,
  attachment_file_name text,
  attachment_size_bytes bigint,
  edited_at timestamptz,
  deleted_for uuid[] not null default '{}'
);

create or replace function is_conversation_member(p_conversation_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profile_conversations where conversation_id = p_conversation_id and profile_id = auth.uid());
$$;

alter table conversations enable row level security;
alter table profile_conversations enable row level security;
alter table messages enable row level security;

create policy conversations_select_member on conversations for select to authenticated
  using (is_conversation_member(conversation_id));
create policy conversations_insert_authenticated on conversations for insert to authenticated with check (true);

create policy profile_conversations_select_member on profile_conversations for select to authenticated
  using (is_conversation_member(conversation_id));
create policy profile_conversations_insert_self on profile_conversations for insert to authenticated
  with check (profile_id = auth.uid());
create policy profile_conversations_update_self on profile_conversations for update to authenticated
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());

create policy messages_select_member on messages for select to authenticated
  using (is_conversation_member(conversation_id));
create policy messages_insert_member on messages for insert to authenticated
  with check (sender_id = auth.uid() and is_conversation_member(conversation_id));
create policy messages_update_sender on messages for update to authenticated
  using (sender_id = auth.uid() or is_conversation_member(conversation_id)); -- non-sender member can only touch deleted_for; enforce column-level via RPC, see below

-- edit_message / delete_message_for_me RPCs replace direct client-side UPDATE for their specific fields.
create or replace function edit_message(p_message_id uuid, p_new_body text) returns void
language plpgsql security definer set search_path = public as $$
begin
  update messages set body = p_new_body, edited_at = now()
  where message_id = p_message_id and sender_id = auth.uid();
end;
$$;

create or replace function delete_message_for_me(p_message_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update messages set deleted_for = array_append(deleted_for, auth.uid())
  where message_id = p_message_id and is_conversation_member(conversation_id) and not (auth.uid() = any(deleted_for));
end;
$$;
```

- [ ] Write, apply, verify. Confirm `messages_update_sender` policy is tightened by removing the broad member-update clause once `edit_message`/`delete_message_for_me` RPCs are the only write path used by the service layer (Task 22) — flag as a TODO comment in the migration if the RPC-only approach isn't ready to enforce yet, and don't silently leave it broader than intended.
- [ ] Commit.

---

## Task 8: Notifications, Document Templates, Document Submissions, Profile Directory

**Files:**
- Create: `supabase/migrations/00007_notifications_templates_submissions_directory.sql`

```sql
create table notifications (
  notification_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(profile_id),
  title text not null,
  body text,
  type text not null check (type in ('application','report','document','message','evaluation','parent_link')),
  related_id uuid,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create table document_templates (
  template_id uuid primary key default gen_random_uuid(),
  purpose text not null,
  name text not null,
  storage_path text not null,
  page_width numeric not null,
  page_height numeric not null,
  fields jsonb not null default '[]',
  is_active boolean not null default false,
  created_by uuid not null references profiles(profile_id),
  created_at timestamptz not null default now()
);

create table document_submissions (
  submission_id uuid primary key default gen_random_uuid(),
  template_id uuid not null references document_templates(template_id),
  student_id uuid not null references students(profile_id),
  submitted_by uuid not null references profiles(profile_id),
  values jsonb not null default '{}',
  generated_pdf_path text not null,
  submitted_at timestamptz not null default now()
);

create table profile_directory (
  profile_id uuid primary key references profiles(profile_id) on delete cascade,
  full_name text,
  role text not null,
  avatar_url text,
  skills text[],
  programme text
);

alter table notifications enable row level security;
alter table document_templates enable row level security;
alter table document_submissions enable row level security;
alter table profile_directory enable row level security;

create policy notifications_select_own on notifications for select to authenticated using (user_id = auth.uid());
create policy notifications_insert_system on notifications for insert to authenticated with check (true);
create policy notifications_update_own on notifications for update to authenticated using (user_id = auth.uid());

create policy document_templates_select_authenticated on document_templates for select to authenticated using (true);
create policy document_templates_write_admin on document_templates for all to authenticated
  using (current_user_role() = 'admin') with check (current_user_role() = 'admin');

create policy document_submissions_select_involved on document_submissions for select to authenticated
  using (submitted_by = auth.uid() or student_id = auth.uid() or current_user_role() = 'admin'
         or is_approved_parent_of(student_id));
create policy document_submissions_insert_own on document_submissions for insert to authenticated
  with check (submitted_by = auth.uid() and (student_id = auth.uid() or is_approved_parent_of(student_id)));

create policy profile_directory_select_authenticated on profile_directory for select to authenticated using (true);

-- sync trigger: keeps profile_directory in step with profiles + students without the app writing to it directly
create or replace function sync_profile_directory() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_skills text[]; v_programme text;
begin
  select skills, programme into v_skills, v_programme from students where profile_id = new.profile_id;
  insert into profile_directory (profile_id, full_name, role, avatar_url, skills, programme)
  values (new.profile_id, new.full_name, new.role, new.avatar_url, v_skills, v_programme)
  on conflict (profile_id) do update set
    full_name = excluded.full_name, role = excluded.role, avatar_url = excluded.avatar_url,
    skills = excluded.skills, programme = excluded.programme;
  return new;
end;
$$;
create trigger sync_profile_directory_on_profile after insert or update on profiles
  for each row execute function sync_profile_directory();

create or replace function sync_profile_directory_from_students() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update profile_directory set skills = new.skills, programme = new.programme where profile_id = new.profile_id;
  return new;
end;
$$;
create trigger sync_profile_directory_on_student after insert or update on students
  for each row execute function sync_profile_directory_from_students();
```

- [ ] Write, apply, verify — insert a test profile, confirm `profile_directory` row appears via trigger without an explicit app-side insert.
- [ ] Commit.

---

## Task 9: Flattening views for common reads

**Files:**
- Create: `supabase/migrations/00008_views.sql`

**Rationale:** this is the durability piece — the service layer reads through these views for the highest-traffic joins, so a future column tweak inside `students`/`profiles` touches the table + the view, not every call site.

```sql
create view v_student_profile as
  select p.profile_id, p.full_name, p.email, p.avatar_url, p.phone, p.date_of_birth,
         p.address_text, p.address_lat, p.address_lng, p.language, p.notification_prefs, p.theme_mode,
         s.academic_supervisor_id, s.programme, s.semester, s.faculty, s.cgpa, s.skills,
         s.resume_path, s.resume_filename, s.resume_size_bytes, s.resume_uploaded_at, s.student_reg_no
  from profiles p join students s on s.profile_id = p.profile_id;

create view v_application_with_interview as
  select a.*, i.interview_id, i.scheduled_at as interview_scheduled_at, i.mode as interview_mode, i.location as interview_location
  from applications a left join interviews i on i.application_id = a.application_id;

create view v_report_with_reviews as
  select r.*,
         arr.status as academic_status, arr.feedback as academic_feedback, arr.reviewer_id as academic_reviewer_id, arr.reviewed_at as academic_reviewed_at,
         crr.status as company_status, crr.feedback as company_feedback, crr.reviewer_id as company_reviewer_id, crr.reviewed_at as company_reviewed_at
  from reports r
  left join academic_report_reviews arr on arr.report_id = r.report_id
  left join company_report_reviews crr on crr.report_id = r.report_id;

create view v_document_with_review as
  select d.*, dr.feedback as review_feedback, dr.reviewer_id, dr.reviewed_at
  from documents d left join document_reviews dr on dr.document_id = d.document_id;
```

> Views inherit RLS from their underlying tables automatically (Postgres enforces the base tables' RLS when querying through a view owned by the same role) — no separate RLS needed here, but verify this with `get_advisors` after creating them.

- [ ] Write, apply, verify each view returns the expected joined shape for a seeded test row (after Task 25).
- [ ] Commit.

---

## Task 10: Storage buckets + RLS

**Files:**
- Create: `supabase/migrations/00009_storage.sql`

- [ ] Create buckets (verified against the current project via `select id, name, public from storage.buckets`): `avatars` (public), `chat_attachments` (private), `document_submissions` (private), `document_templates` (private), `resumes` (private), `student_files` (private — holds both `documents` and `reports` table file uploads).
- [ ] Write RLS policies on `storage.objects` for each bucket, scoped by path convention (e.g. `{profile_id}/...`) and role, following the same `current_user_role()`/`is_academic_supervisor_of()` helpers from Task 2.
- [ ] Verify: `get_advisors` shows no "public bucket" or "missing RLS" findings.
- [ ] Commit.

---

## Task 11: Edge Function + Database Webhooks

**Files:**
- Modify: `supabase/functions/send-push-notification/index.ts` (update any query against old table/column names — audit for references to `profiles.programme`/`profiles.skills` etc. that moved to `students`, and `conversations.participant_a/b` that moved to `profile_conversations`)

- [ ] Audit `send-push-notification/index.ts` for any direct table/column references affected by the schema split; update them.
- [ ] Deploy via `deploy_edge_function` to the new project.
- [ ] Set the OneSignal REST API key as a secret on the new project (reusing the existing key value).
- [ ] Recreate the Database Webhook(s) that trigger this function (confirm exact table/event from the old project first — likely `notifications` insert).
- [ ] Verify: trigger a test notification insert (once Task 25 seed data exists) and confirm the Edge Function fires (`get_logs`).
- [ ] Commit the Edge Function diff if any.

---

## Task 12: Point the Flutter app at the new project

**Files:**
- Modify: `lib/main.dart` — `Supabase.initialize(url: ..., anonKey: ...)`
- Modify: `lib/services/push_notification_service.dart` — confirm OneSignal `appId` constant is unchanged (reused, not regenerated)

- [ ] Update the URL/anon key in `main.dart` to the new project's values (from `get_project_url`/`get_publishable_keys`).
- [ ] Confirm `push_notification_service.dart`'s OneSignal App ID is untouched.
- [ ] Verify: `flutter analyze` clean; app launches and reaches the login screen against the new project (expect auth failure until Task 17/25 — that's fine, just confirm no crash on init).
- [ ] Commit.

---

## Task 13: Rewrite `auth_service.dart`

**Files:**
- Modify: `lib/services/auth_service.dart` (651 lines, 23 query call sites; tables: `avatars`, `profile_directory`, `profiles`, `resumes`)

**Interfaces:**
- Produces: sign-up must now insert into `profiles` **and** the matching subtype table (`students`/`academic_supervisors`/`parents`/`company_hr`/`company_supervisors`/`administrators`) as one logical operation — wrap in an RPC (`create_profile_with_subtype(role, ...)`) rather than two sequential client-side inserts, so a failure partway doesn't leave an orphaned base-only profile.
- Profile-read methods that used to return a flat `profiles` row with role-specific fields now read from `v_student_profile` (Task 9) when the role is `student`, or `profiles` joined to the relevant subtype table for other roles.
- Profile-update methods that used to do one `profiles` UPDATE now split into two UPDATEs (base + subtype) or a single RPC, matching the insert pattern.

- [ ] Add a `create_profile_with_subtype` Postgres RPC (as part of Task 2's migration, referenced here) and call it from sign-up instead of a raw `.insert()`.
- [ ] Update every method reading `profiles` for role-specific fields (`programme`, `skills`, `company_id`, `academic_supervisor_id`, etc.) to read from the appropriate view/join.
- [ ] Update every method writing those fields to write to the subtype table.
- [ ] `flutter analyze` clean.
- [ ] Commit.

---

## Task 14: Rewrite `student_data_service.dart`

**Files:**
- Modify: `lib/services/student_data_service.dart` (697 lines, 71 call sites — the largest file; tables: `applications`, `chat_attachments`, `companies`, `company_reviews`, `conversations`, `documents`, `internships`→`job_postings`, `messages`, `notifications`, `parent_child_links`, `profile_directory`, `profiles`→`v_student_profile`, `reports`→`v_report_with_reviews`, `student_files`, `work_experiences`)

- [ ] `internships` references become `job_postings` (join `categories` where the old code read `category` as a plain string).
- [ ] Any `interview_at`/`interview_mode`/`interview_location` read off `applications` becomes a read from `v_application_with_interview` or a join to `interviews`.
- [ ] Any report-status read (`status`, `feedback`, `reviewed_by`, `company_review_status`, etc.) becomes a read from `v_report_with_reviews`.
- [ ] Any document-status read becomes a read from `v_document_with_review`.
- [ ] Conversation membership checks (`participant_a.eq.$uid,participant_b.eq.$uid`) become a join through `profile_conversations`.
- [ ] Mute/archive/block toggles (`archived_a`, `muted_a`, `blocked_by_a` etc.) become an upsert on the caller's own `profile_conversations` row.
- [ ] Message edit/delete calls the `edit_message`/`delete_message_for_me` RPCs (Task 7) instead of a raw `.update()`.
- [ ] `flutter analyze` clean; manual Browser-pane pass on student dashboard, search, apply, applications, reports, messages, notifications screens.
- [ ] Commit.

---

## Task 15: Rewrite `supervisor_data_service.dart`

**Files:**
- Modify: `lib/services/supervisor_data_service.dart` (258 lines, 20 call sites; tables: `applications`, `documents`→`v_document_with_review`, `evaluations`, `profile_directory`, `profiles`→joins, `reports`→`v_report_with_reviews`/`academic_report_reviews`, `student_files`)

- [ ] Student roster queries join `students` (was flat `profiles` filter on `academic_supervisor_id`).
- [ ] Report review submission writes to `academic_report_reviews`, not flat `reports` columns.
- [ ] Document review submission writes to `document_reviews`.
- [ ] `flutter analyze` clean; manual pass on supervisor dashboard, students, reviews, evaluate, messages screens.
- [ ] Commit.

---

## Task 16: Rewrite `hr_data_service.dart`

**Files:**
- Modify: `lib/services/hr_data_service.dart` (278 lines, 18 call sites; tables: `applications`, `companies`, `internships`→`job_postings`, `profile_directory`, `profiles`→`company_hr`, `resumes`)

- [ ] Posting CRUD moves from `internships` to `job_postings` (+ `categories` for the dropdown, replacing the old hardcoded enum list).
- [ ] Interview scheduling writes to `interviews`, not `applications`.
- [ ] `flutter analyze` clean; manual pass on HR dashboard, postings, applicants, schedule-interview, recommended-candidates screens.
- [ ] Commit.

---

## Task 17: Rewrite `admin_data_service.dart`

**Files:**
- Modify: `lib/services/admin_data_service.dart` (168 lines, 17 call sites; tables: `applications`, `companies`, `profile_directory`, `profiles`→joins across all 6 subtype tables)

- [ ] Any cross-role listing (students, supervisors, HR) now joins `profiles` to the matching subtype table per row instead of reading one flat table.
- [ ] "Promote to admin" flow: role change on `profiles.role` now also requires inserting the corresponding `administrators` row (and, per the role-consistency trigger from Task 2, the *old* subtype row's role no longer matches — decide and implement whether to delete the old subtype row or leave it orphaned; recommend deleting it in the same RPC transaction).
- [ ] `flutter analyze` clean; manual pass on admin dashboard, companies, students, supervisors, monitor, more screens.
- [ ] Commit.

---

## Task 18: Rewrite `company_supervisor_data_service.dart`

**Files:**
- Modify: `lib/services/company_supervisor_data_service.dart` (143 lines, 5 call sites; tables: `applications`, `documents`, `profiles`→`company_supervisors`, `reports`→`company_report_reviews`)

- [ ] Report review submission writes to `company_report_reviews`.
- [ ] `flutter analyze` clean; manual pass on company supervisor dashboard/reviews screens.
- [ ] Commit.

---

## Task 19: Rewrite `parent_data_service.dart`

**Files:**
- Modify: `lib/services/parent_data_service.dart` (95 lines, 10 call sites; tables: `applications`, `documents`, `parent_child_links`, `profiles`→`parents`/`students` joins)

- [ ] Progress-view queries join `students` for the child's programme/status fields instead of a flat `profiles` read.
- [ ] `flutter analyze` clean; manual pass on parent shell, link-child, progress, acknowledgement screens.
- [ ] Commit.

---

## Task 20: Rewrite `company_service.dart`

**Files:**
- Modify: `lib/services/company_service.dart` (49 lines, 5 call sites; tables: `companies`, `profiles`→`company_hr`/`company_supervisors`)

- [ ] Self-service company pick/create flow inserts into `company_hr` or `company_supervisors` (matching the caller's role), not a flat `profiles.company_id` write.
- [ ] `flutter analyze` clean.
- [ ] Commit.

---

## Task 21: Verify `document_template_service.dart` needs no changes

**Files:**
- Read-only check: `lib/services/document_template_service.dart` (120 lines, 14 call sites; tables: `document_submissions`, `document_templates`)

- [ ] Confirm both tables kept their shape 1:1 in Task 8 — expect zero code changes here. If any column name shifted, fix it.
- [ ] `flutter analyze` clean.

---

## Task 22: Fresh seed data across all 6 roles

**Files:**
- Create: `supabase/seed.sql` (or seeded via `execute_sql`, but written to a tracked file either way — same durability principle as migrations)

- [ ] Create one test `auth.users` + `profiles` + subtype row per role (student, academic_supervisor, company_hr, company_supervisor, parent, admin).
- [ ] Link one parent-child pair (`parent_child_links`, status `approved`).
- [ ] Create one company, one job posting, one application (with an interview), one report (with both review stages), one document (with a review), one evaluation, one conversation with a couple of messages, one document template + submission.
- [ ] Verify: every seeded row is reachable through the RLS policies for its intended role (spot-check via `execute_sql` impersonation).
- [ ] Commit `supabase/seed.sql`.

---

## Task 23: Full regression verification

- [ ] `flutter analyze` — zero errors across the whole project.
- [ ] `get_advisors` (security + performance) — zero new findings vs. the pre-migration baseline.
- [ ] Browser-pane walkthrough per role: student (dashboard/search/apply/applications/reports/messages/notifications/profile), academic supervisor (dashboard/students/reviews/evaluate/messages), HR (dashboard/postings/applicants/recommended-candidates), company supervisor (dashboard/reviews), parent (link-child/progress/acknowledgement), admin (dashboard/companies/students/supervisors/monitor/more).
- [ ] Confirm push notifications fire end-to-end (the original Task 116 checkpoint, re-verified against the new project).
- [ ] Final commit + tag (e.g. `v2-normalized-schema`).

---

## Self-Review Notes

- **Spec coverage:** every entity in the final ERD (`C:\Users\Lucas\Downloads\CIMS_ERD.xml`) has a corresponding `CREATE TABLE` in Tasks 2–8; every one of the 9 service files has a dedicated rewrite task; infra (storage, Edge Function, webhooks, app config) has dedicated tasks; durability practices (tracked migrations, views, seed file) are woven through rather than bolted on at the end.
- **Known gap flagged inline:** Task 7's `messages_update_sender` policy is broader than final-intent until the RPC-only write path is confirmed in Task 22 — do not close Task 7 as fully verified until that's resolved, not just applied.
- **Storage bucket names were verified against the live project** (`avatars`, `chat_attachments`, `document_submissions`, `document_templates`, `resumes`, `student_files`) rather than guessed — no placeholder remains in Task 10.
