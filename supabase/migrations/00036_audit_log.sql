-- 00036: an audit log of the important changes administrators (and the rest of the system) make.
--
-- Rows are written ONLY by database triggers (and the admin-create-students Edge Function with the
-- service role), so nobody can leave something out or edit what was written. Only administrators
-- can read the log; nobody can update or delete rows through the API.

create table if not exists public.audit_log (
  audit_id    uuid primary key default gen_random_uuid(),
  actor_id    uuid references public.profiles(profile_id) on delete set null,
  actor_role  text,
  action      text not null,
  target_type text,
  target_id   text,
  summary     text not null,
  details     jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

create index if not exists idx_audit_log_created on public.audit_log (created_at desc);
create index if not exists idx_audit_log_action on public.audit_log (action, created_at desc);

alter table public.audit_log enable row level security;

create policy audit_log_select_admin on public.audit_log
  for select to authenticated using ((select current_user_role()) = 'admin');

-- Used by the triggers below; not callable from the app.
create or replace function public.audit_write(
  p_action text, p_target_type text, p_target_id text, p_summary text, p_details jsonb default '{}'::jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into audit_log (actor_id, actor_role, action, target_type, target_id, summary, details)
  values (auth.uid(), (select current_user_role()), p_action, p_target_type, p_target_id, p_summary, coalesce(p_details, '{}'::jsonb));
end;
$$;
revoke all on function public.audit_write(text, text, text, text, jsonb) from public, anon, authenticated;

create or replace function public._audit_person(p_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(nullif(btrim(full_name), ''), email, 'unknown') from profiles where profile_id = p_id;
$$;
revoke all on function public._audit_person(uuid) from public, anon, authenticated;

-- Accounts: approval decisions, role changes, deletions.
create or replace function public.audit_profiles_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.approval_status is distinct from new.approval_status then
    perform audit_write('account_' || new.approval_status, 'profile', new.profile_id::text,
      'Account of ' || coalesce(nullif(btrim(new.full_name), ''), new.email) || ' (' || new.role || ') set to ' || new.approval_status,
      jsonb_build_object('email', new.email, 'role', new.role, 'from', old.approval_status, 'to', new.approval_status));
  end if;
  if old.role is distinct from new.role then
    perform audit_write('role_changed', 'profile', new.profile_id::text,
      'Role of ' || coalesce(nullif(btrim(new.full_name), ''), new.email) || ' changed from ' || old.role || ' to ' || new.role,
      jsonb_build_object('from', old.role, 'to', new.role));
  end if;
  if old.email not like '%@deleted.invalid' and new.email like '%@deleted.invalid' then
    perform audit_write('account_deleted', 'profile', new.profile_id::text,
      'Account of ' || coalesce(nullif(btrim(old.full_name), ''), old.email) || ' (' || old.role || ') was deleted',
      jsonb_build_object('role', old.role));
  end if;
  return new;
end;
$$;
drop trigger if exists audit_profiles_update on public.profiles;
create trigger audit_profiles_update after update on public.profiles
  for each row execute function public.audit_profiles_update();

-- Companies: created, status changed (for example verified), removed.
create or replace function public.audit_companies()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform audit_write('company_created', 'company', new.company_id::text, 'Company "' || new.name || '" was registered',
      jsonb_build_object('status', new.status));
  elsif tg_op = 'UPDATE' then
    if old.status is distinct from new.status then
      perform audit_write('company_status_changed', 'company', new.company_id::text,
        'Company "' || new.name || '" changed from ' || coalesce(old.status, '-') || ' to ' || coalesce(new.status, '-'),
        jsonb_build_object('from', old.status, 'to', new.status));
    end if;
  elsif tg_op = 'DELETE' then
    perform audit_write('company_deleted', 'company', old.company_id::text, 'Company "' || old.name || '" was removed', '{}'::jsonb);
    return old;
  end if;
  return new;
end;
$$;
drop trigger if exists audit_companies on public.companies;
create trigger audit_companies after insert or update or delete on public.companies
  for each row execute function public.audit_companies();

-- Students: supervisor and intake assignments.
create or replace function public.audit_students_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.academic_supervisor_id is distinct from new.academic_supervisor_id then
    perform audit_write('supervisor_assigned', 'student', new.profile_id::text,
      case when new.academic_supervisor_id is null
           then 'Supervisor removed from ' || _audit_person(new.profile_id)
           else _audit_person(new.profile_id) || ' assigned to supervisor ' || _audit_person(new.academic_supervisor_id) end,
      jsonb_build_object('from', old.academic_supervisor_id, 'to', new.academic_supervisor_id));
  end if;
  if old.intake_id is distinct from new.intake_id then
    perform audit_write('intake_assigned', 'student', new.profile_id::text,
      _audit_person(new.profile_id) || case when new.intake_id is null then ' removed from intake' else ' assigned to an intake' end,
      jsonb_build_object('from', old.intake_id, 'to', new.intake_id));
  end if;
  return new;
end;
$$;
drop trigger if exists audit_students_update on public.students;
create trigger audit_students_update after update on public.students
  for each row execute function public.audit_students_update();

-- Intakes.
create or replace function public.audit_intakes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform audit_write('intake_created', 'intake', new.intake_id::text, 'Intake "' || new.name || '" was created',
      jsonb_build_object('start', new.start_date, 'end', new.end_date));
    return new;
  elsif tg_op = 'DELETE' then
    perform audit_write('intake_deleted', 'intake', old.intake_id::text, 'Intake "' || old.name || '" was deleted', '{}'::jsonb);
    return old;
  end if;
  return new;
end;
$$;
drop trigger if exists audit_intakes on public.intakes;
create trigger audit_intakes after insert or delete on public.intakes
  for each row execute function public.audit_intakes();

-- Document templates.
create or replace function public.audit_templates()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform audit_write('template_created', 'document_template', new.template_id::text,
      'Document template "' || new.name || '" (' || new.purpose || ') was added', '{}'::jsonb);
    return new;
  elsif tg_op = 'UPDATE' then
    if old.is_active is distinct from new.is_active then
      perform audit_write('template_' || case when new.is_active then 'activated' else 'deactivated' end, 'document_template', new.template_id::text,
        'Document template "' || new.name || '" was ' || case when new.is_active then 'activated' else 'deactivated' end, '{}'::jsonb);
    end if;
    return new;
  elsif tg_op = 'DELETE' then
    perform audit_write('template_deleted', 'document_template', old.template_id::text,
      'Document template "' || old.name || '" was deleted', '{}'::jsonb);
    return old;
  end if;
  return new;
end;
$$;
drop trigger if exists audit_templates on public.document_templates;
create trigger audit_templates after insert or update or delete on public.document_templates
  for each row execute function public.audit_templates();
