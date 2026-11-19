-- 00032: expired postings close themselves; a reschedule only happens when the other side accepts.
--
-- 1. Postings past their application deadline (Malaysian date) or their automatic closing time
--    are closed by close_expired_postings(), which the app calls whenever postings are listed
--    (it could also be scheduled with pg_cron, e.g. every 15 minutes, if that extension is
--    enabled). Independently of that, nobody can apply to an expired posting (applications_guard),
--    and a closed or expired posting cannot be re-opened until its dates are extended.
-- 2. Rescheduling is now a request: the requester proposes a new time and a reason, the other
--    party is notified and must accept (the interview then moves) or decline with a reason (it
--    stays where it is). The proposed slot is held, so nobody else can book it meanwhile.
--    reschedule_interview() is removed, so the approval step cannot be bypassed.

-- ---------------------------------------------------------------------------------------
-- 1. Expired postings
-- ---------------------------------------------------------------------------------------
create or replace function public.posting_has_expired(p_deadline date, p_closes_at timestamptz)
returns boolean
language sql
stable
set search_path = public
as $$
  select (p_deadline is not null and p_deadline < (now() at time zone 'Asia/Kuala_Lumpur')::date)
      or (p_closes_at is not null and p_closes_at <= now());
$$;

create or replace function public.close_expired_postings()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  n int;
begin
  update job_postings set status = 'closed'
   where status = 'open' and posting_has_expired(application_deadline, posting_closes_at);
  get diagnostics n = row_count;
  return n;
end;
$$;

revoke all on function public.close_expired_postings() from public, anon;
grant execute on function public.close_expired_postings() to authenticated;

-- An open posting must not be past its dates. (The function above closes it with a plain
-- UPDATE of status to 'closed', which this does not block.)
create or replace function public.job_postings_guard()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status = 'open' and posting_has_expired(new.application_deadline, new.posting_closes_at) then
    raise exception 'The deadline of this posting has passed. Extend the deadline or the closing date before it can be open.';
  end if;
  return new;
end;
$$;

drop trigger if exists job_postings_guard on public.job_postings;
create trigger job_postings_guard
  before insert or update on public.job_postings
  for each row execute function public.job_postings_guard();

-- Nobody can apply to a closed or expired posting.
create or replace function public.applications_guard()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_role text;
begin
  if current_user not in ('authenticated', 'anon') then
    return coalesce(new, old);
  end if;

  v_role := (select current_user_role());

  if tg_op = 'INSERT' then
    if new.status <> 'pending' then
      raise exception 'A new application must start as pending.';
    end if;
    new.rejection_reason := null;
    if exists (select 1 from applications where student_id = new.student_id and status = 'active') then
      raise exception 'You have already accepted an internship offer, so you cannot apply to other postings.';
    end if;
    if not exists (
         select 1 from job_postings jp
          where jp.job_posting_id = new.job_posting_id
            and jp.status = 'open'
            and not posting_has_expired(jp.application_deadline, jp.posting_closes_at)) then
      raise exception 'This posting is closed and no longer accepts applications.';
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    if v_role = 'admin' then
      return old;
    end if;
    if old.status <> 'pending' then
      raise exception 'Only a pending application can be withdrawn.';
    end if;
    return old;
  end if;

  if v_role = 'admin' then
    return new;
  end if;

  if new.student_id is distinct from old.student_id
     or new.job_posting_id is distinct from old.job_posting_id
     or new.cover_letter is distinct from old.cover_letter
     or new.skills is distinct from old.skills
     or new.applied_at is distinct from old.applied_at then
    raise exception 'The details of an application cannot be changed.';
  end if;

  if new.status is distinct from old.status then
    if v_role is distinct from 'company_hr' then
      raise exception 'Only the company''s HR can change the status of an application.';
    end if;
    if not (
      (old.status = 'pending'   and new.status in ('interview', 'offered', 'rejected'))
      or (old.status = 'interview' and new.status in ('offered', 'rejected'))
      or (old.status = 'offered'   and new.status = 'rejected')
    ) then
      raise exception 'An application cannot move from % to %.', old.status, new.status;
    end if;
    if new.status = 'rejected' and char_length(btrim(coalesce(new.rejection_reason, ''))) < 10 then
      raise exception 'Please give a reason of at least 10 characters when rejecting an application.';
    end if;
    if new.status <> 'rejected' then
      new.rejection_reason := null;
    end if;
  elsif new.rejection_reason is distinct from old.rejection_reason then
    raise exception 'The rejection reason cannot be changed after the application was rejected.';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

