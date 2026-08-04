-- Task 4: Reports + academic/company report reviews.
-- Students submit monthly/final reports; academic supervisors review them
-- for the school, company supervisors review them for the employer.
-- Note: company_report_reviews deliberately excludes admin from write
-- access (can_manage_company_review only checks company_supervisor) --
-- that is an intentional boundary confirmed earlier in the project, not
-- an oversight.

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

create or replace function can_manage_academic_review(p_report_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select (select current_user_role()) = 'admin'
         or exists (select 1 from reports r where r.report_id = p_report_id and is_academic_supervisor_of(r.student_id));
$$;
revoke execute on function can_manage_academic_review(uuid) from public, anon;
grant execute on function can_manage_academic_review(uuid) to authenticated;

create policy academic_report_reviews_insert_supervisor on academic_report_reviews for insert to authenticated
  with check (can_manage_academic_review(report_id));
create policy academic_report_reviews_update_supervisor on academic_report_reviews for update to authenticated
  using (can_manage_academic_review(report_id)) with check (can_manage_academic_review(report_id));
create policy academic_report_reviews_delete_supervisor on academic_report_reviews for delete to authenticated
  using (can_manage_academic_review(report_id));

create policy company_report_reviews_select_involved on company_report_reviews for select to authenticated
  using (exists (select 1 from reports r where r.report_id = company_report_reviews.report_id
                 and (r.student_id = (select auth.uid())
                      or exists (select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
                                  where a.student_id = r.student_id and is_my_company(jp.company_id)))));

create or replace function can_manage_company_review(p_report_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from reports r join applications a on a.student_id = r.student_id
                 join job_postings jp on jp.job_posting_id = a.job_posting_id
                 where r.report_id = p_report_id and is_my_company(jp.company_id)
                 and (select current_user_role()) = 'company_supervisor');
$$;
revoke execute on function can_manage_company_review(uuid) from public, anon;
grant execute on function can_manage_company_review(uuid) to authenticated;

create policy company_report_reviews_insert_company_supervisor on company_report_reviews for insert to authenticated
  with check (can_manage_company_review(report_id));
create policy company_report_reviews_update_company_supervisor on company_report_reviews for update to authenticated
  using (can_manage_company_review(report_id)) with check (can_manage_company_review(report_id));
create policy company_report_reviews_delete_company_supervisor on company_report_reviews for delete to authenticated
  using (can_manage_company_review(report_id));

create index if not exists idx_reports_student_id on reports(student_id);
create index if not exists idx_academic_report_reviews_reviewer_id on academic_report_reviews(reviewer_id);
create index if not exists idx_company_report_reviews_reviewer_id on company_report_reviews(reviewer_id);
