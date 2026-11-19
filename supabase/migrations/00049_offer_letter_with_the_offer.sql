-- 00049: the offer letter is attached when HR MAKES the offer (it used to be uploadable only after the student accepted).
--
--   * the letter belongs to the APPLICATION (several companies can offer the same student at once, so a single
--     per-student document would be overwritten): applications.offer_letter_path / _name / _size / _uploaded_at.
--     Stored in the private bucket student_files at  <student id>/offers/<application id>/<timestamp>.<ext>
--   * an application cannot move to 'offered' without a letter (applications_guard); offers made before this
--     migration are left as they are.
--   * only the company's HR can attach or replace it, and only before the student accepts.
--   * the student (own folder), admin and academic supervisor can already read the folder (can_access_student_file);
--     the company's staff get a read policy for offers of their own company.
--   * when the student accepts, the letter is copied into documents (category 'offer_letter') so everything that
--     already reads that document (company supervisor, admin, academic supervisor, HR) keeps working.

alter table public.applications add column if not exists offer_letter_path text;
alter table public.applications add column if not exists offer_letter_name text;
alter table public.applications add column if not exists offer_letter_size bigint;
alter table public.applications add column if not exists offer_letter_uploaded_at timestamptz;

-- ---------------------------------------------------------------- storage helpers
create or replace function public.can_write_offer_file(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_student uuid;
  v_app uuid;
begin
  if (select current_user_role()) is distinct from 'company_hr' then
    return false;
  end if;
  begin
    v_student := (storage.foldername(p_name))[1]::uuid;
    v_app := (storage.foldername(p_name))[3]::uuid;
  exception when others then
    return false;
  end;
  return exists (
    select 1
      from applications a
      join job_postings jp on jp.job_posting_id = a.job_posting_id
     where a.application_id = v_app
       and a.student_id = v_student
       and is_my_company(jp.company_id)
       and a.status in ('pending', 'interview', 'offered'));
end;
$$;

create or replace function public.can_read_offer_file(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_student uuid;
  v_app uuid;
begin
  begin
    v_student := (storage.foldername(p_name))[1]::uuid;
    v_app := (storage.foldername(p_name))[3]::uuid;
  exception when others then
    return false;
  end;
  return exists (
    select 1
      from applications a
      join job_postings jp on jp.job_posting_id = a.job_posting_id
     where a.application_id = v_app
       and a.student_id = v_student
       and is_my_company(jp.company_id));
end;
$$;

revoke all on function public.can_write_offer_file(text) from public, anon;
revoke all on function public.can_read_offer_file(text) from public, anon;
grant execute on function public.can_write_offer_file(text) to authenticated;
grant execute on function public.can_read_offer_file(text) to authenticated;

drop policy if exists student_files_insert_hr_offers on storage.objects;
create policy student_files_insert_hr_offers on storage.objects for insert to authenticated
  with check (bucket_id = 'student_files' and (storage.foldername(name))[2] = 'offers' and public.can_write_offer_file(name));

drop policy if exists student_files_delete_hr_offers on storage.objects;
create policy student_files_delete_hr_offers on storage.objects for delete to authenticated
  using (bucket_id = 'student_files' and (storage.foldername(name))[2] = 'offers' and public.can_write_offer_file(name));

drop policy if exists student_files_select_company_offers on storage.objects;
create policy student_files_select_company_offers on storage.objects for select to authenticated
  using (bucket_id = 'student_files' and (storage.foldername(name))[2] = 'offers' and public.can_read_offer_file(name));

-- ---------------------------------------------------------------- applications guard
create or replace function public.applications_guard()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_role text;
begin
  if current_user not in ('authenticated', 'anon') then
    return coalesce(new, old);
  end if;

  v_role := (select current_user_role());

  if tg_op = 'INSERT' then
    if new.status <> 'pending' then
      raise exception 'A new application must start as pending.';
    end if;
    new.rejection_reason := null;
    new.offer_letter_path := null;
    new.offer_letter_name := null;
    new.offer_letter_size := null;
    new.offer_letter_uploaded_at := null;
    if exists (select 1 from applications where student_id = new.student_id and status = 'active') then
      raise exception 'You have already accepted an internship offer, so you cannot apply to other postings.';
    end if;
    if not exists (
         select 1 from job_postings jp
          where jp.job_posting_id = new.job_posting_id
            and jp.status = 'open'
            and not posting_has_expired(jp.application_deadline, jp.posting_closes_at)) then
      raise exception 'This posting is closed and no longer accepts applications.';
    end if;
    if not exists (
         select 1 from job_postings jp
           join companies c on c.company_id = jp.company_id
          where jp.job_posting_id = new.job_posting_id
            and c.status = 'verified') then
      raise exception 'This company has not been verified yet, so you cannot apply to its postings.';
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    if v_role = 'admin' then
      return old;
    end if;
    if old.status <> 'pending' then
      raise exception 'Only a pending application can be withdrawn.';
    end if;
    return old;
  end if;

  if v_role = 'admin' then
    return new;
  end if;

  if new.student_id is distinct from old.student_id
     or new.job_posting_id is distinct from old.job_posting_id
     or new.cover_letter is distinct from old.cover_letter
     or new.skills is distinct from old.skills
     or new.applied_at is distinct from old.applied_at then
    raise exception 'The details of an application cannot be changed.';
  end if;

  -- the offer letter: only the company's HR, and only until the student has accepted
  if new.offer_letter_path is distinct from old.offer_letter_path
     or new.offer_letter_name is distinct from old.offer_letter_name
     or new.offer_letter_size is distinct from old.offer_letter_size
     or new.offer_letter_uploaded_at is distinct from old.offer_letter_uploaded_at then
    if v_role is distinct from 'company_hr' then
      raise exception 'Only the company''s HR can attach an offer letter.';
    end if;
    if old.status not in ('pending', 'interview', 'offered') then
      raise exception 'The offer letter can only be changed before the student accepts the offer.';
    end if;
    if new.offer_letter_path is distinct from old.offer_letter_path then
      new.offer_letter_uploaded_at := now();
    end if;
  end if;

  if new.status is distinct from old.status then
    if v_role is distinct from 'company_hr' then
      raise exception 'Only the company''s HR can change the status of an application.';
    end if;
    if not (
      (old.status = 'pending'   and new.status in ('interview', 'offered', 'rejected'))
      or (old.status = 'interview' and new.status in ('offered', 'rejected'))
      or (old.status = 'offered'   and new.status = 'rejected')
    ) then
      raise exception 'An application cannot move from % to %.', old.status, new.status;
    end if;
    if new.status = 'offered' and (new.offer_letter_path is null or char_length(btrim(new.offer_letter_path)) = 0) then
      raise exception 'Upload the offer letter before making the offer.';
    end if;
    if new.status = 'rejected' and char_length(btrim(coalesce(new.rejection_reason, ''))) < 100 then
      raise exception 'Please give a reason of at least 100 characters when rejecting an application.';
    end if;
    if new.status <> 'rejected' then
      new.rejection_reason := null;
    end if;
  elsif new.rejection_reason is distinct from old.rejection_reason then
    raise exception 'The rejection reason cannot be changed after the application was rejected.';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------- accepting: the letter becomes the student's document
create or replace function public.accept_offer(p_application_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid  uuid := auth.uid();
  v_app  applications%rowtype;
  v_name text;
begin
  if v_uid is null or (select current_user_role()) is distinct from 'student' then
    raise exception 'Only a signed-in student can accept an offer.';
  end if;

  perform 1 from applications where student_id = v_uid for update;

  select * into v_app from applications
   where application_id = p_application_id and student_id = v_uid;
  if not found then
    raise exception 'That application was not found.';
  end if;
  if v_app.status = 'active' then
    raise exception 'You have already accepted this offer.';
  end if;
  if v_app.status <> 'offered' then
    raise exception 'This application does not have an offer you can accept.';
  end if;
  if exists (select 1 from applications where student_id = v_uid and status = 'active') then
    raise exception 'You have already accepted another offer. Only one internship can be active.';
  end if;

  select full_name into v_name from profiles where profile_id = v_uid;

  update applications set status = 'active', updated_at = now()
   where application_id = p_application_id;

  -- the offer letter of the accepted offer becomes the student's 'offer_letter' document
  if v_app.offer_letter_path is not null then
    delete from documents where student_id = v_uid and category = 'offer_letter';
    insert into documents (student_id, category, status, storage_path, file_name, file_size_bytes)
    values (v_uid, 'offer_letter', 'approved', v_app.offer_letter_path,
            coalesce(v_app.offer_letter_name, 'Offer letter'), v_app.offer_letter_size);
  end if;

  insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
  select h.profile_id,
         'Offer accepted',
         coalesce(nullif(btrim(v_name), ''), 'A student') || ' accepted your offer for ' || jp.title || '.',
         'application',
         v_app.application_id,
         'offer_accepted',
         jsonb_build_object('student', coalesce(nullif(btrim(v_name), ''), ''), 'role', jp.title)
    from job_postings jp
    join company_hr h on h.company_id = jp.company_id
   where jp.job_posting_id = v_app.job_posting_id;

  with closed as (
    update applications set status = 'unavailable', updated_at = now()
     where student_id = v_uid
       and application_id <> p_application_id
       and status in ('pending', 'interview', 'offered')
    returning application_id, job_posting_id
  )
  insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
  select h.profile_id,
         'Candidate no longer available',
         coalesce(nullif(btrim(v_name), ''), 'A student') || ' accepted another offer, so their application for '
           || jp.title || ' has been closed.',
         'application',
         c.application_id,
         'candidate_unavailable',
         jsonb_build_object('student', coalesce(nullif(btrim(v_name), ''), ''), 'role', jp.title)
    from closed c
    join job_postings jp on jp.job_posting_id = c.job_posting_id
    join company_hr h on h.company_id = jp.company_id;
end;
$$;
