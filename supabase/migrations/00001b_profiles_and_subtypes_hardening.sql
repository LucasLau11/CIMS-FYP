-- Follow-up to 00001_profiles_and_subtypes.sql: closes two get_advisors
-- security findings before Task 2 is considered done, rather than letting
-- the same gap repeat across every later migration's functions.
--
-- 1) function_search_path_mutable: pin search_path on the trigger/guard
--    functions (the RLS helper functions in 00001 already had this; the
--    trigger functions were missed).
-- 2) anon/authenticated_security_definer_function_executable: these four
--    helper functions rely on auth.uid(), so anon callers always get a
--    null-based (non-matching) result -- not a data leak -- but there is
--    no reason to expose them as public RPC endpoints. RLS policies that
--    call them run as the `authenticated` role, so that grant must stay.

create or replace function assert_subtype_role(p_profile_id uuid, p_expected_role text)
returns void language plpgsql set search_path = public as $$
begin
  if not exists (select 1 from profiles where profile_id = p_profile_id and role = p_expected_role) then
    raise exception 'profile % is not role %', p_profile_id, p_expected_role;
  end if;
end;
$$;

create or replace function trg_check_student_role() returns trigger language plpgsql set search_path = public as $$
begin perform assert_subtype_role(new.profile_id, 'student'); return new; end; $$;

create or replace function trg_check_academic_supervisor_role() returns trigger language plpgsql set search_path = public as $$
begin perform assert_subtype_role(new.profile_id, 'academic_supervisor'); return new; end; $$;

create or replace function trg_check_parent_role() returns trigger language plpgsql set search_path = public as $$
begin perform assert_subtype_role(new.profile_id, 'parent'); return new; end; $$;

create or replace function trg_check_company_hr_role() returns trigger language plpgsql set search_path = public as $$
begin perform assert_subtype_role(new.profile_id, 'company_hr'); return new; end; $$;

create or replace function trg_check_company_supervisor_role() returns trigger language plpgsql set search_path = public as $$
begin perform assert_subtype_role(new.profile_id, 'company_supervisor'); return new; end; $$;

create or replace function trg_check_administrator_role() returns trigger language plpgsql set search_path = public as $$
begin perform assert_subtype_role(new.profile_id, 'admin'); return new; end; $$;

revoke execute on function current_user_role() from public, anon;
grant execute on function current_user_role() to authenticated;

revoke execute on function is_academic_supervisor_of(uuid) from public, anon;
grant execute on function is_academic_supervisor_of(uuid) to authenticated;

revoke execute on function is_approved_parent_of(uuid) from public, anon;
grant execute on function is_approved_parent_of(uuid) to authenticated;

revoke execute on function same_company_as(uuid) from public, anon;
grant execute on function same_company_as(uuid) to authenticated;
