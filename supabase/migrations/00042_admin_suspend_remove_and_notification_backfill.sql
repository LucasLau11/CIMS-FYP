-- 00042: second round of phone-testing fixes.
--
--  1. Notifications written before message keys existed (00041) are given keys, so the WHOLE list
--     follows the language setting. Only rows whose text matches one of our own templates exactly
--     are touched. Two templates for the old "Interview rescheduled" wording are added.
--  2. 'suspended' is a new approval status. An administrator can suspend / reactivate an account
--     (admin_set_account_suspended) and remove one for good (admin_remove_account: the same
--     anonymising as "Delete my account"). admin_company_staff lists the HR people and company
--     supervisors of a company; deleted_profiles lets the chat list hide deleted people.
--
-- Applied to the project as 00042a_backfill_notification_keys and
-- 00042b_admin_suspend_remove_company_staff.

-- ---------------------------------------------------------------------------------------
-- 1. Back-fill message keys
-- ---------------------------------------------------------------------------------------
insert into public.notification_templates (msg_key, lang, title, body) values
 ('interview_moved_by_company','en','Interview rescheduled','The company moved the interview for {role} to {to}. Reason: {reason}'),
 ('interview_moved_by_company','ms','Temu duga dijadualkan semula','Syarikat menukar temu duga untuk {role} ke {to}. Sebab: {reason}'),
 ('interview_moved_by_company','zh','面试已改期','公司将{role}的面试改到了{to}。原因：{reason}'),
 ('interview_moved_by_student','en','Interview rescheduled','The student moved the interview for {role} to {to}. Reason: {reason}'),
 ('interview_moved_by_student','ms','Temu duga dijadualkan semula','Pelajar menukar temu duga untuk {role} ke {to}. Sebab: {reason}'),
 ('interview_moved_by_student','zh','面试已改期','学生将{role}的面试改到了{to}。原因：{reason}')
on conflict (msg_key, lang) do update set title = excluded.title, body = excluded.body;

create or replace function pg_temp._bf_when(w text) returns text language sql as $$
  select to_char(((to_timestamp(w, 'Dy DD Mon YYYY, HH12:MI AM'))::timestamp at time zone 'Asia/Kuala_Lumpur') at time zone 'UTC',
                 'YYYY-MM-DD"T"HH24:MI:SS"Z"');
$$;

do $$
declare
  r record;
  m text[];
  wp constant text := '(\w{3} \d{2} \w{3} \d{4}, \d{2}:\d{2} [AP]M)';
  who text;
