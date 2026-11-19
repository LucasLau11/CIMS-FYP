-- 00027: interview availability, double-booking protection, cancel / reschedule with reasons.
--
-- Model
--   hr_availability       weekly windows an HR person is free (several per weekday, own slot length)
--   hr_unavailable_dates  whole days they are not available (leave, public holiday)
--   interviews            + interviewer, end time, status. One row per application; a cancelled
--                         interview is re-booked by updating that row.
--   interview_changes     history of every book / reschedule / cancel, with the mandatory reason
--
-- Free slots are never stored. interview_free_slots() computes them from the weekly windows,
-- minus blocked dates, minus slots that overlap a scheduled interview, minus the past, in
-- Malaysian time (Asia/Kuala_Lumpur). Double booking is prevented by an exclusion constraint on
-- interviews, so two people clicking the same slot at once cannot both succeed.
--
-- All writes to interviews go through book_interview / reschedule_interview / cancel_interview,
-- which check who may act, enforce the 2-hour cutoff and the reason, log the change and notify
-- the other side. The old client-side INSERT/UPDATE/DELETE policies on interviews are removed.

create extension if not exists btree_gist with schema extensions;

-- ---------------------------------------------------------------------------------------
-- 1. interviews: interviewer, end time, status
-- ---------------------------------------------------------------------------------------
alter table public.interviews
  add column if not exists interviewer_id uuid references public.profiles(profile_id),
  add column if not exists ends_at timestamptz,
  add column if not exists status text not null default 'scheduled';

-- Existing rows predate slots: 30-minute interviews run by the company's HR person.
update public.interviews i
   set ends_at = i.scheduled_at + interval '30 minutes',
       interviewer_id = (
         select min(h.profile_id::text)::uuid
           from public.applications a
           join public.job_postings jp on jp.job_posting_id = a.job_posting_id
           join public.company_hr h on h.company_id = jp.company_id
          where a.application_id = i.application_id),
       status = case
         when (select a.status from public.applications a where a.application_id = i.application_id) in ('rejected', 'unavailable') then 'cancelled'
         when i.scheduled_at < now() then 'completed'
         else 'scheduled'
       end
 where i.ends_at is null;

alter table public.interviews
  alter column scheduled_at set not null,
  alter column ends_at set not null,
  alter column interviewer_id set not null;

alter table public.interviews
  add constraint interviews_status_check check (status in ('scheduled', 'cancelled', 'completed')),
  add constraint interviews_end_after_start check (ends_at > scheduled_at),
  add constraint interviews_no_overlap
    exclude using gist (interviewer_id with =, tstzrange(scheduled_at, ends_at) with &&)
    where (status = 'scheduled');

create index if not exists idx_interviews_interviewer on public.interviews (interviewer_id, scheduled_at);

-- ---------------------------------------------------------------------------------------
-- 2. Availability
-- ---------------------------------------------------------------------------------------
create table if not exists public.hr_availability (
  availability_id uuid primary key default gen_random_uuid(),
  hr_id uuid not null references public.profiles(profile_id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),          -- 1 = Monday ... 7 = Sunday
  start_time time not null,
  end_time time not null,
  slot_minutes smallint not null default 30 check (slot_minutes in (15, 20, 30, 45, 60, 90, 120)),
  created_at timestamptz not null default now(),
  constraint hr_availability_window_order check (end_time > start_time),
  constraint hr_availability_fits_a_slot check (end_time - start_time >= make_interval(mins => slot_minutes)),
  constraint hr_availability_no_overlap
    exclude using gist (hr_id with =, weekday with =,
                        tsrange(timestamp '2000-01-01' + start_time, timestamp '2000-01-01' + end_time) with &&)
);

create table if not exists public.hr_unavailable_dates (
  hr_id uuid not null references public.profiles(profile_id) on delete cascade,
  blocked_on date not null,
  reason text check (reason is null or char_length(reason) <= 200),
  created_at timestamptz not null default now(),
  primary key (hr_id, blocked_on)
);

alter table public.hr_availability enable row level security;
alter table public.hr_unavailable_dates enable row level security;

create policy hr_availability_own on public.hr_availability
  for all to authenticated
  using (hr_id = (select auth.uid()) and (select current_user_role()) = 'company_hr')
  with check (hr_id = (select auth.uid()) and (select current_user_role()) = 'company_hr');

create policy hr_unavailable_dates_own on public.hr_unavailable_dates
  for all to authenticated
  using (hr_id = (select auth.uid()) and (select current_user_role()) = 'company_hr')
  with check (hr_id = (select auth.uid()) and (select current_user_role()) = 'company_hr');

-- ---------------------------------------------------------------------------------------
-- 3. History
-- ---------------------------------------------------------------------------------------
create table if not exists public.interview_changes (
  change_id uuid primary key default gen_random_uuid(),
  interview_id uuid not null references public.interviews(interview_id) on delete cascade,
  action text not null check (action in ('booked', 'rescheduled', 'cancelled', 'auto_cancelled')),
  actor_id uuid references public.profiles(profile_id),
  actor_role text,
  reason text check (reason is null or char_length(reason) <= 500),
  old_start timestamptz,
  new_start timestamptz,
  created_at timestamptz not null default now(),
  -- A person-made cancel or reschedule must always carry a real reason.
  constraint interview_changes_reason_required check (
    action not in ('rescheduled', 'cancelled') or char_length(btrim(coalesce(reason, ''))) >= 10)
);
create index if not exists idx_interview_changes_interview on public.interview_changes (interview_id, created_at);

