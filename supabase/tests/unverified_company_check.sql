-- Checks for migration 00040: a student cannot apply to a posting of a company that is not verified yet.
-- Everything is rolled back; the "error" shown is the report. A "(BAD)" line means a rule was broken.
--
-- Expected:
--   unverified company: This company has not been verified yet, so you cannot apply to its postings.
--   verified company: application accepted

do $$
declare stu uuid; jp uuid; cid uuid; out text := '';
begin
  select a.profile_id into stu from profiles a where a.role = 'student' and a.approval_status = 'approved' and a.email not like '%@deleted.invalid'
     and not exists (select 1 from applications x where x.student_id = a.profile_id and x.status = 'active') order by created_at limit 1;
  select job_posting_id, company_id into jp, cid from job_postings where status = 'open' and not posting_has_expired(application_deadline, posting_closes_at) limit 1;
  if stu is null or jp is null then raise exception E'RESULT (rolled back)\nno student or open posting to test with'; end if;
  delete from applications where student_id = stu and job_posting_id = jp;

  update companies set status = 'pending' where company_id = cid;
  perform set_config('request.jwt.claims', json_build_object('sub', stu, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', stu::text, true);
  set local role authenticated;
  begin
    insert into applications (student_id, job_posting_id, cover_letter, skills) values (stu, jp, 'Dear hiring manager, I would like to apply.', array['x']);
    out := out || E'applied to an unverified company (BAD)\n';
  exception when others then
    out := out || 'unverified company: ' || sqlerrm || E'\n';
  end;
  reset role;

  update companies set status = 'verified' where company_id = cid;
  set local role authenticated;
  begin
    insert into applications (student_id, job_posting_id, cover_letter, skills) values (stu, jp, 'Dear hiring manager, I would like to apply.', array['x']);
    out := out || E'verified company: application accepted\n';
  exception when others then
    out := out || 'verified company refused (BAD): ' || sqlerrm || E'\n';
  end;
  reset role;
  raise exception E'RESULT (rolled back)\n%', out;
end $$;
