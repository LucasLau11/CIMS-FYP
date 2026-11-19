-- 00023_security_hardening.sql
--
-- Findings from the pre-publication security audit (2026-11-02), verified
-- against the live database before this migration was written:
--
--  1. profiles / students / company_hr / company_supervisors were writable by
--     the row owner on EVERY column, with no guard trigger -- so a signed-in
--     user could set their own profiles.role = 'admin'.
--  2. profiles_insert_own (and the *_insert_own policies on the subtype
--     tables) let a user with no profile row insert one with ANY role,
--     including 'admin'. Profile creation is now trigger-only (00015), so
--     those policies and the superseded RPC are removed.
--  3. profiles / students were readable by every signed-in user
--     (using (true)), exposing phone, date of birth and home address.
--  4. Anyone could self-register as academic_supervisor / company_hr /
--     company_supervisor and immediately act with those privileges.
--  5. evaluations_insert_supervisor did not check the supervisor is actually
--     responsible for the student.
--  6. Storage buckets had no size limits; two accepted any content type.
--  7. Trigger / helper functions were executable by `anon`.
--
-- Accepted, documented design decisions (NOT changed here):
--  * can_view_resume still lets approved staff of a company see the resume of
--    a student whose skills match one of that company's open postings. This
--    backs the "recommended candidates" feature and is now gated by the
--    staff-approval step below.
--  * SECURITY DEFINER helpers used inside RLS policies must stay executable
--    by `authenticated`; they only ever answer questions about the caller's
--    own context, so the advisor's "authenticated can execute" warnings for
--    them are expected.

-- ---------------------------------------------------------------------------
-- 1. Staff approval gate
-- ---------------------------------------------------------------------------
alter table profiles
  add column if not exists approval_status text not null default 'approved'
  check (approval_status in ('pending', 'approved', 'rejected'));

create or replace function is_approved_user() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select approval_status = 'approved' from profiles where profile_id = (select auth.uid())),
    false);
$$;
revoke execute on function is_approved_user() from public, anon;
grant execute on function is_approved_user() to authenticated;

-- An account that is not approved has NO role as far as authorisation goes.
create or replace function current_user_role() returns text
language sql stable security definer set search_path = public as $$
  select case when approval_status = 'approved' then role end
  from profiles where profile_id = auth.uid();
$$;

