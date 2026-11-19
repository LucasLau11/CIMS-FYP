-- Checks for migration 00026 (rejection reason + one accepted offer).
--
-- Run in the Supabase SQL editor. Everything happens inside one transaction that ends in a
-- deliberate exception, so nothing is kept; the "error" shown is the report.
--
-- Fixtures: replace the three ids below with a real student, one of their applications that
-- is `active`, two more of their applications, and an approved company_hr of the same company.
-- (These are the ids of the test accounts in the development project.)
--
-- Expected output:
--   A: blocked: Only the company's HR can change the status of an application.
--   D: blocked: Only a pending application can be withdrawn.
--   B1/B2: Please give a reason of at least 10 characters when rejecting an application.
--   B3: reject with a proper reason OK
--   B4: An application cannot move from rejected to offered.
--   C2: This application does not have an offer you can accept.
--   C: the accepted application is active, every other open one is unavailable.

do $$
declare
  s   uuid := 'a22363d8-7012-4cea-9bec-6572ca128d4c';   -- student
  hr  uuid := 'ab1f0794-4120-4381-83d2-2656d0814d4c';   -- approved company_hr
  app_a uuid := '22c73462-c292-4e0d-94b6-54bd5fe0b272'; -- application to be accepted
  app_b uuid := '01d655f7-125d-40d3-9617-40aaf5e823a1'; -- currently the student's active one
  app_c uuid := 'd1b24838-9314-4ba8-9cf6-69a842000288'; -- a third application
  out text := '';
  n int;
  r record;
begin
  -- A / D: a student tries to promote or delete an application through the API.
  perform set_config('request.jwt.claims', json_build_object('sub', s, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', s::text, true);
  set local role authenticated;
  begin
    update applications set status = 'active' where application_id = app_a;
    out := out || E'A: student self-promote succeeded (BAD)\n';
  exception when others then out := out || 'A: blocked: ' || sqlerrm || E'\n'; end;
  begin
    delete from applications where application_id = app_b;
    out := out || E'D: student deleted an active application (BAD)\n';
  exception when others then out := out || 'D: blocked: ' || sqlerrm || E'\n'; end;
  reset role;

  -- B: HR must give a reason to reject; a rejected application cannot be revived.
  update applications set status = 'pending', rejection_reason = null where application_id = app_a;
  perform set_config('request.jwt.claims', json_build_object('sub', hr, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', hr::text, true);
  set local role authenticated;
  begin
    update applications set status = 'rejected' where application_id = app_a;
    out := out || E'B1: reject with no reason succeeded (BAD)\n';
  exception when others then out := out || 'B1: ' || sqlerrm || E'\n'; end;
  begin
    update applications set status = 'rejected', rejection_reason = 'too short' where application_id = app_a;
    out := out || E'B2: reject with a short reason succeeded (BAD)\n';
  exception when others then out := out || 'B2: ' || sqlerrm || E'\n'; end;
  begin
    update applications set status = 'rejected', rejection_reason = 'Skills do not match the role requirements.' where application_id = app_a;
    out := out || E'B3: reject with a proper reason OK\n';
  exception when others then out := out || 'B3 (BAD): ' || sqlerrm || E'\n'; end;
  begin
    update applications set status = 'offered' where application_id = app_a;
    out := out || E'B4: rejected -> offered succeeded (BAD)\n';
  exception when others then out := out || 'B4: ' || sqlerrm || E'\n'; end;
  reset role;

  -- C: two offers are held; accepting one closes the other.
  update applications set status = 'offered', rejection_reason = null where application_id = app_a;
  update applications set status = 'offered' where application_id = app_b;
  update applications set status = 'pending' where application_id = app_c;
  perform set_config('request.jwt.claims', json_build_object('sub', s, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', s::text, true);
  set local role authenticated;
  perform accept_offer(app_a);
  begin
    perform accept_offer(app_b);
    out := out || E'C2: a second accept succeeded (BAD)\n';
  exception when others then out := out || 'C2: ' || sqlerrm || E'\n'; end;
  reset role;
  for r in select application_id, status from applications where student_id = s order by application_id loop
    out := out || 'C: ' || left(r.application_id::text, 8) || ' -> ' || r.status || E'\n';
  end loop;
  select count(*) into n from notifications
   where created_at > now() - interval '1 minute' and user_id = hr and type = 'application';
  out := out || 'C: HR notifications created: ' || n || E'\n';

  raise exception E'RESULTS (rolled back)\n%', out;
end $$;
