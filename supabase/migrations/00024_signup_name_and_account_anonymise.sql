-- 00024_signup_name_and_account_anonymise.sql
--
-- 1. The sign-up trigger now also stores the name entered at sign-up
--    (raw_user_meta_data->>'full_name'), so administrators can see WHO they
--    are approving on the Pending approvals screen. Before this, the name
--    typed by company staff was lost whenever email confirmation was on.
--
-- 2. anonymise_my_account(): backs the in-app "Delete my account" action.
--    Rows that other people's records depend on (reports, evaluations,
--    reviews, messages) reference profiles without ON DELETE CASCADE, so a
--    hard delete is impossible once an account has history. Instead the
--    account is anonymised: personal details are wiped, login is blocked,
--    sessions are ended. The academic record the university must keep
--    remains, without personal details.

create or replace function handle_new_auth_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_role text := new.raw_user_meta_data->>'app_role';
  v_name text := left(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 100);
begin
  if v_role is null or v_role not in
     ('student', 'academic_supervisor', 'parent', 'company_hr', 'company_supervisor') then
    return new;
  end if;

  insert into profiles (profile_id, role, email, full_name, approval_status)
  values (
    new.id, v_role, new.email, v_name,
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

create or replace function anonymise_my_account() returns void
language plpgsql security definer set search_path = public, auth as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_placeholder text;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select role into v_role from profiles where profile_id = v_uid;
  if v_role is null then
    raise exception 'no profile found for this account';
  end if;

  if v_role = 'admin' and
     (select count(*) from profiles where role = 'admin' and approval_status = 'approved') <= 1 then
    raise exception 'the last administrator cannot delete their account';
  end if;

  v_placeholder := 'deleted-' || v_uid || '@deleted.invalid';

  update profiles
    set full_name = 'Deleted user', phone = null, date_of_birth = null,
        address_text = null, address_lat = null, address_lng = null,
        avatar_url = null, email = v_placeholder
    where profile_id = v_uid;

  update students
    set programme = null, faculty = null, semester = null, cgpa = null,
        skills = '{}', resume_path = null, resume_filename = null,
        resume_size_bytes = null, resume_uploaded_at = null, student_reg_no = null
    where profile_id = v_uid;

  delete from work_experiences where student_id = v_uid;
  delete from notifications where user_id = v_uid;
  delete from parent_child_links where parent_id = v_uid or student_id = v_uid;

  update messages
    set body = '[message removed]', attachment_path = null,
        attachment_file_name = null, attachment_size_bytes = null
    where sender_id = v_uid;

  -- Block future logins and end every session. A far-future date is used
  -- instead of 'infinity', which some Auth server versions cannot read back.
  update auth.users
    set email = v_placeholder, phone = null, raw_user_meta_data = '{}'::jsonb,
        banned_until = '2999-12-31'::timestamptz
    where id = v_uid;
  update auth.identities
    set identity_data = jsonb_build_object('sub', v_uid::text, 'email', v_placeholder)
    where user_id = v_uid;
  delete from auth.sessions where user_id = v_uid;
end;
$$;
revoke execute on function anonymise_my_account() from public, anon;
grant execute on function anonymise_my_account() to authenticated;

-- create or replace keeps existing grants, but state the intent explicitly:
-- the sign-up trigger function is never called by clients.
revoke execute on function handle_new_auth_user() from public, anon, authenticated;