begin
  for r in select notification_id, body from notifications where msg_key is null loop
    m := regexp_match(r.body, '^Your application to (.+) has been sent\.$');
    if m is null then m := regexp_match(r.body, '^您对(.+)的申请已发送。$'); end if;
    if m is null then m := regexp_match(r.body, '^Permohonan anda kepada (.+) telah dihantar\.$'); end if;
    if m is not null then
      update notifications set msg_key = 'app_submitted', msg_args = jsonb_build_object('company', m[1]) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^Congratulations! You have been offered (.+)\. Open My Applications');
    if m is not null then
      update notifications set msg_key = 'offer_received', msg_args = jsonb_build_object('role', m[1]) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^Your application for (.+) was not successful this time\. Reason: (.+)$');
    if m is not null then
      update notifications set msg_key = 'application_rejected', msg_args = jsonb_build_object('role', m[1], 'reason', m[2]) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^There is an update on (.+)\.$');
    if m is not null then
      update notifications set msg_key = 'application_update', msg_args = jsonb_build_object('role', m[1]) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^(.*) accepted your offer for (.+)\.$');
    if m is not null then
      update notifications set msg_key = 'offer_accepted', msg_args = jsonb_build_object('student', m[1], 'role', m[2]) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^(.*) accepted another offer, so their application for (.+) has been closed\.$');
    if m is not null then
      update notifications set msg_key = 'candidate_unavailable', msg_args = jsonb_build_object('student', m[1], 'role', m[2]) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^You have an interview for (.+) on ' || wp || '\.$');
    if m is not null then
      update notifications set msg_key = 'interview_scheduled', msg_args = jsonb_build_object('role', m[1], 'when', pg_temp._bf_when(m[2])) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^The (company|student) moved the interview for (.+) to ' || wp || '\. Reason: (.+)$');
    if m is not null then
      update notifications set msg_key = 'interview_moved_by_' || m[1],
             msg_args = jsonb_build_object('role', m[2], 'to', pg_temp._bf_when(m[3]), 'reason', m[4]) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^The (company|student) accepted\. The interview for (.+) is now on ' || wp || '\.$');
    if m is not null then
      update notifications set msg_key = 'reschedule_accepted_by_' || m[1],
             msg_args = jsonb_build_object('role', m[2], 'when', pg_temp._bf_when(m[3])) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^The (company|student) declined moving the interview for (.+)\. It stays on ' || wp || '\. Reason: (.+)$');
    if m is not null then
      update notifications set msg_key = 'reschedule_declined_by_' || m[1],
             msg_args = jsonb_build_object('role', m[2], 'when', pg_temp._bf_when(m[3]), 'reason', m[4]) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^The (student|company) asks to move the interview for (.+) from ' || wp || ' to ' || wp || '\. Reason: (.+) Open the interview to accept or decline; it stays as it is until you accept\.$');
    if m is not null then
      update notifications set msg_key = 'reschedule_requested_by_' || m[1],
             msg_args = jsonb_build_object('role', m[2], 'from', pg_temp._bf_when(m[3]), 'to', pg_temp._bf_when(m[4]), 'reason', m[5]) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^(The student|The company) cancelled the interview for (.+) on ' || wp || '\. Reason: (.+?)( The company will arrange a new time\.)?$');
    if m is not null then
      who := case when m[1] = 'The student' then 'student' else 'company' end;
      update notifications set msg_key = 'interview_cancelled_by_' || who,
             msg_args = jsonb_build_object('role', m[2], 'when', pg_temp._bf_when(m[3]), 'reason', m[4]) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^Your interview for (.+) starts in about an hour: ' || wp || '\.$');
    if m is not null then
      update notifications set msg_key = 'interview_reminder_1h', msg_args = jsonb_build_object('role', m[1], 'when', pg_temp._bf_when(m[2])) where notification_id = r.notification_id; continue;
    end if;

    m := regexp_match(r.body, '^Your interview for (.+) is coming up in the next 24 hours: ' || wp || '\.$');
    if m is not null then
      update notifications set msg_key = 'interview_reminder_24h', msg_args = jsonb_build_object('role', m[1], 'when', pg_temp._bf_when(m[2])) where notification_id = r.notification_id; continue;
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------------------------
-- 2. Suspend, remove, company staff, deleted people
-- ---------------------------------------------------------------------------------------
alter table public.profiles drop constraint if exists profiles_approval_status_check;
alter table public.profiles add constraint profiles_approval_status_check
  check (approval_status in ('pending', 'approved', 'rejected', 'suspended'));

create or replace function public.admin_set_account_suspended(p_profile uuid, p_suspend boolean)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_role text;
  v_status text;
  v_email text;
begin
  if (select current_user_role()) is distinct from 'admin' then
    raise exception 'Only an administrator can do this.' using errcode = '42501';
  end if;
  if p_profile = auth.uid() then
    raise exception 'You cannot suspend your own account.';
  end if;
  select role, approval_status, email into v_role, v_status, v_email from profiles where profile_id = p_profile;
  if v_role is null then
    raise exception 'That account was not found.';
  end if;
  if v_role = 'admin' then
    raise exception 'An administrator account cannot be suspended here.';
  end if;
  if v_email like '%@deleted.invalid' then
    raise exception 'That account has been removed.';
  end if;

  if p_suspend then
    if v_status <> 'approved' then
      raise exception 'Only an approved account can be suspended.';
    end if;
    update profiles set approval_status = 'suspended' where profile_id = p_profile;
    update auth.users set banned_until = '2999-12-31'::timestamptz where id = p_profile;
    delete from auth.sessions where user_id = p_profile;
  else
    if v_status <> 'suspended' then
      raise exception 'That account is not suspended.';
    end if;
    update profiles set approval_status = 'approved' where profile_id = p_profile;
    update auth.users set banned_until = null where id = p_profile;
  end if;
