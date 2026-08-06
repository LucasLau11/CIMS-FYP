-- Bug report: with Supabase Auth's "Confirm email" setting enabled,
-- auth.signUp() returns a user but NO active session until the user
-- clicks the confirmation link -- so the client-side follow-up call to
-- create_profile_with_subtype() executes as `anon` (no JWT yet), and
-- since that RPC is granted to `authenticated` only, it fails with
-- "permission denied for function create_profile_with_subtype". This
-- broke sign-up entirely as soon as email confirmation was turned on.
--
-- Fix: move profile creation into a trigger on auth.users itself. Triggers
-- fire synchronously as part of the same INSERT that GoTrue performs when
-- creating the auth.users row (via its own internal privileged connection,
-- not the client's session), so this works identically regardless of
-- whether email confirmation is required, and regardless of whether the
-- client has an active session yet. The role is read from
-- raw_user_meta_data->>'app_role', which auth_service.dart's signUp()
-- already passes via signUp(data: {'app_role': ...}) -- no client change
-- needed there beyond removing the now-redundant (and now potentially
-- duplicate-inserting) RPC call.
--
-- Defensive by design: unlike create_profile_with_subtype (which raises on
-- an invalid role), this trigger silently skips profile creation for a
-- missing/unrecognized role or role = 'admin' rather than raising --
-- raising here would abort the auth.users INSERT itself and break account
-- creation with a raw Postgres error. Silently skipping just leaves an
-- auth.users row with no profiles row, which is inert (everything in this
-- app gates on profiles.role) -- notably this also means a client can't
-- self-provision an admin profile by setting app_role: 'admin' in signUp's
-- metadata, mirroring the guard create_profile_with_subtype already had.

create or replace function handle_new_auth_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_role text := new.raw_user_meta_data->>'app_role';
begin
  if v_role is null or v_role = 'admin' then
    return new;
  end if;

  insert into profiles (profile_id, role, email)
  values (new.id, v_role, new.email)
  on conflict (profile_id) do nothing;

  case v_role
    when 'student' then insert into students (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'academic_supervisor' then insert into academic_supervisors (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'parent' then insert into parents (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'company_hr' then insert into company_hr (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'company_supervisor' then insert into company_supervisors (profile_id) values (new.id) on conflict (profile_id) do nothing;
    else null;
  end case;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_auth_user();

-- create_profile_with_subtype is no longer called by the client (its only
-- caller, auth_service.dart's signUp(), now relies on the trigger above)
-- -- left in place rather than dropped since it was independently reviewed
-- and live-tested in an earlier task, and removing it has no benefit over
-- just noting it's superseded.
comment on function create_profile_with_subtype(text, text) is
  'Superseded by the on_auth_user_created trigger (handle_new_auth_user) as of migration 00015 -- no longer called by the client. Kept for reference / potential future direct use.';
