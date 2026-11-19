-- 00050: two things that stopped the company HR from filling and signing the company acceptance letter,
-- and the storage rule the administrator needs to delete a template.
--
-- 1. The filled letter is first stored in the private bucket document_submissions at
--       <HR id>/<student id>/<template id>.pdf
--    but the only insert rule there required BOTH folders to be the signed-in user's own id (that is how a student signs
--    their own letter), so for HR the upload was refused with "new row violates row-level security policy" and nothing
--    after it ran. HR may now write there for a student who has accepted an offer from HR's company, under HR's own folder.
--
-- 2. After the file is uploaded the app saves its path on the documents row (an UPDATE). HR could insert and delete
--    offer / acceptance letters but not update them, and an update that no policy allows does not fail: it changes
--    0 rows. The letter would have been saved with an empty path and nobody could open it. HR may now update the two
--    letter categories of a student who accepted its offer.
--
-- 3. The administrator can delete a template's PDF from the document_templates bucket (the row was already deletable).

create or replace function public.can_hr_write_submission_file(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_student uuid;
begin
  if (select current_user_role()) is distinct from 'company_hr' then
    return false;
  end if;
  if (storage.foldername(p_name))[1] is distinct from (select auth.uid())::text then
    return false;
  end if;
  begin
    v_student := (storage.foldername(p_name))[2]::uuid;
  exception when others then
    return false;
  end;
  return public.is_my_accepted_student(v_student);
end;
$$;

revoke all on function public.can_hr_write_submission_file(text) from public, anon;
grant execute on function public.can_hr_write_submission_file(text) to authenticated;

drop policy if exists document_submissions_insert_hr on storage.objects;
create policy document_submissions_insert_hr on storage.objects for insert to authenticated
  with check (bucket_id = 'document_submissions' and public.can_hr_write_submission_file(name));

drop policy if exists documents_update_hr_letters on public.documents;
create policy documents_update_hr_letters on public.documents for update to authenticated
  using (category = any (array['offer_letter', 'company_acceptance_letter'])
         and (select current_user_role()) = 'company_hr'
         and is_my_accepted_student(student_id))
  with check (category = any (array['offer_letter', 'company_acceptance_letter'])
         and (select current_user_role()) = 'company_hr'
         and is_my_accepted_student(student_id));

drop policy if exists document_templates_delete_admin_storage on storage.objects;
create policy document_templates_delete_admin_storage on storage.objects for delete to authenticated
  using (bucket_id = 'document_templates' and (select current_user_role()) = 'admin');