-- Close what is already past its dates (the guard above only checks open rows being written).
update public.job_postings set status = 'closed'
 where status = 'open' and public.posting_has_expired(application_deadline, posting_closes_at);

-- ---------------------------------------------------------------------------------------
-- 2. Reschedule requests
-- ---------------------------------------------------------------------------------------
create table if not exists public.interview_reschedule_requests (
  request_id uuid primary key default gen_random_uuid(),
  interview_id uuid not null references public.interviews(interview_id) on delete cascade,
  requested_by uuid not null references public.profiles(profile_id),
  requested_role text not null check (requested_role in ('student', 'company_hr')),
  proposed_interviewer_id uuid not null references public.profiles(profile_id),
  proposed_start timestamptz not null,
  proposed_end timestamptz not null,
  reason text not null check (char_length(btrim(reason)) between 10 and 500),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined', 'withdrawn', 'expired')),
  responded_by uuid references public.profiles(profile_id),
  response_note text check (response_note is null or char_length(response_note) <= 500),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint reschedule_request_end_after_start check (proposed_end > proposed_start)
);

create unique index if not exists one_pending_reschedule_per_interview
  on public.interview_reschedule_requests (interview_id) where status = 'pending';
create index if not exists idx_reschedule_requests_interview on public.interview_reschedule_requests (interview_id, created_at);

