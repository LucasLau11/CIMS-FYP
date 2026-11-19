-- 00044: company verification. An HR person registering a company uploads its legal documents; an
-- administrator verifies or rejects the company; an unverified company cannot post jobs.
-- Applied as 00044a_company_verification_documents.

-- 1. a company can also be rejected, with a note for the HR person
alter table public.companies drop constraint if exists companies_status_check;
alter table public.companies add constraint companies_status_check check (status in ('pending', 'verified', 'rejected'));
alter table public.companies add column if not exists verification_note text;

-- 2. only an administrator may decide a company's status. (companies_update_own_staff let a company's
--    own staff update the whole row, which also meant they could mark their company verified, and a new
--    company could be inserted already verified.)
create or replace function public.companies_status_guard()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is null
     or (select current_user_role()) = 'admin'
     or current_setting('app.company_status_ok', true) = '1' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.status := 'pending';
    new.verification_note := null;
  elsif new.status is distinct from old.status or new.verification_note is distinct from old.verification_note then
    raise exception 'Only an administrator can verify a company.' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists companies_status_guard on public.companies;
create trigger companies_status_guard before insert or update on public.companies
  for each row execute function public.companies_status_guard();

-- 3. the legal documents
create or replace function public.is_company_hr_of(p_company uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from company_hr h where h.profile_id = (select auth.uid()) and h.company_id = p_company);
$$;
revoke all on function public.is_company_hr_of(uuid) from public, anon;
grant execute on function public.is_company_hr_of(uuid) to authenticated;

create table if not exists public.company_documents (
  document_id  uuid primary key default gen_random_uuid(),
  company_id   uuid not null references public.companies(company_id) on delete cascade,
  uploaded_by  uuid references public.profiles(profile_id),
  doc_type     text not null default 'other',
  file_name    text not null,
  storage_path text not null,
  file_size_bytes bigint,
  uploaded_at  timestamptz not null default now()
);
create index if not exists company_documents_company_idx on public.company_documents (company_id);
alter table public.company_documents enable row level security;

drop policy if exists company_documents_select on public.company_documents;
create policy company_documents_select on public.company_documents for select to authenticated
  using (is_company_hr_of(company_id) or (select current_user_role()) = 'admin');
drop policy if exists company_documents_insert on public.company_documents;
create policy company_documents_insert on public.company_documents for insert to authenticated
  with check (is_company_hr_of(company_id) and uploaded_by = (select auth.uid()));
drop policy if exists company_documents_delete on public.company_documents;
create policy company_documents_delete on public.company_documents for delete to authenticated
  using ((select current_user_role()) = 'admin'
         or (is_company_hr_of(company_id) and exists (select 1 from companies c where c.company_id = company_documents.company_id and c.status <> 'verified')));

-- a new document after a rejection sends the company back for review
create or replace function public.company_documents_resubmit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform set_config('app.company_status_ok', '1', true);
  update companies set status = 'pending', verification_note = null where company_id = new.company_id and status = 'rejected';
  perform set_config('app.company_status_ok', '0', true);
  return new;
end;
$$;
drop trigger if exists company_documents_resubmit on public.company_documents;
create trigger company_documents_resubmit after insert on public.company_documents
  for each row execute function public.company_documents_resubmit();

-- private file storage: <company id>/<file>
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('company_documents', 'company_documents', false, 10485760, array['application/pdf', 'image/jpeg', 'image/png'])
on conflict (id) do update set file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists company_documents_objects_insert on storage.objects;
create policy company_documents_objects_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'company_documents' and public.is_company_hr_of(((storage.foldername(name))[1])::uuid));
drop policy if exists company_documents_objects_select on storage.objects;
create policy company_documents_objects_select on storage.objects for select to authenticated
  using (bucket_id = 'company_documents'
         and (public.is_company_hr_of(((storage.foldername(name))[1])::uuid) or (select public.current_user_role()) = 'admin'));
drop policy if exists company_documents_objects_delete on storage.objects;
create policy company_documents_objects_delete on storage.objects for delete to authenticated
  using (bucket_id = 'company_documents'
         and ((select public.current_user_role()) = 'admin' or public.is_company_hr_of(((storage.foldername(name))[1])::uuid)));

-- 4. the administrator's decision, with a notification to the company's HR people
insert into public.notification_templates (msg_key, lang, title, body) values
 ('company_verified','en','Company verified','{company} has been verified. You can now post internships.'),
 ('company_verified','ms','Syarikat disahkan','{company} telah disahkan. Anda kini boleh menyiarkan latihan industri.'),
 ('company_verified','zh','公司已认证','{company}已通过认证。您现在可以发布实习职位。'),
 ('company_rejected','en','Company not verified','{company} could not be verified. Reason: {reason} Upload the correct documents and it will be reviewed again.'),
 ('company_rejected','ms','Syarikat tidak disahkan','{company} tidak dapat disahkan. Sebab: {reason} Muat naik dokumen yang betul dan ia akan disemak semula.'),
 ('company_rejected','zh','公司未通过认证','{company}未能通过认证。原因：{reason} 请上传正确的文件，我们会重新审核。')
