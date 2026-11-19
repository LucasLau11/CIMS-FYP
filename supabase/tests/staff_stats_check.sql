-- Checks for migration 00039: every statistics function answers its own role and refuses the others.
-- Everything is rolled back; the "error" shown is the report. A "(BAD)" line means a rule was broken.
-- A line is skipped when the project has no approved account of that role.

do $$
declare adm uuid; hr uuid; sup uuid; csup uuid; stu uuid; out text := ''; r jsonb;
begin
  select profile_id into adm  from profiles where role = 'admin' and approval_status = 'approved' limit 1;
  select profile_id into hr   from profiles where role = 'company_hr' and approval_status = 'approved' limit 1;
  select profile_id into sup  from profiles where role = 'academic_supervisor' and approval_status = 'approved' limit 1;
  select profile_id into csup from profiles where role = 'company_supervisor' and approval_status = 'approved' limit 1;
  select profile_id into stu  from profiles where role = 'student' limit 1;

  if adm is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', adm, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', adm::text, true);
    set local role authenticated;
    r := admin_platform_stats();
    out := out || 'admin sees companies_total=' || (r->>'companies_total') || E'\n';
    begin perform hr_stats(); out := out || E'admin opened the HR statistics (BAD)\n'; exception when others then out := out || E'admin -> HR statistics refused\n'; end;
    reset role;
  end if;

  if hr is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', hr, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', hr::text, true);
    set local role authenticated;
    r := hr_stats();
    out := out || 'HR sees applications_total=' || coalesce(r->>'applications_total', 'none') || E'\n';
    begin perform admin_platform_stats(); out := out || E'HR opened the admin statistics (BAD)\n'; exception when others then out := out || E'HR -> admin statistics refused\n'; end;
    begin perform academic_supervisor_stats(); out := out || E'HR opened the supervisor statistics (BAD)\n'; exception when others then out := out || E'HR -> supervisor statistics refused\n'; end;
    reset role;
  end if;

  if sup is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', sup, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', sup::text, true);
    set local role authenticated;
    r := academic_supervisor_stats();
    out := out || 'academic supervisor sees students_total=' || (r->>'students_total') || E'\n';
    reset role;
  end if;

  if csup is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', csup, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', csup::text, true);
    set local role authenticated;
    r := company_supervisor_stats();
    out := out || 'company supervisor sees students_total=' || coalesce(r->>'students_total', 'none') || E'\n';
    reset role;
  end if;

  if stu is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', stu, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', stu::text, true);
    set local role authenticated;
    begin perform hr_stats(); out := out || E'student opened the HR statistics (BAD)\n'; exception when others then out := out || E'student -> HR statistics refused\n'; end;
    begin perform admin_platform_stats(); out := out || E'student opened the admin statistics (BAD)\n'; exception when others then out := out || E'student -> admin statistics refused\n'; end;
    reset role;
  end if;

  raise exception E'RESULT (rolled back)\n%', out;
end $$;
