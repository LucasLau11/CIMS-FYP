-- Checks for migration 00032: a reschedule only happens when the other side accepts.
--
-- Run in the Supabase SQL editor. Everything runs in one transaction that ends in a deliberate
-- exception, so nothing is kept; the "error" shown is the report. Replace the ids with your own
-- test student, an approved company_hr of the same company, and one of the student's applications.
--
-- Expected output (in this order):
--   after request, interview still at old time: true
--   HR got interview_request notification: 1
--   second request: A reschedule request for this interview is already waiting for an answer.
--   requester answers own: Only the other side of this interview can answer this request.
--   proposed slot still listed as free (should be 0): 0
--   decline short: Please give a reason of 10 to 500 characters for declining.
--   after decline, interview unchanged: true
--   HR accepts own: Only the other side of this interview can answer this request.
--   after student accepts, interview moved: true
--   history: booked / reschedule_requested / reschedule_declined / reschedule_requested / rescheduled

do $$
declare
  s    uuid := 'a22363d8-7012-4cea-9bec-6572ca128d4c';   -- student
  hr   uuid := 'ab1f0794-4120-4381-83d2-2656d0814d4c';   -- approved company_hr
  app1 uuid := 'd1b24838-9314-4ba8-9cf6-69a842000288';   -- the student's application
  out text := ''; n int; slotA timestamptz; slotB timestamptz; slotC timestamptz; iid uuid; rid uuid; r record;
begin
  -- weekly hours for the test (rolled back with everything else)
  delete from hr_availability where hr_id = hr;
  insert into hr_availability (hr_id, weekday, start_time, end_time, slot_minutes)
    select hr, d, time '09:00', time '17:00', 30 from generate_series(1,7) d;
  update applications set status = 'pending' where application_id = app1;

  perform set_config('request.jwt.claims', json_build_object('sub', hr, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', hr::text, true);
  set local role authenticated;
  select slot_start into slotA from interview_free_slots(hr, current_date + 3, current_date + 10) order by 1 offset 2 limit 1;
  select slot_start into slotB from interview_free_slots(hr, current_date + 3, current_date + 10) order by 1 offset 20 limit 1;
  select slot_start into slotC from interview_free_slots(hr, current_date + 3, current_date + 10) order by 1 offset 30 limit 1;
  iid := book_interview(app1, slotA, 'online', 'https://meet.example.com/a');
  reset role;

  -- the student asks to move it
  perform set_config('request.jwt.claims', json_build_object('sub', s, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', s::text, true);
  set local role authenticated;
  rid := request_reschedule(iid, slotB, 'I have an exam at the original time.');
  reset role;
  select (scheduled_at = slotA) as same into r from interviews where interview_id = iid;
  out := out || 'after request, interview still at old time: ' || r.same || E'\n';
  select count(*) into n from notifications where user_id = hr and type = 'interview_request' and created_at > now() - interval '1 minute';
  out := out || 'HR got interview_request notification: ' || n || E'\n';

  set local role authenticated;
  begin perform request_reschedule(iid, slotC, 'Second request while one is waiting.'); out := out || E'second request accepted (BAD)\n';
  exception when others then out := out || 'second request: ' || sqlerrm || E'\n'; end;
  begin perform respond_reschedule(rid, true); out := out || E'requester answered own request (BAD)\n';
  exception when others then out := out || 'requester answers own: ' || sqlerrm || E'\n'; end;
  select count(*) into n from interview_free_slots(hr, current_date + 3, current_date + 10) where slot_start = slotB;
  out := out || 'proposed slot still listed as free (should be 0): ' || n || E'\n';
  reset role;

  -- HR declines: a reason is required, and the interview stays put
  perform set_config('request.jwt.claims', json_build_object('sub', hr, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', hr::text, true);
  set local role authenticated;
  begin perform respond_reschedule(rid, false, 'no'); out := out || E'decline without reason OK (BAD)\n';
  exception when others then out := out || 'decline short: ' || sqlerrm || E'\n'; end;
  perform respond_reschedule(rid, false, 'That day we are fully booked, sorry.');
  reset role;
  select (scheduled_at = slotA) as same into r from interviews where interview_id = iid;
  out := out || 'after decline, interview unchanged: ' || r.same || E'\n';

  -- HR asks to move it; only the student can accept, and then it moves
  set local role authenticated;
  rid := request_reschedule(iid, slotC, 'The interviewer has a clash that day.');
  begin perform respond_reschedule(rid, true); out := out || E'requester HR accepted own request (BAD)\n';
  exception when others then out := out || 'HR accepts own: ' || sqlerrm || E'\n'; end;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', s, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', s::text, true);
  set local role authenticated;
  perform respond_reschedule(rid, true);
  reset role;
  select (scheduled_at = slotC) as moved into r from interviews where interview_id = iid;
  out := out || 'after student accepts, interview moved: ' || r.moved || E'\n';
  for r in select action, actor_role, left(coalesce(reason, ''), 40) rs from interview_changes where interview_id = iid order by created_at, action loop
    out := out || 'history: ' || r.action || ' by ' || coalesce(r.actor_role, '-') || ' | ' || r.rs || E'\n';
  end loop;

  raise exception E'RESULT (rolled back)\n%', out;
end $$;
