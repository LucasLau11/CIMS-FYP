-- 00041: fixes from the first round of phone testing.
--
--  1. Notifications are stored as a message KEY plus its values (msg_key, msg_args) and are turned
--     into text when they are READ or pushed, in the reader's current language. Before, the text
--     was written once in whatever language the sender used, so a person's list could mix
--     English and Chinese. Old rows without a key keep their stored text.
--  2. Accounts an administrator creates really are approved straight away. The Edge Function
--     marks the new user with app_metadata, but Supabase only writes that AFTER the row exists,
--     so the sign-up trigger could not see it: supervisors came out "pending", and students were
--     refused. The function now leaves a one-off permission in admin_account_grants first.
--  3. email_has_account(): lets the login screen say whether the EMAIL or the PASSWORD was wrong.
--  4. admin_account_activity(): when each account last signed in, for the admin lists.
--  5. Deleted (anonymised) accounts no longer show up in anybody's lists.

-- ---------------------------------------------------------------------------------------
-- 1. Localised notifications
-- ---------------------------------------------------------------------------------------
alter table public.notifications add column if not exists msg_key text;
alter table public.notifications add column if not exists msg_args jsonb;

create table if not exists public.notification_templates (
  msg_key text not null,
  lang    text not null check (lang in ('en', 'ms', 'zh')),
  title   text not null,
  body    text not null,
  primary key (msg_key, lang)
);
alter table public.notification_templates enable row level security;
-- No policies: only the functions below (security definer) read it.

