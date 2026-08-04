-- Task 13 follow-up to 00001_profiles_and_subtypes.sql: sign-up needs to
-- create the shared `profiles` row AND the matching subtype row as one
-- atomic operation, so a crash/error partway through never leaves an
-- orphaned base-only profile (which would fail every later subtype-joined
-- query and view). Postgres functions are transactional by default, so
-- wrapping both inserts in a single RPC gets this for free without an
-- explicit BEGIN/COMMIT.
--
-- Design notes (see task-13-brief.md context):
-- * profile_id always comes from auth.uid() -- the client can never assert
--   another user's identity here, unlike a client-supplied id parameter
--   would allow.
-- * p_role = 'admin' is rejected outright. This mirrors
--   administrators_insert_admin_only (which requires current_user_role() =
--   'admin' and therefore can never be satisfied by a brand-new,
--   not-yet-inserted caller) -- admin accounts are only ever created later
--   by an existing admin promoting someone, never via self-service sign-up.
-- * Only the fields actually collected on the sign-up screen today (email,
--   password [not stored here], role) are parameters. full_name is set
--   afterwards via a separate profile update call (see auth_service.dart
--   signUp / signup_screen.dart), and company_hr/company_supervisor
--   sign-up doesn't collect a company_id at sign-up time (that's the
--   separate self-service "pick or create company" flow in
--   company_service.dart) -- so those subtype rows are inserted bare with
--   company_id left null.

create or replace function create_profile_with_subtype(
  p_role text,
  p_email text
)
returns void
language plpgsql
security definer
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
