-- Task 10: Storage buckets + RLS
--
-- Bucket path conventions confirmed against the real Dart code (post-merge
-- of master's "Finalise v1" commit):
--   avatars (public): flat, {userId}.{ext} -- no folder. auth_service.dart:229.
--   resumes (private): {userId}/resume.{ext}. auth_service.dart:295.
--   student_files (private): {userId}/reports/{reportId}.{ext} and
--     {userId}/documents/{documentId}.{ext} -- same bucket, a path segment
--     distinguishes the two. student_data_service.dart:184,254.
--   chat_attachments (private): {conversationId}/{timestamp}_{userIdPrefix}.{ext}
--     -- folder is the conversation, not the uploader. student_data_service.dart:526-527.
--   document_templates (private): flat templates/{templateId}.pdf -- no user
--     scoping, admin-authored shared resource. document_template_service.dart:51.
--   document_submissions (private): {submittedBy}/{studentId}/{templateId}.pdf.
--     document_template_service.dart:102.
--
-- Resume visibility is a real, non-obvious business rule (see
-- HrDataService.getCandidateResume comment, hr_data_service.dart:206-210):
-- HR can view a candidate's resume before that candidate ever applies, as
-- long as the candidate's skills overlap a required_skills array on an open
-- posting at HR's own company. This is skills-match-based, not
-- applicant-relationship-based.

create or replace function can_view_resume(p_student_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select
    p_student_id = (select auth.uid())
    or (select current_user_role()) = 'admin'
    or is_academic_supervisor_of(p_student_id)
    or exists (
      select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
      where a.student_id = p_student_id and is_my_company(jp.company_id)
    )
    or exists (
      select 1 from students s join job_postings jp on jp.required_skills && s.skills
      where s.profile_id = p_student_id and jp.status = 'open' and is_my_company(jp.company_id)
    );
$$;

revoke execute on function can_view_resume(uuid) from public, anon;
grant execute on function can_view_resume(uuid) to authenticated;

-- Mirrors the reports/documents visibility boundary already built in Tasks 4-5:
-- company staff can see report files (they review reports), but never document
-- files (document review is academic-supervisor + admin only, same as the
-- document_reviews table RLS).
create or replace function can_access_student_file(p_student_id uuid, p_category text) returns boolean
language sql stable security definer set search_path = public as $$
  select
    p_student_id = (select auth.uid())
    or (select current_user_role()) = 'admin'
    or is_academic_supervisor_of(p_student_id)
    or (p_category = 'reports' and exists (
      select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
      where a.student_id = p_student_id and is_my_company(jp.company_id)
    ));
$$;

revoke execute on function can_access_student_file(uuid, text) from public, anon;
grant execute on function can_access_student_file(uuid, text) to authenticated;

insert into storage.buckets (id, name, public) values
  ('avatars', 'avatars', true),
  ('resumes', 'resumes', false),
  ('student_files', 'student_files', false),
  ('chat_attachments', 'chat_attachments', false),
  ('document_templates', 'document_templates', false),
  ('document_submissions', 'document_submissions', false)
on conflict (id) do nothing;

-- avatars: public bucket, SELECT true is the documented/expected exception
-- (get_advisors explicitly excludes SELECT-true from the always-true lint).
create policy avatars_select_public on storage.objects for select
  using (bucket_id = 'avatars');
create policy avatars_write_own on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and split_part(name, '.', 1) = (select auth.uid())::text);
create policy avatars_update_own on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and split_part(name, '.', 1) = (select auth.uid())::text);
create policy avatars_delete_own on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and split_part(name, '.', 1) = (select auth.uid())::text);

create policy resumes_select_authorized on storage.objects for select to authenticated
  using (bucket_id = 'resumes' and can_view_resume(((storage.foldername(name))[1])::uuid));
create policy resumes_write_own on storage.objects for insert to authenticated
  with check (bucket_id = 'resumes' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy resumes_update_own on storage.objects for update to authenticated
  using (bucket_id = 'resumes' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy resumes_delete_own on storage.objects for delete to authenticated
  using (bucket_id = 'resumes' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy student_files_select_authorized on storage.objects for select to authenticated
  using (bucket_id = 'student_files'
         and can_access_student_file(((storage.foldername(name))[1])::uuid, (storage.foldername(name))[2]));
create policy student_files_write_own on storage.objects for insert to authenticated
  with check (bucket_id = 'student_files' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy student_files_delete_own on storage.objects for delete to authenticated
  using (bucket_id = 'student_files' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy chat_attachments_select_member on storage.objects for select to authenticated
  using (bucket_id = 'chat_attachments' and is_conversation_member(((storage.foldername(name))[1])::uuid));
create policy chat_attachments_insert_member on storage.objects for insert to authenticated
  with check (bucket_id = 'chat_attachments' and is_conversation_member(((storage.foldername(name))[1])::uuid));
create policy chat_attachments_delete_member on storage.objects for delete to authenticated
  using (bucket_id = 'chat_attachments' and is_conversation_member(((storage.foldername(name))[1])::uuid));

create policy document_templates_select_authenticated on storage.objects for select to authenticated
  using (bucket_id = 'document_templates');
create policy document_templates_write_admin on storage.objects for insert to authenticated
  with check (bucket_id = 'document_templates' and (select current_user_role()) = 'admin');
create policy document_templates_update_admin on storage.objects for update to authenticated
  using (bucket_id = 'document_templates' and (select current_user_role()) = 'admin');

-- Mirrors the document_submissions table's own RLS from Task 8 exactly
-- (submitter, student, admin, approved parent -- no company/HR access,
-- matching the "parent consent" nature of this feature).
create policy document_submissions_select_involved on storage.objects for select to authenticated
  using (bucket_id = 'document_submissions'
         and (
           (storage.foldername(name))[1] = (select auth.uid())::text
           or (storage.foldername(name))[2] = (select auth.uid())::text
           or (select current_user_role()) = 'admin'
           or is_approved_parent_of(((storage.foldername(name))[2])::uuid)
         ));
create policy document_submissions_insert_own on storage.objects for insert to authenticated
  with check (bucket_id = 'document_submissions'
              and (storage.foldername(name))[1] = (select auth.uid())::text
              and ((storage.foldername(name))[2] = (select auth.uid())::text
                   or is_approved_parent_of(((storage.foldername(name))[2])::uuid)));