end;
$$;
revoke all on function public.admin_set_account_suspended(uuid, boolean) from public, anon;
grant execute on function public.admin_set_account_suspended(uuid, boolean) to authenticated;

create or replace function public.admin_remove_account(p_profile uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_role text;
  v_email text;
  v_placeholder text;
begin
  if (select current_user_role()) is distinct from 'admin' then
    raise exception 'Only an administrator can do this.' using errcode = '42501';
  end if;
  if p_profile = auth.uid() then
    raise exception 'You cannot remove your own account here.';
  end if;
  select role, email into v_role, v_email from profiles where profile_id = p_profile;
  if v_role is null then
    raise exception 'That account was not found.';
  end if;
  if v_role = 'admin' then
    raise exception 'An administrator account cannot be removed here.';
  end if;
  if v_email like '%@deleted.invalid' then
    raise exception 'That account has already been removed.';
  end if;

  v_placeholder := 'deleted-' || p_profile || '@deleted.invalid';

  update profiles
     set full_name = 'Deleted user', phone = null, date_of_birth = null,
         address_text = null, address_lat = null, address_lng = null,
         avatar_url = null, email = v_placeholder
   where profile_id = p_profile;

  update students
     set programme = null, faculty = null, semester = null, cgpa = null,
         skills = '{}', resume_path = null, resume_filename = null,
         resume_size_bytes = null, resume_uploaded_at = null, student_reg_no = null
   where profile_id = p_profile;

  update students set academic_supervisor_id = null where academic_supervisor_id = p_profile;

  delete from work_experiences where student_id = p_profile;
  delete from notifications where user_id = p_profile;
  delete from parent_child_links where parent_id = p_profile or student_id = p_profile;

  update messages
     set body = '[message removed]', attachment_path = null,
         attachment_file_name = null, attachment_size_bytes = null
   where sender_id = p_profile;

  update auth.users
     set email = v_placeholder, phone = null, raw_user_meta_data = '{}'::jsonb,
         banned_until = '2999-12-31'::timestamptz
   where id = p_profile;
  update auth.identities
     set identity_data = jsonb_build_object('sub', p_profile::text, 'email', v_placeholder)
   where user_id = p_profile;
  delete from auth.sessions where user_id = p_profile;
end;
$$;
revoke all on function public.admin_remove_account(uuid) from public, anon;
grant execute on function public.admin_remove_account(uuid) to authenticated;

create or replace function public.admin_company_staff(p_company uuid)
returns table (profile_id uuid, role text, full_name text, email text, approval_status text, last_sign_in_at timestamptz)
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
      left join auth.users u on u.id = p.profile_id
     where p.email not like '%@deleted.invalid'
       and (p.profile_id in (select h.profile_id from company_hr h where h.company_id = p_company)
         or p.profile_id in (select s.profile_id from company_supervisors s where s.company_id = p_company))
     order by p.role, p.full_name;
end;
$$;
revoke all on function public.admin_company_staff(uuid) from public, anon;
grant execute on function public.admin_company_staff(uuid) to authenticated;

create or replace function public.deleted_profiles(p_ids uuid[])
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select profile_id from profiles where profile_id = any(p_ids) and email like '%@deleted.invalid';
$$;
revoke all on function public.deleted_profiles(uuid[]) from public, anon;
grant execute on function public.deleted_profiles(uuid[]) to authenticated;
