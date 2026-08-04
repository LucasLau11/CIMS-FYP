-- Second follow-up to 00001_profiles_and_subtypes.sql, from task review findings.
--
-- 1) CRITICAL: companies_update_own_staff never actually referenced the row
--    being updated. same_company_as(auth.uid()) compares the caller against
--    themselves (mine == theirs, both auth.uid()), so it collapsed to "does
--    the caller belong to ANY company" -- letting any company_hr/
--    company_supervisor update every company row, not just their own.
--    Fixed by replacing same_company_as(profile) with a properly
--    row-correlated is_my_company(company_id) helper, used against the
--    actual companies.company_id column.
-- 2) Important: get_advisors(performance) was never run for Task 2.
--    - auth_rls_initplan: wrap auth.uid()/current_user_role() in (select ...)
--      so Postgres evaluates them once per query instead of once per row.
--    - multiple_permissive_policies: profiles had two separate UPDATE
--      policies (own, admin) both evaluated for every authenticated UPDATE;
--      merged into one.
--    - unindexed_foreign_keys: added indexes on the three FK columns flagged.

drop policy if exists companies_update_own_staff on companies;
drop function if exists same_company_as(uuid);

create or replace function is_my_company(p_company_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from company_hr where profile_id = (select auth.uid()) and company_id = p_company_id
    union
    select 1 from company_supervisors where profile_id = (select auth.uid()) and company_id = p_company_id
  );
$$;
revoke execute on function is_my_company(uuid) from public, anon;
grant execute on function is_my_company(uuid) to authenticated;

create policy companies_update_own_staff on companies for update to authenticated
  using (is_my_company(company_id) or (select current_user_role()) = 'admin')
  with check (is_my_company(company_id) or (select current_user_role()) = 'admin');

drop policy if exists profiles_update_own on profiles;
drop policy if exists profiles_update_admin on profiles;
create policy profiles_update_own_or_admin on profiles for update to authenticated
  using (profile_id = (select auth.uid()) or (select current_user_role()) = 'admin')
  with check (profile_id = (select auth.uid()) or (select current_user_role()) = 'admin');

alter policy profiles_insert_own on profiles
  with check (profile_id = (select auth.uid()));

alter policy companies_insert_self_service on companies
  with check ((select current_user_role()) in ('company_hr','company_supervisor','admin'));

alter policy students_update_own_or_staff on students
  using (profile_id = (select auth.uid()) or (select current_user_role()) = 'admin'
         or is_academic_supervisor_of(profile_id));

alter policy students_insert_own on students
  with check (profile_id = (select auth.uid()));

alter policy academic_supervisors_insert_own on academic_supervisors
  with check (profile_id = (select auth.uid()));

alter policy parents_insert_own on parents
  with check (profile_id = (select auth.uid()));

alter policy company_hr_update_own on company_hr
  using (profile_id = (select auth.uid()) or (select current_user_role()) = 'admin');

alter policy company_hr_insert_own on company_hr
  with check (profile_id = (select auth.uid()));

alter policy company_supervisors_update_own on company_supervisors
  using (profile_id = (select auth.uid()) or (select current_user_role()) = 'admin');

alter policy company_supervisors_insert_own on company_supervisors
  with check (profile_id = (select auth.uid()));

alter policy administrators_insert_admin_only on administrators
  with check ((select current_user_role()) = 'admin');

create index if not exists idx_company_hr_company_id on company_hr(company_id);
create index if not exists idx_company_supervisors_company_id on company_supervisors(company_id);
create index if not exists idx_students_academic_supervisor_id on students(academic_supervisor_id);
