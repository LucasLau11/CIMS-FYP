-- 00031: student accounts are created by an administrator, not by self sign-up.
--
-- * profiles.must_change_password: set for accounts created with a temporary password; the app
--   makes the person choose a new password at their first login, then clears it with
--   clear_must_change_password().
-- * handle_new_auth_user(): a 'student' account can only come from the admin-create-students Edge
--   Function (it marks the auth user with app_metadata.created_by_admin, which a client cannot set
--   through sign-up). A self sign-up that asks to be a student is refused.

alter table public.profiles add column if not exists must_change_password boolean not null default false;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_role text := new.raw_user_meta_data->>'app_role';
  v_name text := left(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 100);
  -- app_metadata can only be written with the service role, never by a client sign-up.
  v_by_admin boolean := coalesce((new.raw_app_meta_data->>'created_by_admin')::boolean, false);
  v_must_change boolean := v_by_admin and coalesce((new.raw_app_meta_data->>'must_change_password')::boolean, false);
begin
  if v_role is null or v_role not in
     ('student', 'academic_supervisor', 'company_hr', 'company_supervisor') then
    return new;
  end if;

  if v_role = 'student' and not v_by_admin then
    raise exception 'Student accounts are created by the administrator.';
  end if;

  insert into profiles (profile_id, role, email, full_name, approval_status, must_change_password)
  values (
    new.id, v_role, new.email, v_name,
    case when v_role in ('academic_supervisor', 'company_hr', 'company_supervisor')
         then 'pending' else 'approved' end,
    v_must_change)
  on conflict (profile_id) do nothing;

  case v_role
    when 'student' then insert into students (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'academic_supervisor' then insert into academic_supervisors (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'company_hr' then insert into company_hr (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'company_supervisor' then insert into company_supervisors (profile_id) values (new.id) on conflict (profile_id) do nothing;
  end case;

  return new;
end;
$function$;

create or replace function public.clear_must_change_password()
returns void
language sql
security definer
set search_path to 'public'
as $$
  update profiles set must_change_password = false where profile_id = (select auth.uid());
$$;

revoke all on function public.clear_must_change_password() from public, anon;
grant execute on function public.clear_must_change_password() to authenticated;
