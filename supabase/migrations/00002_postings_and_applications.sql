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
