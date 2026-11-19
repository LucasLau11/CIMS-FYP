-- 00028: stop depending on the parent role (step 1 of removing it; non-destructive).
--
-- The parent account is being removed: the Parent Acknowledgement form is now filled in by the
-- student on their own phone (the parent signs there), so nothing needs a parent to log in.
-- This step rewrites every function and policy that mentions parents so they no longer do,
-- and stops new parent sign-ups. It deletes nothing. Step 2 (00029) drops the parent data and
-- tables and is applied separately, after the account owner confirms.

-- 1. Notifications: no more parent-link notifications are created.
create or replace function public.can_notify(p_user_id uuid, p_type text)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    p_user_id = (select auth.uid())
    or (select current_user_role()) = 'admin'
    or case p_type
      when 'application' then
        exists (select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
                 where a.student_id = p_user_id and is_my_company(jp.company_id))
      when 'report' then
        is_academic_supervisor_of(p_user_id)
        or exists (select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
                    where a.student_id = p_user_id and is_my_company(jp.company_id))
      when 'document' then
        is_academic_supervisor_of(p_user_id)
      when 'evaluation' then
        is_academic_supervisor_of(p_user_id)
        or exists (select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
                    where a.student_id = p_user_id and is_my_company(jp.company_id))
      when 'message' then
        exists (
          select 1 from profile_conversations pc1
          join profile_conversations pc2 using (conversation_id)
          where pc1.profile_id = (select auth.uid()) and pc2.profile_id = p_user_id
        )
      else false
    end;
$function$;

-- 2. Who can see whose profile.
create or replace function public.can_view_profile(p_target uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    p_target = (select auth.uid())
    or (select current_user_role()) = 'admin'
    or exists (select 1 from profiles t where t.profile_id = p_target
               and t.role in ('academic_supervisor', 'company_hr', 'company_supervisor', 'admin'))
    or is_academic_supervisor_of(p_target)
    or exists (select 1 from profile_conversations a
               join profile_conversations b using (conversation_id)
               where a.profile_id = (select auth.uid()) and b.profile_id = p_target)
    or exists (select 1 from applications a
               join job_postings jp on jp.job_posting_id = a.job_posting_id
               where a.student_id = p_target and is_my_company(jp.company_id));
$function$;

-- 3. Sign-up no longer creates parent accounts.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_role text := new.raw_user_meta_data->>'app_role';
  v_name text := left(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 100);
begin
  if v_role is null or v_role not in
     ('student', 'academic_supervisor', 'company_hr', 'company_supervisor') then
    return new;
  end if;

  insert into profiles (profile_id, role, email, full_name, approval_status)
  values (
    new.id, v_role, new.email, v_name,
    case when v_role in ('academic_supervisor', 'company_hr', 'company_supervisor')
         then 'pending' else 'approved' end)
  on conflict (profile_id) do nothing;

  case v_role
    when 'student' then insert into students (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'academic_supervisor' then insert into academic_supervisors (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'company_hr' then insert into company_hr (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'company_supervisor' then insert into company_supervisors (profile_id) values (new.id) on conflict (profile_id) do nothing;
  end case;

  return new;
end;
$function$;

-- 4. Row policies: the people who can read a student's records no longer include parents.
alter policy applications_select_involved on public.applications
  using (
    (student_id = (select auth.uid()))
    or ((select current_user_role()) = 'admin')
    or exists (select 1 from job_postings jp
                where jp.job_posting_id = applications.job_posting_id and is_my_company(jp.company_id))
    or is_academic_supervisor_of(student_id)
  );

alter policy reports_select_involved on public.reports
  using (
    (student_id = (select auth.uid()))
    or ((select current_user_role()) = 'admin')
    or is_academic_supervisor_of(student_id)
    or exists (select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
                where a.student_id = reports.student_id and is_my_company(jp.company_id))
  );

alter policy documents_select_involved on public.documents
  using (
    (student_id = (select auth.uid()))
    or ((select current_user_role()) = 'admin')
    or is_academic_supervisor_of(student_id)
  );

alter policy evaluations_select_involved on public.evaluations
  using (
    (student_id = (select auth.uid()))
    or (supervisor_id = (select auth.uid()))
    or ((select current_user_role()) = 'admin')
  );

-- 5. Acknowledgement-form submissions: the student submits their own (the parent signs on the
--    student's phone), so only the student, an admin, or the student's own row applies.
alter policy document_submissions_select_involved on public.document_submissions
  using (
    (submitted_by = (select auth.uid()))
    or (student_id = (select auth.uid()))
    or ((select current_user_role()) = 'admin')
  );

alter policy document_submissions_insert_own on public.document_submissions
  with check (
    (submitted_by = (select auth.uid())) and (student_id = (select auth.uid()))
  );

alter policy document_submissions_select_involved on storage.objects
  using (
    (bucket_id = 'document_submissions')
    and (
      ((storage.foldername(name))[1] = (select auth.uid())::text)
      or ((storage.foldername(name))[2] = (select auth.uid())::text)
      or ((select current_user_role()) = 'admin')
    )
  );

alter policy document_submissions_insert_own on storage.objects
  with check (
    (bucket_id = 'document_submissions')
    and ((storage.foldername(name))[1] = (select auth.uid())::text)
    and ((storage.foldername(name))[2] = (select auth.uid())::text)
  );

-- 6. The parent-only lookup is no longer needed.
drop function if exists public.find_student_for_link(text);