create or replace function is_my_company(p_company_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select (select is_approved_user()) and exists (
    select 1 from company_hr where profile_id = (select auth.uid()) and company_id = p_company_id
    union
    select 1 from company_supervisors where profile_id = (select auth.uid()) and company_id = p_company_id
  );
$$;

create or replace function is_academic_supervisor_of(p_student_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select (select is_approved_user())
    and exists (select 1 from students where profile_id = p_student_id and academic_supervisor_id = auth.uid());
$$;

-- Sign-up trigger: staff roles start 'pending'; unknown roles are ignored.
create or replace function handle_new_auth_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_role text := new.raw_user_meta_data->>'app_role';
begin
  if v_role is null or v_role not in
     ('student', 'academic_supervisor', 'parent', 'company_hr', 'company_supervisor') then
    return new;
  end if;

  insert into profiles (profile_id, role, email, approval_status)
  values (
    new.id, v_role, new.email,
    case when v_role in ('academic_supervisor', 'company_hr', 'company_supervisor')
         then 'pending' else 'approved' end)
  on conflict (profile_id) do nothing;

  case v_role
    when 'student' then insert into students (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'academic_supervisor' then insert into academic_supervisors (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'parent' then insert into parents (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'company_hr' then insert into company_hr (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'company_supervisor' then insert into company_supervisors (profile_id) values (new.id) on conflict (profile_id) do nothing;
  end case;

  return new;
end;
$$;
-- Trigger functions run with the table owner's rights; nobody needs EXECUTE.
revoke execute on function handle_new_auth_user() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Profile creation is trigger-only: remove client-side INSERT paths
-- ---------------------------------------------------------------------------
drop policy if exists profiles_insert_own on profiles;
drop policy if exists students_insert_own on students;
drop policy if exists academic_supervisors_insert_own on academic_supervisors;
drop policy if exists parents_insert_own on parents;
drop policy if exists company_hr_insert_own on company_hr;
drop policy if exists company_supervisors_insert_own on company_supervisors;
drop function if exists create_profile_with_subtype(text, text);

-- ---------------------------------------------------------------------------
-- 3. Column guards: owners may edit their details, not their privileges
--    (auth.uid() is null for the service role / SQL editor, which stay allowed)
-- ---------------------------------------------------------------------------
create or replace function guard_profiles_update() returns trigger
language plpgsql set search_path = public as $$
begin
  if (select auth.uid()) is null or (select current_user_role()) = 'admin' then
    return new;
  end if;
  if new.profile_id is distinct from old.profile_id then
    raise exception 'profile_id cannot be changed' using errcode = '42501';
  end if;
  if new.role is distinct from old.role then
    raise exception 'only an administrator can change a role' using errcode = '42501';
  end if;
  if new.approval_status is distinct from old.approval_status then
    raise exception 'only an administrator can change approval status' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists guard_profiles_update on profiles;
create trigger guard_profiles_update before update on profiles
  for each row execute function guard_profiles_update();

create or replace function guard_students_update() returns trigger
language plpgsql set search_path = public as $$
begin
  if (select auth.uid()) is null or (select current_user_role()) = 'admin' then
    return new;
  end if;
  if new.academic_supervisor_id is distinct from old.academic_supervisor_id then
    raise exception 'only an administrator can assign a supervisor' using errcode = '42501';
  end if;
  if new.intake_id is distinct from old.intake_id then
    raise exception 'only an administrator can change an intake' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists guard_students_update on students;
create trigger guard_students_update before update on students
  for each row execute function guard_students_update();

-- Company staff may attach themselves to a company once (null -> value);
-- moving to a different company afterwards is an administrator action.
create or replace function guard_company_staff_update() returns trigger
language plpgsql set search_path = public as $$
begin
  if (select auth.uid()) is null or (select current_user_role()) = 'admin' then
    return new;
  end if;
  if new.company_id is distinct from old.company_id and old.company_id is not null then
    raise exception 'only an administrator can move an account to another company' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists guard_company_hr_update on company_hr;
create trigger guard_company_hr_update before update on company_hr
  for each row execute function guard_company_staff_update();
drop trigger if exists guard_company_supervisors_update on company_supervisors;
create trigger guard_company_supervisors_update before update on company_supervisors
  for each row execute function guard_company_staff_update();

-- ---------------------------------------------------------------------------
-- 4. Evaluations: the supervisor must be responsible for the student
-- ---------------------------------------------------------------------------
drop policy if exists evaluations_insert_supervisor on evaluations;
create policy evaluations_insert_supervisor on evaluations for insert to authenticated
  with check (
    supervisor_id = (select auth.uid())
    and student_internship_status(student_id) = 'completed'
    and (
      (select current_user_role()) = 'admin'
      or ((select current_user_role()) = 'academic_supervisor' and is_academic_supervisor_of(student_id))
      or ((select current_user_role()) = 'company_supervisor' and is_my_accepted_student(student_id))
    )
  );

-- ---------------------------------------------------------------------------
-- 5. Profile visibility: PII is visible only to people with a working
--    relationship to the person. Staff profiles stay visible to signed-in
--    users (students must see their supervisors / recruiters). Everyone can
--    still read the minimal profile_directory surface.
-- ---------------------------------------------------------------------------
create or replace function can_view_profile(p_target uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select
    p_target = (select auth.uid())
    or (select current_user_role()) = 'admin'
    or exists (select 1 from profiles t where t.profile_id = p_target
               and t.role in ('academic_supervisor', 'company_hr', 'company_supervisor', 'admin'))
    or is_academic_supervisor_of(p_target)
    or is_approved_parent_of(p_target)
    or exists (select 1 from parent_child_links l
               where (l.parent_id = (select auth.uid()) and l.student_id = p_target)
                  or (l.student_id = (select auth.uid()) and l.parent_id = p_target))
    or exists (select 1 from profile_conversations a
               join profile_conversations b using (conversation_id)
               where a.profile_id = (select auth.uid()) and b.profile_id = p_target)
    or exists (select 1 from applications a
               join job_postings jp on jp.job_posting_id = a.job_posting_id
               where a.student_id = p_target and is_my_company(jp.company_id));
$$;
revoke execute on function can_view_profile(uuid) from public, anon;
grant execute on function can_view_profile(uuid) to authenticated;

drop policy if exists profiles_select_authenticated on profiles;
create policy profiles_select_visible on profiles for select to authenticated
  using (can_view_profile(profile_id));

drop policy if exists students_select_authenticated on students;
create policy students_select_visible on students for select to authenticated
  using (can_view_profile(profile_id));

-- Parents link to a child by exact email. They are, by definition, not yet
-- related to that student, so this goes through a narrow RPC returning only
-- what the link screen shows.
create or replace function find_student_for_link(p_email text)
returns table (profile_id uuid, full_name text, programme text)
language plpgsql stable security definer set search_path = public as $$
begin
  if (select current_user_role()) is distinct from 'parent' then
    raise exception 'only parents can look up a student to link' using errcode = '42501';
  end if;
  return query
    select p.profile_id, p.full_name, s.programme
    from profiles p join students s on s.profile_id = p.profile_id
    where p.role = 'student' and lower(p.email) = lower(trim(p_email))
    limit 1;
end;
$$;
revoke execute on function find_student_for_link(text) from public, anon;
grant execute on function find_student_for_link(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. Function exposure: nothing here should be callable without signing in
-- ---------------------------------------------------------------------------
-- RLS policies call these as `authenticated`, so grant that role explicitly
-- before removing the implicit PUBLIC grant.
revoke execute on function is_my_accepted_student(uuid) from public, anon;
grant execute on function is_my_accepted_student(uuid) to authenticated;
revoke execute on function student_internship_status(uuid) from public, anon;
grant execute on function student_internship_status(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 7. Storage limits
-- ---------------------------------------------------------------------------
update storage.buckets set file_size_limit = 5 * 1024 * 1024 where id = 'avatars';
update storage.buckets set file_size_limit = 10 * 1024 * 1024 where id = 'resumes';
update storage.buckets set file_size_limit = 20 * 1024 * 1024 where id in ('student_files', 'chat_attachments');
-- These two only ever receive PDFs uploaded with an explicit content type.
update storage.buckets
  set file_size_limit = 20 * 1024 * 1024, allowed_mime_types = array['application/pdf']
  where id in ('document_templates', 'document_submissions');