insert into public.notification_templates (msg_key, lang, title, body) values
 ('app_submitted','en','Application submitted','Your application to {company} has been sent.'),
 ('app_submitted','ms','Permohonan dihantar','Permohonan anda kepada {company} telah dihantar.'),
 ('app_submitted','zh','申请已提交','您对{company}的申请已发送。'),

 ('offer_received','en','You have an internship offer','Congratulations! You have been offered {role}. Open My Applications to accept it. You can hold several offers, but once you accept one the others are closed.'),
 ('offer_received','ms','Anda mendapat tawaran latihan industri','Tahniah! Anda telah ditawarkan {role}. Buka Permohonan Saya untuk menerimanya. Anda boleh memegang beberapa tawaran, tetapi setelah anda menerima satu, yang lain akan ditutup.'),
 ('offer_received','zh','您收到了实习录用通知','恭喜！您已获得{role}的录用。请打开“我的申请”接受。您可以同时持有多个录用，但接受其中一个后，其余将被关闭。'),

 ('application_rejected','en','Application update','Your application for {role} was not successful this time. Reason: {reason}'),
 ('application_rejected','ms','Kemas kini permohonan','Permohonan anda untuk {role} tidak berjaya kali ini. Sebab: {reason}'),
 ('application_rejected','zh','申请更新','您申请的{role}这次未获通过。原因：{reason}'),

 ('application_update','en','Application update','There is an update on {role}.'),
 ('application_update','ms','Kemas kini permohonan','Ada kemas kini mengenai {role}.'),
 ('application_update','zh','申请更新','{role}有新的更新。'),

 ('offer_accepted','en','Offer accepted','{student} accepted your offer for {role}.'),
 ('offer_accepted','ms','Tawaran diterima','{student} menerima tawaran anda untuk {role}.'),
 ('offer_accepted','zh','录用已接受','{student}已接受您为{role}发出的录用。'),

 ('candidate_unavailable','en','Candidate no longer available','{student} accepted another offer, so their application for {role} has been closed.'),
 ('candidate_unavailable','ms','Calon tidak lagi tersedia','{student} menerima tawaran lain, jadi permohonan mereka untuk {role} telah ditutup.'),
 ('candidate_unavailable','zh','候选人已不可用','{student}已接受其他录用，因此其{role}的申请已关闭。'),

 ('interview_scheduled','en','Interview scheduled','You have an interview for {role} on {when}.'),
 ('interview_scheduled','ms','Temu duga dijadualkan','Anda mempunyai temu duga untuk {role} pada {when}.'),
 ('interview_scheduled','zh','面试已安排','您有一场{role}的面试，时间：{when}。'),

 ('interview_cancelled_by_student','en','Interview cancelled','The student cancelled the interview for {role} on {when}. Reason: {reason}'),
 ('interview_cancelled_by_student','ms','Temu duga dibatalkan','Pelajar membatalkan temu duga untuk {role} pada {when}. Sebab: {reason}'),
 ('interview_cancelled_by_student','zh','面试已取消','学生取消了{role}的面试（{when}）。原因：{reason}'),
 ('interview_cancelled_by_company','en','Interview cancelled','The company cancelled the interview for {role} on {when}. Reason: {reason} The company will arrange a new time.'),
 ('interview_cancelled_by_company','ms','Temu duga dibatalkan','Syarikat membatalkan temu duga untuk {role} pada {when}. Sebab: {reason} Syarikat akan mengatur masa baharu.'),
 ('interview_cancelled_by_company','zh','面试已取消','公司取消了{role}的面试（{when}）。原因：{reason} 公司将安排新的时间。'),

 ('reschedule_requested_by_student','en','Reschedule requested','The student asks to move the interview for {role} from {from} to {to}. Reason: {reason} Open the interview to accept or decline; it stays as it is until you accept.'),
 ('reschedule_requested_by_student','ms','Permintaan jadual semula','Pelajar meminta untuk menukar temu duga untuk {role} dari {from} ke {to}. Sebab: {reason} Buka temu duga untuk menerima atau menolak; ia kekal seperti sedia ada sehingga anda menerima.'),
 ('reschedule_requested_by_student','zh','请求改期','学生请求将{role}的面试从{from}改到{to}。原因：{reason} 请打开面试以接受或拒绝；在您接受之前，面试时间保持不变。'),
 ('reschedule_requested_by_company','en','Reschedule requested','The company asks to move the interview for {role} from {from} to {to}. Reason: {reason} Open the interview to accept or decline; it stays as it is until you accept.'),
 ('reschedule_requested_by_company','ms','Permintaan jadual semula','Syarikat meminta untuk menukar temu duga untuk {role} dari {from} ke {to}. Sebab: {reason} Buka temu duga untuk menerima atau menolak; ia kekal seperti sedia ada sehingga anda menerima.'),
 ('reschedule_requested_by_company','zh','请求改期','公司请求将{role}的面试从{from}改到{to}。原因：{reason} 请打开面试以接受或拒绝；在您接受之前，面试时间保持不变。'),

 ('reschedule_declined_by_company','en','Reschedule declined','The company declined moving the interview for {role}. It stays on {when}. Reason: {reason}'),
 ('reschedule_declined_by_company','ms','Jadual semula ditolak','Syarikat menolak pertukaran temu duga untuk {role}. Ia kekal pada {when}. Sebab: {reason}'),
 ('reschedule_declined_by_company','zh','改期被拒绝','公司拒绝了{role}面试的改期。面试仍在{when}。原因：{reason}'),
 ('reschedule_declined_by_student','en','Reschedule declined','The student declined moving the interview for {role}. It stays on {when}. Reason: {reason}'),
 ('reschedule_declined_by_student','ms','Jadual semula ditolak','Pelajar menolak pertukaran temu duga untuk {role}. Ia kekal pada {when}. Sebab: {reason}'),
 ('reschedule_declined_by_student','zh','改期被拒绝','学生拒绝了{role}面试的改期。面试仍在{when}。原因：{reason}'),

 ('reschedule_accepted_by_company','en','Reschedule accepted','The company accepted. The interview for {role} is now on {when}.'),
 ('reschedule_accepted_by_company','ms','Jadual semula diterima','Syarikat bersetuju. Temu duga untuk {role} kini pada {when}.'),
 ('reschedule_accepted_by_company','zh','改期已接受','公司已同意。{role}的面试现在是{when}。'),
 ('reschedule_accepted_by_student','en','Reschedule accepted','The student accepted. The interview for {role} is now on {when}.'),
 ('reschedule_accepted_by_student','ms','Jadual semula diterima','Pelajar bersetuju. Temu duga untuk {role} kini pada {when}.'),
 ('reschedule_accepted_by_student','zh','改期已接受','学生已同意。{role}的面试现在是{when}。'),

 ('interview_reminder_1h','en','Interview in 1 hour','Your interview for {role} starts in about an hour: {when}.'),
 ('interview_reminder_1h','ms','Temu duga dalam 1 jam','Temu duga anda untuk {role} bermula dalam kira-kira sejam: {when}.'),
 ('interview_reminder_1h','zh','面试将在1小时后开始','您的{role}面试将在大约一小时后开始：{when}。'),
 ('interview_reminder_24h','en','Interview tomorrow','Your interview for {role} is coming up in the next 24 hours: {when}.'),
 ('interview_reminder_24h','ms','Temu duga esok','Temu duga anda untuk {role} akan berlangsung dalam 24 jam akan datang: {when}.'),
 ('interview_reminder_24h','zh','面试即将到来','您的{role}面试将在未来24小时内举行：{when}。'),

 ('report_submitted','en','Report submitted','{period} has been submitted.'),
 ('report_submitted','ms','Laporan dihantar','{period} telah dihantar.'),
 ('report_submitted','zh','报告已提交','{period}已提交。'),

 ('document_uploaded','en','Document uploaded','{file} has been uploaded.'),
 ('document_uploaded','ms','Dokumen dimuat naik','{file} telah dimuat naik.'),
 ('document_uploaded','zh','文件已上传','{file}已上传。'),

 ('document_signed_self','en','Document signed','{file} has been signed and saved.'),
 ('document_signed_self','ms','Dokumen ditandatangani','{file} telah ditandatangani dan disimpan.'),
 ('document_signed_self','zh','文件已签署','{file}已签署并保存。'),

 ('offer_letter_uploaded','en','Offer letter uploaded','{file} has been uploaded by your company.'),
 ('offer_letter_uploaded','ms','Surat tawaran dimuat naik','{file} telah dimuat naik oleh syarikat anda.'),
 ('offer_letter_uploaded','zh','录用信已上传','{file}已由贵公司上传。'),

 ('document_signed_company','en','Document signed','{file} has been signed by your company.'),
 ('document_signed_company','ms','Dokumen ditandatangani','{file} telah ditandatangani oleh syarikat anda.'),
 ('document_signed_company','zh','文件已签署','{file}已由贵公司签署。')