on conflict (msg_key, lang) do update set title = excluded.title, body = excluded.body;

create or replace function public.admin_set_company_status(p_company uuid, p_status text, p_note text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if (select current_user_role()) is distinct from 'admin' then
    raise exception 'Only an administrator can do this.' using errcode = '42501';
  end if;
  if p_status not in ('verified', 'rejected', 'pending') then
    raise exception 'Unknown company status.';
  end if;
  select name into v_name from companies where company_id = p_company;
  if v_name is null then
    raise exception 'That company was not found.';
  end if;
  if p_status = 'rejected' and (v_note is null or char_length(v_note) < 100 or char_length(v_note) > 500) then
    raise exception 'Please give a reason of 100 to 500 characters.';
  end if;

  update companies set status = p_status, verification_note = case when p_status = 'rejected' then v_note else null end
   where company_id = p_company;

  if p_status in ('verified', 'rejected') then
    insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
    select h.profile_id,
           case p_status when 'verified' then 'Company verified' else 'Company not verified' end,
           case p_status when 'verified' then v_name || ' has been verified. You can now post internships.'
                         else v_name || ' could not be verified. Reason: ' || v_note || ' Upload the correct documents and it will be reviewed again.' end,
           'company', p_company,
           case p_status when 'verified' then 'company_verified' else 'company_rejected' end,
           jsonb_build_object('company', v_name, 'reason', coalesce(v_note, ''))
      from company_hr h where h.company_id = p_company;
  end if;
end;
$$;
revoke all on function public.admin_set_company_status(uuid, text, text) from public, anon;
grant execute on function public.admin_set_company_status(uuid, text, text) to authenticated;

-- 5. no postings from a company that is not verified
create or replace function public.job_postings_guard()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is not null and (select current_user_role()) is distinct from 'admin'
     and (tg_op = 'INSERT' or (new.status = 'open' and old.status is distinct from 'open'))
     and not exists (select 1 from companies c where c.company_id = new.company_id and c.status = 'verified') then
    raise exception 'Your company has not been verified yet, so you cannot post internships. Upload your company documents and wait for an administrator to verify them.';
  end if;
  if new.status = 'open' and posting_has_expired(new.application_deadline, new.posting_closes_at) then
    raise exception 'The deadline of this posting has passed. Extend the deadline or the closing date before it can be open.';
  end if;
  return new;
end;
$$;

-- 6. HR accounts are approved at sign-up (the company is what gets verified); supervisors still wait
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text := new.raw_user_meta_data->>'app_role';
  v_name text := left(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 100);
  v_by_admin boolean := coalesce((new.raw_app_meta_data->>'created_by_admin')::boolean, false);
  v_must_change boolean;
begin
  if v_role is null or v_role not in
     ('student', 'academic_supervisor', 'company_hr', 'company_supervisor') then
    return new;
  end if;

  if not v_by_admin then
    delete from admin_account_grants
     where lower(email) = lower(new.email) and created_at > now() - interval '10 minutes';
    v_by_admin := found;
    v_must_change := v_by_admin;
  else
    v_must_change := coalesce((new.raw_app_meta_data->>'must_change_password')::boolean, false);
  end if;

  if v_role = 'student' and not v_by_admin then
    raise exception 'Student accounts are created by the administrator.';
  end if;

  insert into profiles (profile_id, role, email, full_name, approval_status, must_change_password)
  values (
    new.id, v_role, new.email, v_name,
    case when v_role in ('academic_supervisor', 'company_supervisor') and not v_by_admin
         then 'pending' else 'approved' end,
    v_must_change)
  on conflict (profile_id) do nothing;

  case v_role
    when 'student' then insert into students (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'academic_supervisor' then insert into academic_supervisors (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'company_hr' then insert into company_hr (profile_id) values (new.id) on conflict (profile_id) do nothing;
    when 'company_supervisor' then insert into company_supervisors (profile_id) values (new.id) on conflict (profile_id) do nothing;
  end case;

  return new;
end;
$$;

-- 7. an HR person of an unverified company cannot start chats with students
do $$
declare
  d text := pg_get_functiondef('public.can_message(uuid)'::regprocedure);
  old_part text := E'  if v_role = ''company_hr'' then\n    if v_trole = ''student'' then\n      return true;';
  new_part text := E'  if v_role = ''company_hr'' then\n    if v_trole = ''student'' then\n      return exists (select 1 from company_hr h join companies c on c.company_id = h.company_id where h.profile_id = v_uid and c.status = ''verified'');';
begin
  if position(old_part in d) = 0 then
    raise exception 'can_message has an unexpected shape';
  end if;
  execute replace(d, old_part, new_part);
end $$;
