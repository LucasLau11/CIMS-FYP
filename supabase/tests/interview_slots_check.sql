-- Checks for migration 00027 (interview slots, double booking, cancel / reschedule).
--
-- Run in the Supabase SQL editor. Everything happens inside one transaction that ends in a
-- deliberate exception, so nothing is kept; the "error" shown is the report.
--
-- Fixtures: a student, an approved company_hr of the company, two of that student's applications
-- for that company's postings, and weekly availability for the HR (Mon-Fri 09:00-12:00 and
-- 14:00-17:00, 30 minutes). Replace the ids with your own test accounts.
--
-- Expected: double booking, off-grid time, a stranger's slots, a direct insert by
-- a student, and a cancel inside the 2-hour cutoff are all refused; a student cancel with a reason works (rescheduling is checked in reschedule_approval_check.sql) and both are in interview_changes; HR can re-book after a cancel; rejecting
-- the application cancels its scheduled interview; a direct overlapping insert is rejected by the
-- exclusion constraint.

do $$
declare
  s    uuid := 'a22363d8-7012-4cea-9bec-6572ca128d4c';   -- student
  hr   uuid := 'ab1f0794-4120-4381-83d2-2656d0814d4c';   -- approved company_hr
  app1 uuid := 'd1b24838-9314-4ba8-9cf6-69a842000288';   -- student's application #1
  app2 uuid := '22c73462-c292-4e0d-94b6-54bd5fe0b272';   -- student's application #2
  out text := '';
  n int; slot1 timestamptz; slot2 timestamptz; iid uuid; r record; v_status text;
begin
  perform set_config('request.jwt.claims', json_build_object('sub', hr, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', hr::text, true);
  set local role authenticated;
  select count(*) into n from interview_free_slots(hr, current_date, current_date + 6);
  out := out || 'free slots in next 7 days: ' || n || E'\n';
  select slot_start into slot1 from interview_free_slots(hr, current_date, current_date + 14) order by 1 offset 3 limit 1;
  select slot_start into slot2 from interview_free_slots(hr, current_date, current_date + 14) order by 1 offset 6 limit 1;
  reset role;

  update applications set status = 'pending' where application_id in (app1, app2);

  perform set_config('request.jwt.claims', json_build_object('sub', hr, 'role', 'authenticated')::text, true);
  set local role authenticated;
  iid := book_interview(app1, slot1, 'online', 'https://meet.example.com/a');
  out := out || E'book app1: OK\n';
  begin
    perform book_interview(app2, slot1, 'online', 'https://meet.example.com/b');
    out := out || E'DOUBLE BOOKING SUCCEEDED (BAD)\n';
  exception when others then out := out || 'double booking: ' || sqlerrm || E'\n'; end;
  select count(*) into n from interview_free_slots(hr, current_date, current_date + 14) where slot_start = slot1;
  out := out || 'booked slot still listed as free: ' || n || E'\n';
  begin
    perform book_interview(app2, slot1 - interval '5 minutes', 'online', 'x');
    out := out || E'off-grid time accepted (BAD)\n';
  exception when others then out := out || 'off-grid time: ' || sqlerrm || E'\n'; end;
  reset role;

  -- the database itself refuses overlapping scheduled interviews for one interviewer
  begin
    insert into interviews (application_id, scheduled_at, ends_at, mode, location, interviewer_id, status)
    values (app2, slot1 + interval '10 minutes', slot1 + interval '40 minutes', 'online', 'x', hr, 'scheduled')
    on conflict (application_id) do update
      set scheduled_at = excluded.scheduled_at, ends_at = excluded.ends_at, status = 'scheduled', interviewer_id = excluded.interviewer_id;
    out := out || E'overlapping direct insert accepted (BAD)\n';
  exception when exclusion_violation then out := out || E'overlap: refused by exclusion constraint\n'; end;

  perform set_config('request.jwt.claims', json_build_object('sub', s, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', s::text, true);
  set local role authenticated;
  begin
    perform interview_free_slots('00000000-0000-0000-0000-000000000001', current_date, current_date + 1);
    out := out || E'student read a stranger''s slots (BAD)\n';
  exception when others then out := out || 'stranger slots: ' || sqlerrm || E'\n'; end;
  begin
    insert into interviews(application_id, scheduled_at, ends_at, mode, location, interviewer_id)
    values (app2, now() + interval '3 days', now() + interval '3 days 30 min', 'online', 'x', hr);
    out := out || E'student direct insert OK (BAD)\n';
  exception when others then out := out || 'direct insert: ' || sqlerrm || E'\n'; end;
  perform cancel_interview(iid, 'I accepted another position elsewhere.');
  out := out || E'student cancel with reason: OK\n';
  reset role;

  select count(*) into n from notifications
   where user_id = hr and title in ('Interview rescheduled', 'Interview cancelled') and created_at > now() - interval '1 minute';
  out := out || 'HR notified of change/cancel: ' || n || E'\n';
  for r in select action, actor_role, reason from interview_changes where interview_id = iid order by created_at loop
    out := out || 'history: ' || r.action || ' by ' || coalesce(r.actor_role, '-') || ' | ' || coalesce(r.reason, '') || E'\n';
  end loop;

  perform set_config('request.jwt.claims', json_build_object('sub', hr, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', hr::text, true);
  set local role authenticated;
  perform book_interview(app1, slot1, 'in_person', 'KL Sentral');
  out := out || E'HR re-book after cancel: OK\n';
  reset role;
  update interviews set scheduled_at = now() + interval '1 hour', ends_at = now() + interval '90 minutes' where application_id = app1;
  set local role authenticated;
  begin
    perform cancel_interview(iid, 'Need to cancel at the last minute.');
    out := out || E'cancel within 2h OK (BAD)\n';
  exception when others then out := out || 'cutoff: ' || sqlerrm || E'\n'; end;
  reset role;

  update interviews set scheduled_at = slot1, ends_at = slot1 + interval '30 minutes' where application_id = app1;
  update applications set status = 'rejected', rejection_reason = 'Position was filled by someone else.' where application_id = app1;
  select status into v_status from interviews where application_id = app1;
  out := out || 'interview status after application rejected: ' || v_status || E'\n';

  raise exception E'RESULTS (rolled back)\n%', out;
end $$;
