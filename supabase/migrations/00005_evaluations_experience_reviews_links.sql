-- Task 6: Evaluations, work experiences, company reviews, parent-child links.
-- evaluations is intentionally append-only: no update/delete policies since
-- evaluations are meant to be immutable once submitted.

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
  using (student_id = (select auth.uid()) or supervisor_id = (select auth.uid()) or (select current_user_role()) = 'admin'
         or is_approved_parent_of(student_id));
create policy evaluations_insert_supervisor on evaluations for insert to authenticated
  with check (supervisor_id = (select auth.uid())
              and (select current_user_role()) in ('academic_supervisor','company_supervisor','admin'));

create policy work_experiences_select_authenticated on work_experiences for select to authenticated using (true);
create policy work_experiences_insert_own on work_experiences for insert to authenticated
  with check (student_id = (select auth.uid()));
create policy work_experiences_update_own on work_experiences for update to authenticated
  using (student_id = (select auth.uid())) with check (student_id = (select auth.uid()));
create policy work_experiences_delete_own on work_experiences for delete to authenticated
  using (student_id = (select auth.uid()));

create policy company_reviews_select_authenticated on company_reviews for select to authenticated using (true);
create policy company_reviews_insert_own on company_reviews for insert to authenticated
  with check (student_id = (select auth.uid()));
create policy company_reviews_update_own on company_reviews for update to authenticated
  using (student_id = (select auth.uid())) with check (student_id = (select auth.uid()));
create policy company_reviews_delete_own on company_reviews for delete to authenticated
  using (student_id = (select auth.uid()));

create policy parent_child_links_select_involved on parent_child_links for select to authenticated
  using (parent_id = (select auth.uid()) or student_id = (select auth.uid()) or (select current_user_role()) = 'admin');
create policy parent_child_links_insert_parent on parent_child_links for insert to authenticated
  with check (parent_id = (select auth.uid()));
create policy parent_child_links_update_student_or_admin on parent_child_links for update to authenticated
  using (student_id = (select auth.uid()) or (select current_user_role()) = 'admin');

create index if not exists idx_evaluations_student_id on evaluations(student_id);
create index if not exists idx_evaluations_supervisor_id on evaluations(supervisor_id);
create index if not exists idx_work_experiences_student_id on work_experiences(student_id);
create index if not exists idx_company_reviews_company_id on company_reviews(company_id);
create index if not exists idx_company_reviews_student_id on company_reviews(student_id);
create index if not exists idx_parent_child_links_parent_id on parent_child_links(parent_id);
create index if not exists idx_parent_child_links_student_id on parent_child_links(student_id);
