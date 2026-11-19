-- rls_security_check.sql
--
-- Re-runnable check of the security rules added in migration 00023. Paste it
-- into the Supabase SQL editor (or run it with `supabase db query`).
--
-- It impersonates real accounts from YOUR database (picked by role), tries the
-- attacks the rules are meant to stop, and prints a PASS/FAIL line for each.
-- Everything runs inside one transaction that is ALWAYS rolled back by the
-- final RAISE EXCEPTION, so it changes nothing. The "error" you get back is
-- the report -- that is expected.
--
-- Needs at least: 1 admin, 1 academic_supervisor, 1 company_hr and
-- 2 students. Lines marked SKIP mean the data to test that rule is missing.

do $$
declare
  adm uuid; sup uuid; hr uuid; stu1 uuid; stu2 uuid;
  rpt text := E'\n';
  n int; v text;
begin
  select profile_id into adm  from profiles where role = 'admin' order by created_at limit 1;
  select profile_id into sup  from profiles where role = 'academic_supervisor' order by created_at limit 1;
  select profile_id into hr   from profiles where role = 'company_hr' order by created_at limit 1;
  select profile_id into stu1 from profiles where role = 'student' order by created_at limit 1;
  select profile_id into stu2 from profiles where role = 'student' order by created_at offset 1 limit 1;

  if adm is null or sup is null or hr is null or stu1 is null or stu2 is null then
    raise exception 'RLS-CHECK: need an admin, supervisor, HR and two students to run this check';
  end if;

  -- ---------------- as a student ----------------
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', stu1, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', stu1::text, true);
  set local role authenticated;

  select count(*) into n from students where profile_id <> stu1;
  rpt := rpt || case when n = 0 then 'PASS' else 'FAIL' end || '  student cannot read other students (saw ' || n || E')\n';

  begin
    update profiles set role = 'admin' where profile_id = stu1;
    rpt := rpt || E'FAIL  student changed own role\n';
  exception when others then
    rpt := rpt || E'PASS  student cannot change own role\n';
  end;

  begin
    update students set academic_supervisor_id = stu1 where profile_id = stu1;
    rpt := rpt || E'FAIL  student assigned own supervisor\n';
  exception when others then
    rpt := rpt || E'PASS  student cannot assign own supervisor\n';
  end;

  begin
    insert into profiles (profile_id, role, email) values (gen_random_uuid(), 'admin', 'x@x.invalid');
    rpt := rpt || E'FAIL  student inserted a profile\n';
  exception when others then
    rpt := rpt || E'PASS  student cannot insert a profile\n';
  end;

  begin
    update profiles set phone = phone where profile_id = stu1;
    get diagnostics n = row_count;
    rpt := rpt || case when n = 1 then 'PASS' else 'FAIL' end || E'  student can still edit own details\n';
  exception when others then
    rpt := rpt || E'FAIL  student cannot edit own details\n';
  end;

  -- ---------------- as an academic supervisor ----------------
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', sup, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', sup::text, true);
  set local role authenticated;
  begin
    update profiles set role = 'admin' where profile_id = sup;
    rpt := rpt || E'FAIL  supervisor changed own role\n';
  exception when others then
    rpt := rpt || E'PASS  supervisor cannot change own role\n';
  end;

  -- ---------------- approval gate ----------------
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', adm, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', adm::text, true);
  set local role authenticated;
  update profiles set approval_status = 'pending' where profile_id = hr;

  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', hr, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', hr::text, true);
  set local role authenticated;
  select count(*) into n from applications;
  select current_user_role() into v;
  rpt := rpt || case when n = 0 and v is null then 'PASS' else 'FAIL' end
       || E'  a pending HR account has no role and sees no applications\n';

  reset role;
  raise exception 'RLS-CHECK REPORT (nothing was changed): %', rpt;
end $$;
