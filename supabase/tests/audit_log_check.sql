-- Checks for migration 00036 (audit log). Run in the SQL editor; the transaction ends in a
-- deliberate exception, so nothing is kept and the "error" shown is the report.
--
-- Expected:
--   intake logged: 1
--   company status change logged: 1
--   supervisor assignment logged: 1   (0 when the project has no approved academic supervisor)
--   non-admin can read the log (should be 0 rows): 0
--   admin can read the log (should be > 0): true
--   non-admin cannot write: permission denied (or 0 rows changed)

do $$
declare
  adm uuid; stu uuid; sup uuid; cid uuid; iid uuid;
  out text := ''; n int; ok boolean;
begin
  select profile_id into adm from profiles where role = 'admin' and approval_status = 'approved' limit 1;
  select profile_id into stu from profiles where role = 'student' limit 1;
  select profile_id into sup from profiles where role = 'academic_supervisor' and approval_status = 'approved' limit 1;
  select company_id into cid from companies limit 1;

  perform set_config('request.jwt.claims', json_build_object('sub', adm, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', adm::text, true);
  set local role authenticated;

  insert into intakes (name, start_date, end_date, created_by) values ('Audit check intake', current_date, current_date + 90, adm) returning intake_id into iid;
  update companies set status = case when status = 'verified' then 'pending' else 'verified' end where company_id = cid;
  if stu is not null and sup is not null then
    update students set academic_supervisor_id = sup where profile_id = stu;
  end if;
  reset role;

  select count(*) into n from audit_log where action = 'intake_created' and actor_id = adm and created_at > now() - interval '1 minute';
  out := out || 'intake logged: ' || n || E'\n';
  if n <> 1 then out := out || E'intake creation was not logged (BAD)\n'; end if;
  select count(*) into n from audit_log where action = 'company_status_changed' and actor_id = adm and created_at > now() - interval '1 minute';
  out := out || 'company status change logged: ' || n || E'\n';
  if n <> 1 then out := out || E'company status change was not logged (BAD)\n'; end if;
  select count(*) into n from audit_log where action = 'supervisor_assigned' and actor_id = adm and created_at > now() - interval '1 minute';
  out := out || 'supervisor assignment logged: ' || n || E'\n';

  -- a student cannot read it
  perform set_config('request.jwt.claims', json_build_object('sub', stu, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', stu::text, true);
  set local role authenticated;
  select count(*) into n from audit_log;
  out := out || 'non-admin can read the log (should be 0 rows): ' || n || E'\n';
  if n <> 0 then out := out || E'a non-admin could read the audit log (BAD)\n'; end if;
  begin
    delete from audit_log;
    get diagnostics n = row_count;
    out := out || 'non-admin delete changed rows (should be 0): ' || n || E'\n';
  exception when others then
    out := out || 'non-admin cannot write: ' || sqlerrm || E'\n';
  end;
  reset role;

  perform set_config('request.jwt.claims', json_build_object('sub', adm, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', adm::text, true);
  set local role authenticated;
  select count(*) > 0 into ok from audit_log;
  out := out || 'admin can read the log (should be true): ' || ok || E'\n';
  if not ok then out := out || E'the admin could not read the audit log (BAD)\n'; end if;
  reset role;

  raise exception E'RESULT (rolled back)\n%', out;
end $$;