on conflict (msg_key, lang) do update set title = excluded.title, body = excluded.body;

-- An instant written in the reader's language (Malaysia time).
create or replace function public._notif_when(p_at timestamptz, p_lang text)
returns text
language sql
immutable
set search_path = public
as $$
  select case p_lang
    when 'ms' then
      (array['Isn','Sel','Rab','Kha','Jum','Sab','Ahd'])[extract(isodow from p_at at time zone 'Asia/Kuala_Lumpur')::int]
      || ' ' || to_char(p_at at time zone 'Asia/Kuala_Lumpur', 'DD') || ' '
      || (array['Jan','Feb','Mac','Apr','Mei','Jun','Jul','Ogo','Sep','Okt','Nov','Dis'])[extract(month from p_at at time zone 'Asia/Kuala_Lumpur')::int]
      || ' ' || to_char(p_at at time zone 'Asia/Kuala_Lumpur', 'YYYY, HH24:MI')
    when 'zh' then
      to_char(p_at at time zone 'Asia/Kuala_Lumpur', 'YYYY"年"FMMM"月"FMDD"日"')
      || ' ' || (array['周一','周二','周三','周四','周五','周六','周日'])[extract(isodow from p_at at time zone 'Asia/Kuala_Lumpur')::int]
      || ' ' || to_char(p_at at time zone 'Asia/Kuala_Lumpur', 'HH24:MI')
    else
      to_char(p_at at time zone 'Asia/Kuala_Lumpur', 'Dy DD Mon YYYY, HH12:MI AM')
  end;
$$;

-- Title and body for a stored message key, filled with its values, in [p_lang]. Returns no row
-- when the key is unknown (old notifications), so callers fall back to the stored text.
create or replace function public.render_notification(p_key text, p_args jsonb, p_lang text)
returns table (title text, body text)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_lang text := case when p_lang in ('ms', 'zh') then p_lang else 'en' end;
  v_title text;
  v_body text;
  r record;
  v_value text;
begin
  if p_key is null then
    return;
  end if;
  select t.title, t.body into v_title, v_body
    from notification_templates t where t.msg_key = p_key and t.lang = v_lang;
  if v_title is null then
    return;
  end if;

  for r in select key, value from jsonb_each_text(coalesce(p_args, '{}'::jsonb)) loop
    v_value := r.value;
    if r.key in ('when', 'from', 'to') and v_value ~ '^\d{4}-\d{2}-\d{2}T' then
      v_value := _notif_when(v_value::timestamptz, v_lang);
    end if;
    -- A student with no name on the profile.
    if r.key = 'student' and btrim(v_value) = '' then
      v_value := case v_lang when 'ms' then 'Seorang pelajar' when 'zh' then '一名学生' else 'A student' end;
    end if;
    v_title := replace(v_title, '{' || r.key || '}', v_value);
    v_body := replace(v_body, '{' || r.key || '}', v_value);
  end loop;

  title := v_title;
  body := v_body;
  return next;
end;
$$;

revoke all on function public.render_notification(text, jsonb, text) from public, anon;
grant execute on function public.render_notification(text, jsonb, text) to authenticated, service_role;

