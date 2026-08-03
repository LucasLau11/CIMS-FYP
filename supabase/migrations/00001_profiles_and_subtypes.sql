-- Task 2: Core identity schema — profiles + 6 subtype tables
-- Produces: profiles(profile_id uuid PK), students, academic_supervisors,
-- parents, company_hr, company_supervisors, administrators.
-- Every later table's student_id/reviewer_id/supervisor_id/etc. FK references
-- land on profiles.profile_id (the shared identity space), never on a
-- subtype table's PK directly, since a subtype PK *is* profiles.profile_id
-- (shared-PK pattern).

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

create or replace function current_user_role() returns text
language sql stable security definer set search_path = public as $$
  select role from profiles where profile_id = auth.uid();
$$;

create or replace function is_academic_supervisor_of(p_student_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from students where profile_id = p_student_id and academic_supervisor_id = auth.uid());
$$;

-- NOTE: language plpgsql (not sql) deliberately — parent_child_links is created
-- in a later migration task, and plpgsql defers body validation until first
-- execution instead of checking the catalog at CREATE time like `language sql`
-- does, so this forward reference is safe to create now.
create or replace function is_approved_parent_of(p_student_id uuid) returns boolean
language plpgsql stable security definer set search_path = public as $$
begin
  return exists (
    select 1 from parent_child_links
    where student_id = p_student_id and parent_id = auth.uid() and status = 'approved'
  );
end;
$$;

create or replace function same_company_as(p_target_profile_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from (
      select company_id from company_hr where profile_id = auth.uid()
      union select company_id from company_supervisors where profile_id = auth.uid()
    ) mine
    join (
      select company_id from company_hr where profile_id = p_target_profile_id
      union select company_id from company_supervisors where profile_id = p_target_profile_id
    ) theirs using (company_id)
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
create policy profiles_update_own on profiles for update to authenticated
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy profiles_update_admin on profiles for update to authenticated
  using (current_user_role() = 'admin');
create policy profiles_insert_own on profiles for insert to authenticated
  with check (profile_id = auth.uid());

create policy companies_select_authenticated on companies for select to authenticated using (true);
create policy companies_update_own_staff on companies for update to authenticated
  using (same_company_as(auth.uid()) or current_user_role() = 'admin');
create policy companies_insert_self_service on companies for insert to authenticated
  with check (current_user_role() in ('company_hr','company_supervisor','admin'));

-- Subtype tables: readable same as base profile row; writable by the profile owner or admin.
create policy students_select_authenticated on students for select to authenticated using (true);
create policy students_update_own_or_staff on students for update to authenticated
  using (profile_id = auth.uid() or current_user_role() = 'admin'
         or is_academic_supervisor_of(profile_id));
create policy students_insert_own on students for insert to authenticated
  with check (profile_id = auth.uid());

create policy academic_supervisors_select_authenticated on academic_supervisors for select to authenticated using (true);
create policy academic_supervisors_insert_own on academic_supervisors for insert to authenticated
  with check (profile_id = auth.uid());

create policy parents_select_authenticated on parents for select to authenticated using (true);
create policy parents_insert_own on parents for insert to authenticated
  with check (profile_id = auth.uid());

create policy company_hr_select_authenticated on company_hr for select to authenticated using (true);
create policy company_hr_update_own on company_hr for update to authenticated
  using (profile_id = auth.uid() or current_user_role() = 'admin');
create policy company_hr_insert_own on company_hr for insert to authenticated
  with check (profile_id = auth.uid());

create policy company_supervisors_select_authenticated on company_supervisors for select to authenticated using (true);
create policy company_supervisors_update_own on company_supervisors for update to authenticated
  using (profile_id = auth.uid() or current_user_role() = 'admin');
create policy company_supervisors_insert_own on company_supervisors for insert to authenticated
  with check (profile_id = auth.uid());

create policy administrators_select_authenticated on administrators for select to authenticated using (true);
create policy administrators_insert_admin_only on administrators for insert to authenticated
  with check (current_user_role() = 'admin');
