-- 00034: interview reminders and automatic completion.
--
-- run_interview_maintenance() is meant to be called every few minutes by a scheduler (pg_cron,
-- see 00035) and is safe to call any number of times:
--   * 24 hours before a scheduled interview, and again 1 hour before, both sides get an
--     in-app notification (the push function turns it into a phone alert if their
--     "application updates" switch is on);
--   * a reminder is remembered per interview AND start time, so an interview that is moved
--     gets fresh reminders for its new time;
--   * interviews whose end time has passed are marked completed.

-- The notification type for reminders.
alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array['application','report','document','message','evaluation','parent_link','interview_request','interview_reminder']));

create table if not exists public.interview_reminders (
  interview_id uuid not null references public.interviews(interview_id) on delete cascade,
  kind         text not null check (kind in ('24h', '1h')),
  for_start    timestamptz not null,
  sent_at      timestamptz not null default now(),
  primary key (interview_id, kind, for_start)
);

alter table public.interview_reminders enable row level security;
-- No policies on purpose: only the SECURITY DEFINER function below touches this table.

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
  v_reminders int := 0;
  v_completed int := 0;
begin
  -- Reminders: 24h window opens a day ahead; the 1h window an hour ahead.
  for r in
    select i.interview_id, i.application_id, i.interviewer_id, i.scheduled_at,
           case when i.scheduled_at - now() <= interval '1 hour' then '1h' else '24h' end as kind
      from interviews i
     where i.status = 'scheduled'
       and i.scheduled_at > now()
       and i.scheduled_at - now() <= interval '24 hours'
  loop
    v_kind := r.kind;
    -- An interview that is inside the 1-hour window and was already reminded at 24h still
    -- needs its 1h reminder, so the check is per kind.
    begin
      insert into interview_reminders (interview_id, kind, for_start) values (r.interview_id, v_kind, r.scheduled_at);
    exception when unique_violation then
      continue;
    end;

    select jp.title, a.student_id into v_title, v_student
      from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
     where a.application_id = r.application_id;

    v_text := case v_kind when '1h' then 'starts in about an hour' else 'is coming up in the next 24 hours' end;

    insert into notifications (user_id, title, body, type, related_id)
    values (v_student,
            case v_kind when '1h' then 'Interview in 1 hour' else 'Interview tomorrow' end,
            'Your interview for ' || v_title || ' ' || v_text || ': ' || _interview_when(r.scheduled_at) || '.',
            'interview_reminder', r.application_id);
    if r.interviewer_id is not null then
      insert into notifications (user_id, title, body, type, related_id)
      values (r.interviewer_id,
              case v_kind when '1h' then 'Interview in 1 hour' else 'Interview tomorrow' end,
              'Your interview for ' || v_title || ' ' || v_text || ': ' || _interview_when(r.scheduled_at) || '.',
              'interview_reminder', r.application_id);
    end if;
    v_reminders := v_reminders + 1;
  end loop;

  -- Completion
  update interviews set status = 'completed' where status = 'scheduled' and ends_at < now();
  get diagnostics v_completed = row_count;

  return jsonb_build_object('reminders', v_reminders, 'completed', v_completed);
end;
$$;

-- Never callable from the app: only the scheduler (service role / postgres) runs it.
revoke all on function public.run_interview_maintenance() from public, anon, authenticated;
