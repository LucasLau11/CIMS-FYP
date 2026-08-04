-- Follow-up to 00001d_create_profile_with_subtype.sql, from Task 13 review
-- finding 1.
--
-- create_profile_with_subtype was declared `security definer`, but every
-- insert it performs is already self-scoped and RLS-permitted:
-- profiles_insert_own, students_insert_own, academic_supervisors_insert_own,
-- parents_insert_own, company_hr_insert_own, company_supervisors_insert_own
-- are all `for insert to authenticated with check (profile_id = auth.uid())`
-- -- exactly matching what this function does with auth.uid(). A single
-- Postgres function call is already atomic regardless of definer/invoker, so
-- `security definer` gained nothing here, while tripping
-- get_advisors(security)'s authenticated_security_definer_function_executable
-- WARN -- a new finding the plan's Global Constraints forbid ("get_advisors
-- must show zero new findings introduced by this task's migration").
--
-- Fix: switch to `security invoker` so the function runs under the calling
-- user's own RLS-enforced privileges instead of the function owner's. The
-- function body is otherwise unchanged -- it still relies on auth.uid() (not
-- a client-supplied id) to decide which profile_id gets inserted, and RLS on
-- profiles/students/academic_supervisors/parents/company_hr/
-- company_supervisors now does the enforcement that security definer used to
-- bypass.

create or replace function create_profile_with_subtype(
  p_role text,
  p_email text
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_role = 'admin' then
    raise exception 'admin accounts cannot be created via self-service sign-up';
  end if;

  insert into profiles (profile_id, role, email)
  values (v_uid, p_role, p_email);

  case p_role
    when 'student' then
      insert into students (profile_id) values (v_uid);
    when 'academic_supervisor' then
      insert into academic_supervisors (profile_id) values (v_uid);
    when 'parent' then
      insert into parents (profile_id) values (v_uid);
    when 'company_hr' then
      insert into company_hr (profile_id) values (v_uid);
    when 'company_supervisor' then
      insert into company_supervisors (profile_id) values (v_uid);
    else
      raise exception 'unknown role: %', p_role;
  end case;
end;
$$;

revoke execute on function create_profile_with_subtype(text, text) from public, anon;
grant execute on function create_profile_with_subtype(text, text) to authenticated;
