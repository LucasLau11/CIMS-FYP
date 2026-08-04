-- Task 17 (admin_data_service.dart migration): closes a real, general gap
-- confirmed live -- none of the 6 subtype tables (students,
-- academic_supervisors, parents, company_hr, company_supervisors,
-- administrators) have ANY delete policy today (confirmed via
-- pg_policies: only *_select_authenticated / *_insert_own / (students only)
-- *_update_own_or_staff exist). This blocks the "promote to admin"
-- role-transition flow, which needs to delete the old subtype row when a
-- user's `profiles.role` changes (the BEFORE INSERT/UPDATE role-consistency
-- triggers from Task 2 -- trg_check_student_role etc, calling
-- assert_subtype_role -- only fire on insert/update, not delete, so this is
-- safe/unaffected by them regardless of statement ordering).
--
-- Admin-only, matching the existing admin-escalation pattern used by
-- students_update_own_or_staff / company_hr_update_own /
-- company_supervisors_update_own elsewhere in this schema.

create policy students_delete_admin on students
  for delete to authenticated
  using ((select current_user_role()) = 'admin');

create policy academic_supervisors_delete_admin on academic_supervisors
  for delete to authenticated
  using ((select current_user_role()) = 'admin');

create policy parents_delete_admin on parents
  for delete to authenticated
  using ((select current_user_role()) = 'admin');

create policy company_hr_delete_admin on company_hr
  for delete to authenticated
  using ((select current_user_role()) = 'admin');

create policy company_supervisors_delete_admin on company_supervisors
  for delete to authenticated
  using ((select current_user_role()) = 'admin');

create policy administrators_delete_admin on administrators
  for delete to authenticated
  using ((select current_user_role()) = 'admin');

-- "Promote to admin" role-transition RPC. Design mirrors
-- create_profile_with_subtype (00001d/00001e): a single plpgsql function
-- body is transactional by default, so any failure partway through (e.g.
-- the final insert violating a constraint) rolls back everything -- no
-- partial promotion is ever left behind.
--
-- security invoker (not definer), matching the 00001e lesson from Task 13's
-- review: every step this function performs is already RLS-permitted to an
-- admin caller once the DELETE policies above exist (the caller's own
-- current_user_role() = 'admin' satisfies students_delete_admin /
-- academic_supervisors_delete_admin / .../administrators_insert_admin_only
-- / and the profiles_update_admin policy on profiles). `security definer`
-- would gain nothing here while tripping get_advisors(security)'s
-- authenticated_security_definer_function_executable WARN.
--
-- The explicit role check at the top is defense in depth on top of RLS --
-- a clear early exception reads better than a cryptic RLS-denial mid-
-- transaction if a non-admin somehow calls this directly.
--
-- Ordering within the transaction matters: profiles.role is updated to
-- 'admin' BEFORE the administrators row is inserted, because
-- trg_check_administrator_role (via assert_subtype_role) requires
-- profiles.role already be 'admin' for the target profile_id at the moment
-- of that insert. The old subtype row is deleted first (order relative to
-- the profiles update doesn't matter for DELETE, since the role-consistency
-- triggers don't fire on delete -- done first here simply so the "old role"
-- lookup captured at the top of the function is used before it's stale).
--
-- Real-world scoping note: this project's UI only offers "promote an
-- academic SUPERVISOR to admin" (admin_supervisors_screen.dart). The other
-- branches (student/parent/company_hr/company_supervisor) are included for
-- completeness/generality -- academic_supervisors has no other columns and
-- nothing else has a hard FK pointing at academic_supervisors.profile_id
-- specifically (FKs like students.academic_supervisor_id,
-- evaluations.supervisor_id etc all point at profiles.profile_id, not the
-- subtype table), so the actually-exercised path is safe. Per the task
-- brief, the other branches aren't expected to be exercised by any current
-- UI flow and weren't over-invested in for testing.

create or replace function promote_to_admin(p_target_profile_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_role text;
begin
  if (select current_user_role()) <> 'admin' then
    raise exception 'only an admin can promote a user to admin';
  end if;

  select role into v_role from profiles where profile_id = p_target_profile_id;

  if v_role is null then
    raise exception 'target profile % not found', p_target_profile_id;
  end if;

  if v_role = 'admin' then
    raise exception 'target profile % is already an admin', p_target_profile_id;
  end if;

  case v_role
    when 'student' then
      delete from students where profile_id = p_target_profile_id;
    when 'academic_supervisor' then
      delete from academic_supervisors where profile_id = p_target_profile_id;
    when 'parent' then
      delete from parents where profile_id = p_target_profile_id;
    when 'company_hr' then
      delete from company_hr where profile_id = p_target_profile_id;
    when 'company_supervisor' then
      delete from company_supervisors where profile_id = p_target_profile_id;
    else
      raise exception 'unknown role: %', v_role;
  end case;

  update profiles set role = 'admin' where profile_id = p_target_profile_id;

  insert into administrators (profile_id) values (p_target_profile_id);
end;
$$;

revoke execute on function promote_to_admin(uuid) from public, anon;
grant execute on function promote_to_admin(uuid) to authenticated;
