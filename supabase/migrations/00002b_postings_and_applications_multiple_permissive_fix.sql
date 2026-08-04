-- Fix multiple_permissive_policies: each of these tables had a separate
-- SELECT-only policy plus a `for all` policy that also covers SELECT,
-- so both got evaluated on every read. Split each `for all` into
-- insert/update/delete so SELECT is governed by exactly one policy.

drop policy if exists categories_write_admin on categories;
create policy categories_insert_admin on categories for insert to authenticated
  with check ((select current_user_role()) = 'admin');
create policy categories_update_admin on categories for update to authenticated
  using ((select current_user_role()) = 'admin') with check ((select current_user_role()) = 'admin');
create policy categories_delete_admin on categories for delete to authenticated
  using ((select current_user_role()) = 'admin');

drop policy if exists job_postings_write_own_company on job_postings;
create policy job_postings_insert_own_company on job_postings for insert to authenticated
  with check (is_my_company(company_id) or (select current_user_role()) = 'admin');
create policy job_postings_update_own_company on job_postings for update to authenticated
  using (is_my_company(company_id) or (select current_user_role()) = 'admin')
  with check (is_my_company(company_id) or (select current_user_role()) = 'admin');
create policy job_postings_delete_own_company on job_postings for delete to authenticated
  using (is_my_company(company_id) or (select current_user_role()) = 'admin');

create or replace function can_manage_interview(p_application_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
    where a.application_id = p_application_id and (is_my_company(jp.company_id) or (select current_user_role()) = 'admin')
  );
$$;
revoke execute on function can_manage_interview(uuid) from public, anon;
grant execute on function can_manage_interview(uuid) to authenticated;

drop policy if exists interviews_write_company on interviews;
create policy interviews_insert_company on interviews for insert to authenticated
  with check (can_manage_interview(application_id));
create policy interviews_update_company on interviews for update to authenticated
  using (can_manage_interview(application_id)) with check (can_manage_interview(application_id));
create policy interviews_delete_company on interviews for delete to authenticated
  using (can_manage_interview(application_id));