alter table public.interview_changes enable row level security;
-- Whoever can see the interview can see its history (the subquery runs under interviews' own RLS).
create policy interview_changes_select on public.interview_changes
  for select to authenticated
  using (exists (select 1 from public.interviews i where i.interview_id = interview_changes.interview_id));

-- Writes only through the functions below.
drop policy if exists interviews_insert_company on public.interviews;
drop policy if exists interviews_update_company on public.interviews;
drop policy if exists interviews_delete_company on public.interviews;

-- ---------------------------------------------------------------------------------------
-- 4. Free slots
-- ---------------------------------------------------------------------------------------
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

  -- The interviewer themselves, or a student who has an interview with them.
  if v_uid <> p_interviewer and not exists (
       select 1 from interviews i join applications a on a.application_id = i.application_id
        where i.interviewer_id = p_interviewer and a.student_id = v_uid) then
    raise exception 'You cannot view these interview slots.';
  end if;

  return query
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
   order by s.start_at;
end;
$$;

-- ---------------------------------------------------------------------------------------
-- 5. Book / reschedule / cancel
-- ---------------------------------------------------------------------------------------
create or replace function public._interview_when(p_at timestamptz)
returns text language sql immutable as $$
  select to_char(p_at at time zone 'Asia/Kuala_Lumpur', 'Dy DD Mon YYYY, HH12:MI AM');
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

  insert into notifications (user_id, title, body, type, related_id)
  values (v_app.student_id, 'Interview scheduled',
          'You have an interview for ' || v_title || ' on ' || _interview_when(p_start) || '.',
          'application', p_application_id);

  return v_id;
end;
$$;

create or replace function public.reschedule_interview(
  p_interview_id uuid, p_new_start timestamptz, p_reason text,
  p_mode text default null, p_location text default null)
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
  v_interviewer uuid;
  v_end timestamptz;
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
  if p_mode is not null and p_mode not in ('online', 'in_person') then
    raise exception 'Choose online or in person.';
  end if;

  v_interviewer := case when v_by = 'company_hr' then v_uid else v_i.interviewer_id end;

  select f.slot_end into v_end
    from interview_free_slots(v_interviewer, (p_new_start at time zone 'Asia/Kuala_Lumpur')::date,
                              (p_new_start at time zone 'Asia/Kuala_Lumpur')::date) f
   where f.slot_start = p_new_start;
  if v_end is null then
    raise exception 'That time slot is not available. Please pick another.';
  end if;

  begin
    update interviews
       set scheduled_at = p_new_start, ends_at = v_end, interviewer_id = v_interviewer,
           mode = coalesce(p_mode, mode),
           location = coalesce(nullif(btrim(coalesce(p_location, '')), ''), location)
     where interview_id = p_interview_id;
  exception when exclusion_violation then
    raise exception 'That time slot was just taken. Please pick another.';
  end;

  insert into interview_changes (interview_id, action, actor_id, actor_role, reason, old_start, new_start)
  values (p_interview_id, 'rescheduled', v_uid, v_by, btrim(p_reason), v_i.scheduled_at, p_new_start);

  v_notify := case when v_by = 'student' then v_i.interviewer_id else v_app.student_id end;
  insert into notifications (user_id, title, body, type, related_id)
  values (v_notify, 'Interview rescheduled',
          case when v_by = 'student' then 'The student' else 'The company' end
            || ' moved the interview for ' || v_title || ' to ' || _interview_when(p_new_start)
            || '. Reason: ' || btrim(p_reason),
          'application', v_app.application_id);
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
  insert into notifications (user_id, title, body, type, related_id)
  values (v_notify, 'Interview cancelled',
          case when v_by = 'student' then 'The student' else 'The company' end
            || ' cancelled the interview for ' || v_title || ' on ' || _interview_when(v_i.scheduled_at)
            || '. Reason: ' || btrim(p_reason)
            || case when v_by = 'company_hr' then ' The company will arrange a new time.' else '' end,
          'application', v_app.application_id);
end;
$$;

-- ---------------------------------------------------------------------------------------
-- 6. Keep interviews consistent with the application's fate
-- ---------------------------------------------------------------------------------------
create or replace function public.applications_sync_interviews()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is not distinct from old.status then
    return null;
  end if;

  if new.status in ('rejected', 'unavailable') then
    with c as (
      update interviews set status = 'cancelled'
       where application_id = new.application_id and status = 'scheduled'
      returning interview_id, scheduled_at)
    insert into interview_changes (interview_id, action, actor_id, reason, old_start)
    select c.interview_id, 'auto_cancelled', auth.uid(),
           case when new.status = 'rejected' then 'The application was rejected.'
                else 'The student accepted another offer.' end,
           c.scheduled_at
      from c;
  elsif new.status in ('offered', 'active') then
    update interviews set status = 'completed'
     where application_id = new.application_id and status = 'scheduled';
  end if;
  return null;
end;
$$;

drop trigger if exists applications_sync_interviews on public.applications;
create trigger applications_sync_interviews
  after update of status on public.applications
  for each row execute function public.applications_sync_interviews();

-- ---------------------------------------------------------------------------------------
-- 7. Grants
-- ---------------------------------------------------------------------------------------
revoke all on function public.interview_free_slots(uuid, date, date) from public, anon;
revoke all on function public.book_interview(uuid, timestamptz, text, text) from public, anon;
revoke all on function public.reschedule_interview(uuid, timestamptz, text, text, text) from public, anon;
revoke all on function public.cancel_interview(uuid, text) from public, anon;
revoke all on function public._interview_when(timestamptz) from public, anon;
grant execute on function public.interview_free_slots(uuid, date, date) to authenticated;
grant execute on function public.book_interview(uuid, timestamptz, text, text) to authenticated;
grant execute on function public.reschedule_interview(uuid, timestamptz, text, text, text) to authenticated;
grant execute on function public.cancel_interview(uuid, text) to authenticated;
grant execute on function public._interview_when(timestamptz) to authenticated;