alter table public.interview_reschedule_requests enable row level security;
-- Whoever can see the interview can see its requests (the subquery runs under interviews' own RLS).
create policy reschedule_requests_select on public.interview_reschedule_requests
  for select to authenticated
  using (exists (select 1 from public.interviews i where i.interview_id = interview_reschedule_requests.interview_id));

alter table public.interview_changes drop constraint if exists interview_changes_action_check;
alter table public.interview_changes
  add constraint interview_changes_action_check
  check (action in ('booked', 'rescheduled', 'cancelled', 'auto_cancelled', 'reschedule_requested', 'reschedule_declined'));

alter table public.interview_changes drop constraint if exists interview_changes_reason_required;
alter table public.interview_changes
  add constraint interview_changes_reason_required
  check (action not in ('rescheduled', 'cancelled', 'reschedule_requested', 'reschedule_declined')
         or char_length(btrim(coalesce(reason, ''))) >= 10);

alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications
  add constraint notifications_type_check
  check (type = any (array['application', 'report', 'document', 'message', 'evaluation', 'parent_link', 'interview_request']));

-- Slot computation without an access check (only other SECURITY DEFINER functions call it).
-- A slot is also unavailable while another pending reschedule request holds it.
create or replace function public._interview_slots(p_interviewer uuid, p_from date, p_to date)
returns table (slot_start timestamptz, slot_end timestamptz, slot_minutes int)
language sql
stable
security definer
set search_path = public
as $$
  select s.start_at, s.start_at + make_interval(mins => s.mins), s.mins
    from (
      select ((p_from + k) + w.start_time + make_interval(mins => n * w.slot_minutes)) at time zone 'Asia/Kuala_Lumpur' as start_at,
             w.slot_minutes::int as mins
        from generate_series(0, p_to - p_from) as k
        join hr_availability w
          on w.hr_id = p_interviewer
         and w.weekday = extract(isodow from (p_from + k))::int
        cross join lateral generate_series(
               0, (extract(epoch from (w.end_time - w.start_time))::int / 60) / w.slot_minutes - 1) as n
       where not exists (select 1 from hr_unavailable_dates u
                          where u.hr_id = p_interviewer and u.blocked_on = p_from + k)
    ) s
   where s.start_at > now() + interval '1 hour'
     and not exists (
       select 1 from interviews i
        where i.interviewer_id = p_interviewer
          and i.status = 'scheduled'
          and tstzrange(i.scheduled_at, i.ends_at) && tstzrange(s.start_at, s.start_at + make_interval(mins => s.mins)))
     and not exists (
       select 1 from interview_reschedule_requests r
        where r.status = 'pending'
          and r.proposed_interviewer_id = p_interviewer
          and tstzrange(r.proposed_start, r.proposed_end) && tstzrange(s.start_at, s.start_at + make_interval(mins => s.mins)))
   order by s.start_at;
$$;

revoke all on function public._interview_slots(uuid, date, date) from public, anon, authenticated;

create or replace function public.interview_free_slots(p_interviewer uuid, p_from date, p_to date)
returns table (slot_start timestamptz, slot_end timestamptz, slot_minutes int)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null or not (select is_approved_user()) then
    raise exception 'You must be signed in.';
  end if;
  if p_to < p_from or p_to - p_from > 60 then
    raise exception 'Choose a date range of at most 60 days.';
  end if;

  if v_uid <> p_interviewer and not exists (
       select 1 from interviews i join applications a on a.application_id = i.application_id
        where i.interviewer_id = p_interviewer and a.student_id = v_uid) then
    raise exception 'You cannot view these interview slots.';
  end if;

  return query select * from _interview_slots(p_interviewer, p_from, p_to);
end;
$$;

-- The old direct reschedule is replaced by request + approval.
drop function if exists public.reschedule_interview(uuid, timestamptz, text, text, text);

-- Ask the other side to move an interview.
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
  insert into notifications (user_id, title, body, type, related_id)
  values (v_notify, 'Reschedule requested',
          case when v_by = 'student' then 'The student' else 'The company' end
            || ' asks to move the interview for ' || v_title || ' from ' || _interview_when(v_i.scheduled_at)
            || ' to ' || _interview_when(p_new_start) || '. Reason: ' || btrim(p_reason)
            || ' Open the interview to accept or decline; it stays as it is until you accept.',
          'interview_request', v_app.application_id);

  return v_id;
end;
$$;

-- Accept (the interview moves) or decline (with a reason; nothing changes).
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
begin
  select * into v_r from interview_reschedule_requests where request_id = p_request_id for update;
  if not found then raise exception 'That request was not found.'; end if;
  if v_r.status <> 'pending' then
    raise exception 'This request has already been answered or is no longer valid.';
  end if;

  select * into v_i from interviews where interview_id = v_r.interview_id for update;
  select * into v_app from applications where application_id = v_i.application_id;
  select jp.company_id, jp.title into v_company, v_title from job_postings jp where jp.job_posting_id = v_app.job_posting_id;

  -- Only the OTHER side may answer.
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
    insert into notifications (user_id, title, body, type, related_id)
    values (v_r.requested_by, 'Reschedule declined',
            case when v_r.requested_role = 'student' then 'The company' else 'The student' end
              || ' declined moving the interview for ' || v_title || '. It stays on ' || _interview_when(v_i.scheduled_at)
              || '. Reason: ' || btrim(p_note),
            'application', v_app.application_id);
    return;
  end if;

  -- Accept: the proposed slot must still be free (this request no longer holds it once answered).
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

  insert into notifications (user_id, title, body, type, related_id)
  values (v_r.requested_by, 'Reschedule accepted',
          case when v_r.requested_role = 'student' then 'The company' else 'The student' end
            || ' accepted. The interview for ' || v_title || ' is now on ' || _interview_when(v_r.proposed_start) || '.',
          'application', v_app.application_id);
end;
$$;

-- The requester takes their request back.
create or replace function public.withdraw_reschedule_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update interview_reschedule_requests
     set status = 'withdrawn', responded_by = auth.uid(), responded_at = now()
   where request_id = p_request_id and requested_by = auth.uid() and status = 'pending';
  if not found then
    raise exception 'There is no waiting request of yours to withdraw.';
  end if;
end;
$$;

-- When an interview stops being scheduled (cancelled, completed, rejected...), a request waiting
-- for an answer can no longer be answered.
create or replace function public.interviews_expire_requests()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status <> 'scheduled' then
    update interview_reschedule_requests set status = 'expired', responded_at = now()
     where interview_id = new.interview_id and status = 'pending';
  end if;
  return null;
end;
$$;

drop trigger if exists interviews_expire_requests on public.interviews;
create trigger interviews_expire_requests
  after update of status on public.interviews
  for each row execute function public.interviews_expire_requests();

revoke all on function public.request_reschedule(uuid, timestamptz, text) from public, anon;
revoke all on function public.respond_reschedule(uuid, boolean, text) from public, anon;
revoke all on function public.withdraw_reschedule_request(uuid) from public, anon;
grant execute on function public.request_reschedule(uuid, timestamptz, text) to authenticated;
grant execute on function public.respond_reschedule(uuid, boolean, text) to authenticated;
grant execute on function public.withdraw_reschedule_request(uuid) to authenticated;
