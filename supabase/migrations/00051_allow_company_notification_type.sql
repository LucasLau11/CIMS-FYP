-- 00051: the administrator could not verify or reject a company.
--
-- admin_set_company_status (00044) tells the company's HR people about the decision with a notification of type
-- 'company', but notifications_type_check (last set in 00034) did not allow that type. The insert failed inside the
-- function, so the whole call rolled back: the status never changed and the administrator saw an error, every time.
-- 'company' is added to the allowed types. (Every other function that writes notifications already used an allowed type.)

alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array['application', 'report', 'document', 'message', 'evaluation', 'parent_link',
                           'interview_request', 'interview_reminder', 'company']));
