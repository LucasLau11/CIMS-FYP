-- 00047: a sign-up that was never finished (the person left at the email-code step) is not an account.
-- The person is told to sign up again (app side); the administrator's lists must not show these half sign-ups either.
-- Nothing is deleted here: removing the unconfirmed auth users needs the owner's decision.

create or replace function public.admin_unconfirmed_profiles()
returns setof uuid
language plpgsql
stable
security definer
set search_path = public, auth
as $$
begin
  if (select current_user_role()) is distinct from 'admin' then
    raise exception 'Only an administrator can see this.' using errcode = '42501';
  end if;
  return query select u.id from auth.users u where u.email_confirmed_at is null;
end;
$$;
revoke all on function public.admin_unconfirmed_profiles() from public, anon;
grant execute on function public.admin_unconfirmed_profiles() to authenticated;

create or replace function public.admin_company_staff(p_company uuid)
returns table(profile_id uuid, role text, full_name text, email text, approval_status text, last_sign_in_at timestamptz)
language plpgsql
stable
security definer
set search_path = public, auth
as $$
begin
  if (select current_user_role()) is distinct from 'admin' then
    raise exception 'Only an administrator can see this.' using errcode = '42501';
  end if;
  return query
    select p.profile_id, p.role, p.full_name, p.email, p.approval_status, u.last_sign_in_at
      from profiles p
      join auth.users u on u.id = p.profile_id
     where p.email not like '%@deleted.invalid'
       and u.email_confirmed_at is not null
       and (p.profile_id in (select h.profile_id from company_hr h where h.company_id = p_company)
         or p.profile_id in (select s.profile_id from company_supervisors s where s.company_id = p_company))
     order by p.role, p.full_name;
end;
$$;
