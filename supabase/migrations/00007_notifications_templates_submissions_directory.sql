create table notifications (
  notification_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(profile_id),
  title text not null,
  body text,
  type text not null check (type in ('application','report','document','message','evaluation','parent_link')),
  related_id uuid,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create table document_templates (
  template_id uuid primary key default gen_random_uuid(),
  purpose text not null,
  name text not null,
  storage_path text not null,
  page_width numeric not null,
  page_height numeric not null,
  fields jsonb not null default '[]',
  is_active boolean not null default false,
  created_by uuid not null references profiles(profile_id),
  created_at timestamptz not null default now()
);

create table document_submissions (
  submission_id uuid primary key default gen_random_uuid(),
  template_id uuid not null references document_templates(template_id),
  student_id uuid not null references students(profile_id),
  submitted_by uuid not null references profiles(profile_id),
  values jsonb not null default '{}',
  generated_pdf_path text not null,
  submitted_at timestamptz not null default now()
);

create table profile_directory (
  profile_id uuid primary key references profiles(profile_id) on delete cascade,
  full_name text,
  role text not null,
  avatar_url text,
  skills text[],
  programme text
);

alter table notifications enable row level security;
alter table document_templates enable row level security;
alter table document_submissions enable row level security;
alter table profile_directory enable row level security;

create policy notifications_select_own on notifications for select to authenticated using (user_id = (select auth.uid()));
create policy notifications_insert_system on notifications for insert to authenticated with check (true);
create policy notifications_update_own on notifications for update to authenticated using (user_id = (select auth.uid()));

create policy document_templates_select_authenticated on document_templates for select to authenticated using (true);
create policy document_templates_insert_admin on document_templates for insert to authenticated
  with check ((select current_user_role()) = 'admin');
create policy document_templates_update_admin on document_templates for update to authenticated
  using ((select current_user_role()) = 'admin') with check ((select current_user_role()) = 'admin');
create policy document_templates_delete_admin on document_templates for delete to authenticated
  using ((select current_user_role()) = 'admin');

create policy document_submissions_select_involved on document_submissions for select to authenticated
  using (submitted_by = (select auth.uid()) or student_id = (select auth.uid()) or (select current_user_role()) = 'admin'
         or is_approved_parent_of(student_id));
create policy document_submissions_insert_own on document_submissions for insert to authenticated
  with check (submitted_by = (select auth.uid()) and (student_id = (select auth.uid()) or is_approved_parent_of(student_id)));

create policy profile_directory_select_authenticated on profile_directory for select to authenticated using (true);

create index if not exists idx_notifications_user_id on notifications(user_id);
create index if not exists idx_document_templates_created_by on document_templates(created_by);
create index if not exists idx_document_submissions_template_id on document_submissions(template_id);
create index if not exists idx_document_submissions_student_id on document_submissions(student_id);
create index if not exists idx_document_submissions_submitted_by on document_submissions(submitted_by);

-- sync trigger: keeps profile_directory in step with profiles + students without the app writing to it directly
create or replace function sync_profile_directory() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_skills text[]; v_programme text;
begin
  select skills, programme into v_skills, v_programme from students where profile_id = new.profile_id;
  insert into profile_directory (profile_id, full_name, role, avatar_url, skills, programme)
  values (new.profile_id, new.full_name, new.role, new.avatar_url, v_skills, v_programme)
  on conflict (profile_id) do update set
    full_name = excluded.full_name, role = excluded.role, avatar_url = excluded.avatar_url,
    skills = excluded.skills, programme = excluded.programme;
  return new;
end;
$$;
create trigger sync_profile_directory_on_profile after insert or update on profiles
  for each row execute function sync_profile_directory();

create or replace function sync_profile_directory_from_students() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update profile_directory set skills = new.skills, programme = new.programme where profile_id = new.profile_id;
  return new;
end;
$$;
create trigger sync_profile_directory_on_student after insert or update on students
  for each row execute function sync_profile_directory_from_students();
