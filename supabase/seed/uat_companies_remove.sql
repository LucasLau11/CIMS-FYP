-- Removes everything supabase/seed/uat_companies.sql created: the 12 companies, their postings, and the
-- 24 HR / company-supervisor accounts (emails hr@<slug>.com.my and supervisor@<slug>.com.my).
-- Applications and interviews made against those postings are removed too. Run it only on a test project.

do $$
declare
  ids uuid[];
  cos uuid[];
begin
  select array_agg(company_id) into cos from companies where hr_contact_email ~ '^hr@[a-z]+\.com\.my$';
  select array_agg(id) into ids from auth.users where email ~ '^(hr|supervisor)@[a-z]+\.com\.my$';

  delete from interviews where application_id in (
    select a.application_id from applications a join job_postings jp using (job_posting_id) where jp.company_id = any(cos));
  delete from applications where job_posting_id in (select job_posting_id from job_postings where company_id = any(cos));
  delete from job_postings where company_id = any(cos);
  delete from company_hr where company_id = any(cos);
  delete from company_supervisors where company_id = any(cos);
  delete from companies where company_id = any(cos);
  delete from auth.identities where user_id = any(ids);
  delete from auth.users where id = any(ids);
end $$;