-- Language code of a profile ('English' / 'Bahasa Malaysia' / '中文' -> en / ms / zh).
create or replace function public._profile_lang(p_profile uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select case language when 'Bahasa Malaysia' then 'ms' when '中文' then 'zh' else 'en' end
    from profiles where profile_id = p_profile;
$$;
revoke all on function public._profile_lang(uuid) from public, anon;
grant execute on function public._profile_lang(uuid) to authenticated, service_role;

-- What the app reads: the caller's own notifications, written in the language they have now.
create or replace view public.v_notifications
with (security_invoker = true) as
select n.notification_id,
       n.user_id,
       coalesce(r.title, n.title) as title,
       coalesce(r.body, n.body) as body,
       n.type,
       n.related_id,
       n.read,
       n.created_at
  from public.notifications n
  left join lateral public.render_notification(n.msg_key, n.msg_args, public._profile_lang(n.user_id)) r on true;

grant select on public.v_notifications to authenticated;

-- ---- the functions that write notifications now write keys ----
create or replace function public.accept_offer(p_application_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid  uuid := auth.uid();
  v_app  applications%rowtype;
  v_name text;
begin
  if v_uid is null or (select current_user_role()) is distinct from 'student' then
    raise exception 'Only a signed-in student can accept an offer.';
  end if;

  perform 1 from applications where student_id = v_uid for update;

  select * into v_app from applications
   where application_id = p_application_id and student_id = v_uid;
  if not found then
    raise exception 'That application was not found.';
  end if;
  if v_app.status = 'active' then
    raise exception 'You have already accepted this offer.';
  end if;
  if v_app.status <> 'offered' then
    raise exception 'This application does not have an offer you can accept.';
  end if;
  if exists (select 1 from applications where student_id = v_uid and status = 'active') then
    raise exception 'You have already accepted another offer. Only one internship can be active.';
  end if;

  select full_name into v_name from profiles where profile_id = v_uid;

  update applications set status = 'active', updated_at = now()
   where application_id = p_application_id;

  insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
  select h.profile_id,
         'Offer accepted',
         coalesce(nullif(btrim(v_name), ''), 'A student') || ' accepted your offer for ' || jp.title || '.',
         'application',
         v_app.application_id,
         'offer_accepted',
         jsonb_build_object('student', coalesce(nullif(btrim(v_name), ''), ''), 'role', jp.title)
    from job_postings jp
    join company_hr h on h.company_id = jp.company_id
   where jp.job_posting_id = v_app.job_posting_id;

  with closed as (
    update applications set status = 'unavailable', updated_at = now()
     where student_id = v_uid
       and application_id <> p_application_id
       and status in ('pending', 'interview', 'offered')
    returning application_id, job_posting_id
  )
  insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
  select h.profile_id,
         'Candidate no longer available',
         coalesce(nullif(btrim(v_name), ''), 'A student') || ' accepted another offer, so their application for '
           || jp.title || ' has been closed.',
         'application',
         c.application_id,
         'candidate_unavailable',
         jsonb_build_object('student', coalesce(nullif(btrim(v_name), ''), ''), 'role', jp.title)
    from closed c
    join job_postings jp on jp.job_posting_id = c.job_posting_id
    join company_hr h on h.company_id = jp.company_id;
end;
$$;

create or replace function public.book_interview(
  p_application_id uuid, p_start timestamptz, p_mode text, p_location text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_app applications%rowtype;
  v_company uuid;
  v_title text;
  v_end timestamptz;
  v_interview interviews%rowtype;
  v_id uuid;
begin
  if v_uid is null or (select current_user_role()) is distinct from 'company_hr' then
    raise exception 'Only the company''s HR can schedule interviews.';
  end if;
  if p_mode not in ('online', 'in_person') then
    raise exception 'Choose online or in person.';
  end if;
  if char_length(btrim(coalesce(p_location, ''))) = 0 or char_length(p_location) > 500 then
    raise exception 'Enter the meeting link or address (up to 500 characters).';
  end if;

  select a.* into v_app from applications a where a.application_id = p_application_id for update;
  if not found then raise exception 'That application was not found.'; end if;
  select jp.company_id, jp.title into v_company, v_title from job_postings jp where jp.job_posting_id = v_app.job_posting_id;
  if not exists (select 1 from company_hr h where h.profile_id = v_uid and h.company_id = v_company) then
    raise exception 'That application does not belong to your company.';
  end if;

  select * into v_interview from interviews where application_id = p_application_id for update;
  if v_app.status = 'pending' then
    null;
  elsif v_app.status = 'interview' and found and v_interview.status = 'cancelled' then
    null;
  elsif v_app.status = 'interview' and found and v_interview.status = 'scheduled' then
    raise exception 'An interview is already scheduled. Use reschedule instead.';
  else
    raise exception 'An interview cannot be scheduled for an application that is %.', v_app.status;
  end if;

  select f.slot_end into v_end
    from interview_free_slots(v_uid, (p_start at time zone 'Asia/Kuala_Lumpur')::date,
                              (p_start at time zone 'Asia/Kuala_Lumpur')::date) f
   where f.slot_start = p_start;
  if v_end is null then
    raise exception 'That time slot is no longer available. Please pick another.';
  end if;

  begin
    if v_interview.interview_id is null then
      insert into interviews (application_id, scheduled_at, ends_at, mode, location, interviewer_id, status)
      values (p_application_id, p_start, v_end, p_mode, btrim(p_location), v_uid, 'scheduled')
      returning interview_id into v_id;
    else
      update interviews
         set scheduled_at = p_start, ends_at = v_end, mode = p_mode, location = btrim(p_location),
             interviewer_id = v_uid, status = 'scheduled'
       where interview_id = v_interview.interview_id
      returning interview_id into v_id;
    end if;
  exception when exclusion_violation then
    raise exception 'That time slot was just taken. Please pick another.';
  end;

  if v_app.status = 'pending' then
    update applications set status = 'interview', updated_at = now() where application_id = p_application_id;
  end if;

  insert into interview_changes (interview_id, action, actor_id, actor_role, new_start)
  values (v_id, 'booked', v_uid, 'company_hr', p_start);

  insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
  values (v_app.student_id, 'Interview scheduled',
          'You have an interview for ' || v_title || ' on ' || _interview_when(p_start) || '.',
          'application', p_application_id,
          'interview_scheduled',
          jsonb_build_object('role', v_title, 'when', to_char(p_start at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')));

  return v_id;
end;
$$;

create or replace function public.cancel_interview(p_interview_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text := (select current_user_role());
  v_i interviews%rowtype;
  v_app applications%rowtype;
  v_company uuid;
  v_title text;
  v_by text;
  v_notify uuid;
begin
  select * into v_i from interviews where interview_id = p_interview_id for update;
  if not found then raise exception 'That interview was not found.'; end if;
  select * into v_app from applications where application_id = v_i.application_id;
  select jp.company_id, jp.title into v_company, v_title from job_postings jp where jp.job_posting_id = v_app.job_posting_id;

  if v_role = 'student' and v_app.student_id = v_uid then
    v_by := 'student';
  elsif v_role = 'company_hr' and exists (select 1 from company_hr h where h.profile_id = v_uid and h.company_id = v_company) then
    v_by := 'company_hr';
  else
    raise exception 'You are not allowed to change this interview.';
  end if;

  if v_i.status <> 'scheduled' then
    raise exception 'Only a scheduled interview can be cancelled.';
  end if;
  if v_i.scheduled_at - now() < interval '2 hours' then
    raise exception 'An interview can only be changed at least 2 hours before it starts.';
  end if;
  if char_length(btrim(coalesce(p_reason, ''))) < 10 or char_length(p_reason) > 500 then
    raise exception 'Please give a reason of 10 to 500 characters.';
  end if;

  update interviews set status = 'cancelled' where interview_id = p_interview_id;

  insert into interview_changes (interview_id, action, actor_id, actor_role, reason, old_start)
  values (p_interview_id, 'cancelled', v_uid, v_by, btrim(p_reason), v_i.scheduled_at);

  v_notify := case when v_by = 'student' then v_i.interviewer_id else v_app.student_id end;
  insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
  values (v_notify, 'Interview cancelled',
          case when v_by = 'student' then 'The student' else 'The company' end
            || ' cancelled the interview for ' || v_title || ' on ' || _interview_when(v_i.scheduled_at)
            || '. Reason: ' || btrim(p_reason)
            || case when v_by = 'company_hr' then ' The company will arrange a new time.' else '' end,
          'application', v_app.application_id,
          case when v_by = 'student' then 'interview_cancelled_by_student' else 'interview_cancelled_by_company' end,
          jsonb_build_object('role', v_title,
                             'when', to_char(v_i.scheduled_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
                             'reason', btrim(p_reason)));
end;
$$;

create or replace function public.request_reschedule(p_interview_id uuid, p_new_start timestamptz, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text := (select current_user_role());
  v_i interviews%rowtype;
  v_app applications%rowtype;
  v_company uuid;
  v_title text;
  v_by text;
  v_interviewer uuid;
  v_end timestamptz;
  v_id uuid;
  v_notify uuid;
begin
  select * into v_i from interviews where interview_id = p_interview_id for update;
  if not found then raise exception 'That interview was not found.'; end if;
  select * into v_app from applications where application_id = v_i.application_id;
  select jp.company_id, jp.title into v_company, v_title from job_postings jp where jp.job_posting_id = v_app.job_posting_id;

  if v_role = 'student' and v_app.student_id = v_uid then
    v_by := 'student';
  elsif v_role = 'company_hr' and exists (select 1 from company_hr h where h.profile_id = v_uid and h.company_id = v_company) then
    v_by := 'company_hr';
  else
    raise exception 'You are not allowed to change this interview.';
  end if;

  if v_i.status <> 'scheduled' then
    raise exception 'Only a scheduled interview can be rescheduled.';
  end if;
  if v_i.scheduled_at - now() < interval '2 hours' then
    raise exception 'An interview can only be changed at least 2 hours before it starts.';
  end if;
  if char_length(btrim(coalesce(p_reason, ''))) < 10 or char_length(p_reason) > 500 then
    raise exception 'Please give a reason of 10 to 500 characters.';
  end if;
  if exists (select 1 from interview_reschedule_requests where interview_id = p_interview_id and status = 'pending') then
    raise exception 'A reschedule request for this interview is already waiting for an answer.';
  end if;

  v_interviewer := case when v_by = 'company_hr' then v_uid else v_i.interviewer_id end;

  select f.slot_end into v_end
    from interview_free_slots(v_interviewer, (p_new_start at time zone 'Asia/Kuala_Lumpur')::date,
                              (p_new_start at time zone 'Asia/Kuala_Lumpur')::date) f
   where f.slot_start = p_new_start;
  if v_end is null then
    raise exception 'That time slot is not available. Please pick another.';
  end if;

  insert into interview_reschedule_requests
    (interview_id, requested_by, requested_role, proposed_interviewer_id, proposed_start, proposed_end, reason)
  values (p_interview_id, v_uid, v_by, v_interviewer, p_new_start, v_end, btrim(p_reason))
  returning request_id into v_id;

  insert into interview_changes (interview_id, action, actor_id, actor_role, reason, old_start, new_start)
  values (p_interview_id, 'reschedule_requested', v_uid, v_by, btrim(p_reason), v_i.scheduled_at, p_new_start);

  v_notify := case when v_by = 'student' then v_i.interviewer_id else v_app.student_id end;
  insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
  values (v_notify, 'Reschedule requested',
          case when v_by = 'student' then 'The student' else 'The company' end
            || ' asks to move the interview for ' || v_title || ' from ' || _interview_when(v_i.scheduled_at)
            || ' to ' || _interview_when(p_new_start) || '. Reason: ' || btrim(p_reason)
            || ' Open the interview to accept or decline; it stays as it is until you accept.',
          'interview_request', v_app.application_id,
          case when v_by = 'student' then 'reschedule_requested_by_student' else 'reschedule_requested_by_company' end,
          jsonb_build_object('role', v_title,
                             'from', to_char(v_i.scheduled_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
                             'to', to_char(p_new_start at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
                             'reason', btrim(p_reason)));

  return v_id;
end;
$$;

create or replace function public.respond_reschedule(p_request_id uuid, p_accept boolean, p_note text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text := (select current_user_role());
  v_r interview_reschedule_requests%rowtype;
  v_i interviews%rowtype;
  v_app applications%rowtype;
  v_company uuid;
  v_title text;
  v_ok boolean := false;
  v_end timestamptz;
  v_req_side text;
begin
  select * into v_r from interview_reschedule_requests where request_id = p_request_id for update;
  if not found then raise exception 'That request was not found.'; end if;
  if v_r.status <> 'pending' then
    raise exception 'This request has already been answered or is no longer valid.';
  end if;

  select * into v_i from interviews where interview_id = v_r.interview_id for update;
  select * into v_app from applications where application_id = v_i.application_id;
  select jp.company_id, jp.title into v_company, v_title from job_postings jp where jp.job_posting_id = v_app.job_posting_id;

  if v_r.requested_role = 'student' then
    v_ok := v_role = 'company_hr' and exists (select 1 from company_hr h where h.profile_id = v_uid and h.company_id = v_company);
  else
    v_ok := v_role = 'student' and v_app.student_id = v_uid;
  end if;
  if not v_ok then
    raise exception 'Only the other side of this interview can answer this request.';
  end if;

  if v_i.status <> 'scheduled' then
    raise exception 'This interview is no longer scheduled, so the request is no longer valid.';
  end if;
  if v_i.scheduled_at - now() < interval '2 hours' then
    raise exception 'The interview is less than 2 hours away, so it can no longer be changed.';
  end if;

  -- who answers (the side that did NOT ask)
  v_req_side := case when v_r.requested_role = 'student' then 'company' else 'student' end;

  if not p_accept then
    if char_length(btrim(coalesce(p_note, ''))) < 10 or char_length(p_note) > 500 then
      raise exception 'Please give a reason of 10 to 500 characters for declining.';
    end if;
    update interview_reschedule_requests
       set status = 'declined', responded_by = v_uid, response_note = btrim(p_note), responded_at = now()
     where request_id = p_request_id;
    insert into interview_changes (interview_id, action, actor_id, actor_role, reason, old_start, new_start)
    values (v_i.interview_id, 'reschedule_declined', v_uid,
            case when v_r.requested_role = 'student' then 'company_hr' else 'student' end,
            btrim(p_note), v_i.scheduled_at, v_r.proposed_start);
    insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
    values (v_r.requested_by, 'Reschedule declined',
            case when v_r.requested_role = 'student' then 'The company' else 'The student' end
              || ' declined moving the interview for ' || v_title || '. It stays on ' || _interview_when(v_i.scheduled_at)
              || '. Reason: ' || btrim(p_note),
            'application', v_app.application_id,
            'reschedule_declined_by_' || v_req_side,
            jsonb_build_object('role', v_title,
                               'when', to_char(v_i.scheduled_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
                               'reason', btrim(p_note)));
    return;
  end if;

  update interview_reschedule_requests
     set status = 'accepted', responded_by = v_uid, responded_at = now()
   where request_id = p_request_id;

  select f.slot_end into v_end
    from _interview_slots(v_r.proposed_interviewer_id, (v_r.proposed_start at time zone 'Asia/Kuala_Lumpur')::date,
                          (v_r.proposed_start at time zone 'Asia/Kuala_Lumpur')::date) f
   where f.slot_start = v_r.proposed_start;
  if v_end is null then
    raise exception 'That time is no longer available, so the interview cannot be moved there. Ask for another time.';
  end if;

  begin
    update interviews
       set scheduled_at = v_r.proposed_start, ends_at = v_end, interviewer_id = v_r.proposed_interviewer_id
     where interview_id = v_i.interview_id;
  exception when exclusion_violation then
    raise exception 'That time was just taken, so the interview cannot be moved there. Ask for another time.';
  end;

  insert into interview_changes (interview_id, action, actor_id, actor_role, reason, old_start, new_start)
  values (v_i.interview_id, 'rescheduled', v_r.requested_by, v_r.requested_role, v_r.reason, v_i.scheduled_at, v_r.proposed_start);

  insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
  values (v_r.requested_by, 'Reschedule accepted',
          case when v_r.requested_role = 'student' then 'The company' else 'The student' end
            || ' accepted. The interview for ' || v_title || ' is now on ' || _interview_when(v_r.proposed_start) || '.',
          'application', v_app.application_id,
          'reschedule_accepted_by_' || v_req_side,
          jsonb_build_object('role', v_title,
                             'when', to_char(v_r.proposed_start at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')));
end;
$$;

create or replace function public.run_interview_maintenance()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
  v_kind text;
  v_title text;
  v_student uuid;
  v_text text;
  v_args jsonb;
  v_reminders int := 0;
  v_completed int := 0;
begin
  for r in
    select i.interview_id, i.application_id, i.interviewer_id, i.scheduled_at,
           case when i.scheduled_at - now() <= interval '1 hour' then '1h' else '24h' end as kind
      from interviews i
     where i.status = 'scheduled'
       and i.scheduled_at > now()
       and i.scheduled_at - now() <= interval '24 hours'
  loop
    v_kind := r.kind;
    begin
      insert into interview_reminders (interview_id, kind, for_start) values (r.interview_id, v_kind, r.scheduled_at);
    exception when unique_violation then
      continue;
    end;

    select jp.title, a.student_id into v_title, v_student
      from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
     where a.application_id = r.application_id;

    v_text := case v_kind when '1h' then 'starts in about an hour' else 'is coming up in the next 24 hours' end;
    v_args := jsonb_build_object('role', v_title,
                                 'when', to_char(r.scheduled_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'));

    insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
    values (v_student,
            case v_kind when '1h' then 'Interview in 1 hour' else 'Interview tomorrow' end,
            'Your interview for ' || v_title || ' ' || v_text || ': ' || _interview_when(r.scheduled_at) || '.',
            'interview_reminder', r.application_id,
            'interview_reminder_' || v_kind, v_args);
    if r.interviewer_id is not null then
      insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
      values (r.interviewer_id,
              case v_kind when '1h' then 'Interview in 1 hour' else 'Interview tomorrow' end,
              'Your interview for ' || v_title || ' ' || v_text || ': ' || _interview_when(r.scheduled_at) || '.',
              'interview_reminder', r.application_id,
              'interview_reminder_' || v_kind, v_args);
    end if;
    v_reminders := v_reminders + 1;
  end loop;

  update interviews set status = 'completed' where status = 'scheduled' and ends_at < now();
  get diagnostics v_completed = row_count;

  return jsonb_build_object('reminders', v_reminders, 'completed', v_completed);
end;
$$;

-- ---------------------------------------------------------------------------------------
-- 2. Accounts created by an administrator
-- ---------------------------------------------------------------------------------------
create table if not exists public.admin_account_grants (
  email      text primary key,
  created_at timestamptz not null default now()
);
alter table public.admin_account_grants enable row level security;
-- No policies: only the service role (the Edge Function) and the sign-up trigger touch it.

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text := new.raw_user_meta_data->>'app_role';
  v_name text := left(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 100);
  v_by_admin boolean := coalesce((new.raw_app_meta_data->>'created_by_admin')::boolean, false);
  v_must_change boolean;
begin
  if v_role is null or v_role not in
     ('student', 'academic_supervisor', 'company_hr', 'company_supervisor') then
    return new;
  end if;

  -- Supabase writes app_metadata after the row exists, so an administrator's request is also
  -- recognised by a one-off permission left for this exact email in the last few minutes.
  if not v_by_admin then
    delete from admin_account_grants
     where lower(email) = lower(new.email) and created_at > now() - interval '10 minutes';
    v_by_admin := found;
    v_must_change := v_by_admin;
  else
    v_must_change := coalesce((new.raw_app_meta_data->>'must_change_password')::boolean, false);
  end if;

  if v_role = 'student' and not v_by_admin then
    raise exception 'Student accounts are created by the administrator.';
  end if;

  insert into profiles (profile_id, role, email, full_name, approval_status, must_change_password)
  values (
    new.id, v_role, new.email, v_name,
    case when v_role in ('academic_supervisor', 'company_hr', 'company_supervisor') and not v_by_admin
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
$$;

-- ---------------------------------------------------------------------------------------
-- 3. Which of "email" and "password" was wrong
-- ---------------------------------------------------------------------------------------
create or replace function public.email_has_account(p_email text)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1 from auth.users
     where lower(email) = lower(btrim(p_email))
       and email not like '%@deleted.invalid'
  );
$$;
revoke all on function public.email_has_account(text) from public;
grant execute on function public.email_has_account(text) to anon, authenticated;

-- ---------------------------------------------------------------------------------------
-- 4. Admin: who has signed in yet
-- ---------------------------------------------------------------------------------------
create or replace function public.admin_account_activity()
returns table (profile_id uuid, last_sign_in_at timestamptz)
language plpgsql
stable
security definer
set search_path = public, auth
as $$
begin
  if (select current_user_role()) is distinct from 'admin' then
    raise exception 'Only an administrator can see this.' using errcode = '42501';
  end if;
  return query select u.id, u.last_sign_in_at from auth.users u;
end;
$$;
revoke all on function public.admin_account_activity() from public, anon;
grant execute on function public.admin_account_activity() to authenticated;

-- ---------------------------------------------------------------------------------------
-- 5. Deleted accounts stay out of everybody's lists
-- ---------------------------------------------------------------------------------------
create or replace function public.is_deleted_profile(p_profile uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select email like '%@deleted.invalid' from profiles where profile_id = p_profile), false);
$$;
revoke all on function public.is_deleted_profile(uuid) from public, anon;
grant execute on function public.is_deleted_profile(uuid) to authenticated;

create or replace function public.can_view_profile(p_target uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    p_target = (select auth.uid())
    or (
      not is_deleted_profile(p_target)
      and (
        (select current_user_role()) = 'admin'
        or exists (select 1 from profiles t where t.profile_id = p_target
                   and t.role in ('academic_supervisor', 'company_hr', 'company_supervisor', 'admin'))
        or is_academic_supervisor_of(p_target)
        or exists (select 1 from profile_conversations a
                   join profile_conversations b using (conversation_id)
                   where a.profile_id = (select auth.uid()) and b.profile_id = p_target)
        or exists (select 1 from applications a
                   join job_postings jp on jp.job_posting_id = a.job_posting_id
                   where a.student_id = p_target and is_my_company(jp.company_id))
      )
    );
$function$;
