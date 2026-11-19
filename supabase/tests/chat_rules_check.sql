-- Checks for migration 00038 (who may start a conversation). Run in the SQL editor or with run_checks.sh;
-- everything is rolled back, the "error" shown is the report. Uses whichever approved accounts exist,
-- and skips a line when the project has no account of that role.
--
-- A "(BAD)" line means a rule was broken.

do $$
declare
  adm uuid; stu uuid; stu2 uuid; hr uuid; sup uuid;
  out text := ''; ok boolean; cid uuid;
begin
  select profile_id into adm  from profiles where role = 'admin' and approval_status = 'approved' limit 1;
  select profile_id into stu  from profiles where role = 'student' and approval_status = 'approved' and email not like '%@deleted.invalid' order by created_at limit 1;
  select profile_id into stu2 from profiles where role = 'student' and approval_status = 'approved' and email not like '%@deleted.invalid' and profile_id <> stu order by created_at limit 1;
  select profile_id into hr   from profiles where role = 'company_hr' and approval_status = 'approved' limit 1;
  select profile_id into sup  from profiles where role = 'academic_supervisor' and approval_status = 'approved' limit 1;

  -- student: may message HR, may not message another student
  if stu is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', stu, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', stu::text, true);
    set local role authenticated;
    if hr is not null then
      ok := can_message(hr);
      out := out || 'student -> HR (should be true): ' || ok || E'\n';
      if not ok then out := out || E'student could not message HR (BAD)\n'; end if;
    end if;
    if stu2 is not null then
      ok := can_message(stu2);
      out := out || 'student -> other student (should be false): ' || ok || E'\n';
      if ok then out := out || E'student could message another student (BAD)\n'; end if;
      begin
        perform start_conversation(stu2);
        out := out || E'student started a chat with another student (BAD)\n';
      exception when others then
        out := out || 'start_conversation refused: ' || sqlerrm || E'\n';
      end;
    end if;
    -- the tables cannot be written to directly any more
    begin
      insert into conversations default values;
      out := out || E'direct insert into conversations worked (BAD)\n';
    exception when others then
      out := out || 'direct insert into conversations refused: ' || sqlerrm || E'\n';
    end;
    reset role;
  end if;

  -- HR: may message a student, may not message an academic supervisor
  if hr is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', hr, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', hr::text, true);
    set local role authenticated;
    if stu is not null then
      ok := can_message(stu);
      out := out || 'HR -> student (should be true): ' || ok || E'\n';
      if not ok then out := out || E'HR could not message a student (BAD)\n'; end if;
      cid := start_conversation(stu);
      out := out || 'HR started a conversation: ' || (cid is not null) || E'\n';
      if cid is distinct from start_conversation(stu) then out := out || E'opening the same chat twice made two conversations (BAD)\n'; end if;
    end if;
    if sup is not null then
      ok := can_message(sup);
      out := out || 'HR -> academic supervisor (should be false): ' || ok || E'\n';
      if ok then out := out || E'HR could message an academic supervisor (BAD)\n'; end if;
    end if;
    reset role;
  end if;

  -- the student can answer in the conversation HR started even though students cannot start one with a student
  if stu is not null and hr is not null and cid is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', stu, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', stu::text, true);
    set local role authenticated;
    insert into messages (conversation_id, sender_id, body) values (cid, stu, 'Thank you, I will be there.');
    out := out || E'student replied in the conversation HR started\n';
    reset role;
  end if;

  -- admin: anyone
  if adm is not null and stu is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', adm, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', adm::text, true);
    set local role authenticated;
    ok := can_message(stu);
    out := out || 'admin -> student (should be true): ' || ok || E'\n';
    if not ok then out := out || E'admin could not message a student (BAD)\n'; end if;
    reset role;
  end if;

  raise exception E'RESULT (rolled back)\n%', out;
end $$;
