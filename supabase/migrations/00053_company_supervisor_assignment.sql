-- 00053: each intern has ONE company supervisor.
--
--   * applications.company_supervisor_id: the company supervisor of a student who accepted (status 'active').
--   * A company with exactly one (approved) company supervisor: its interns are assigned to that person automatically,
--     when the student accepts, and when the company ends up with one supervisor later (a supervisor is approved,
--     added to the company, suspended or removed).
--   * A company with more than one: the company's HR assigns each intern (hr_assign_company_supervisor), and can change
--     it until the intern has been evaluated. Until then nobody is responsible for that intern.
--   * Only the assigned supervisor can review the intern's reports and evaluate the intern (database rules, not just
--     screens); the company supervisor's intern list and statistics show only their own interns.

alter table public.applications add column if not exists company_supervisor_id uuid references public.profiles(profile_id) on delete set null;
create index if not exists idx_applications_company_supervisor on public.applications (company_supervisor_id);

-- ---------------------------------------------------------------- who counts as a company supervisor
create or replace function public.approved_company_supervisors(p_company uuid)
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select cs.profile_id
    from company_supervisors cs
    join profiles p on p.profile_id = cs.profile_id
   where cs.company_id = p_company
     and p.approval_status = 'approved'
     and p.email not like '%@deleted.invalid';
$$;
revoke all on function public.approved_company_supervisors(uuid) from public, anon;
grant execute on function public.approved_company_supervisors(uuid) to authenticated;

-- ---------------------------------------------------------------- automatic assignment
create or replace function public.refresh_company_supervisor_assignments(p_company uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ids uuid[];
begin
  if p_company is null then
    return;
  end if;
  select coalesce(array_agg(s), '{}') into v_ids from public.approved_company_supervisors(p_company) s;

  -- an intern whose supervisor is no longer approved there (suspended, removed, moved) is unassigned again,
  -- unless that supervisor already evaluated the intern (the evaluation stays theirs)
  update applications a
     set company_supervisor_id = null
    from job_postings jp
   where jp.job_posting_id = a.job_posting_id
     and jp.company_id = p_company
     and a.status = 'active'
     and a.company_supervisor_id is not null
     and not (a.company_supervisor_id = any (v_ids))
     and not exists (select 1 from evaluations e where e.student_id = a.student_id and e.type = 'workplace');

  -- exactly one supervisor: all unassigned interns of the company are theirs
  if array_length(v_ids, 1) = 1 then
    with assigned as (
      update applications a
         set company_supervisor_id = v_ids[1]
        from job_postings jp
       where jp.job_posting_id = a.job_posting_id
         and jp.company_id = p_company
         and a.status = 'active'
         and a.company_supervisor_id is null
      returning a.application_id, a.student_id, jp.title
    )
    insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
    select v_ids[1], 'New intern assigned',
           coalesce(nullif(btrim(p.full_name), ''), 'A student') || ' (' || x.title || ') has been assigned to you.',
           'application', x.application_id, 'intern_assigned',
           jsonb_build_object('student', coalesce(nullif(btrim(p.full_name), ''), ''), 'role', x.title)
      from assigned x
      join profiles p on p.profile_id = x.student_id;
  end if;
end;
$$;
revoke all on function public.refresh_company_supervisor_assignments(uuid) from public, anon, authenticated;

create or replace function public.trg_applications_assign_supervisor()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company uuid;
begin
  if new.status = 'active' and old.status is distinct from 'active' then
    select jp.company_id into v_company from job_postings jp where jp.job_posting_id = new.job_posting_id;
    perform public.refresh_company_supervisor_assignments(v_company);
  end if;
  return null;
end;
$$;
drop trigger if exists applications_assign_supervisor on public.applications;
create trigger applications_assign_supervisor after update of status on public.applications
  for each row execute function public.trg_applications_assign_supervisor();

create or replace function public.trg_company_supervisors_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and old.company_id is distinct from new.company_id then
    perform public.refresh_company_supervisor_assignments(old.company_id);
  end if;
  perform public.refresh_company_supervisor_assignments(new.company_id);
  return null;
end;
$$;
drop trigger if exists company_supervisors_changed on public.company_supervisors;
create trigger company_supervisors_changed after insert or update of company_id on public.company_supervisors
  for each row execute function public.trg_company_supervisors_changed();

create or replace function public.trg_profiles_supervisor_approval()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company uuid;
begin
  if new.role = 'company_supervisor' and new.approval_status is distinct from old.approval_status then
    select company_id into v_company from company_supervisors where profile_id = new.profile_id;
    perform public.refresh_company_supervisor_assignments(v_company);
  end if;
  return null;
end;
$$;
drop trigger if exists profiles_supervisor_approval on public.profiles;
create trigger profiles_supervisor_approval after update of approval_status on public.profiles
  for each row execute function public.trg_profiles_supervisor_approval();

-- ---------------------------------------------------------------- HR: who can be assigned, and assigning
create or replace function public.hr_company_supervisors()
returns table (profile_id uuid, full_name text, email text, interns bigint)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company uuid;
begin
  if (select current_user_role()) is distinct from 'company_hr' then
    raise exception 'Only the company''s HR can see this.' using errcode = '42501';
  end if;
  select company_id into v_company from company_hr where company_hr.profile_id = auth.uid();
  return query
    select p.profile_id, p.full_name, p.email,
           (select count(*) from applications a where a.company_supervisor_id = p.profile_id and a.status = 'active')
      from public.approved_company_supervisors(v_company) s
      join profiles p on p.profile_id = s
     order by p.full_name;
end;
$$;
revoke all on function public.hr_company_supervisors() from public, anon;
grant execute on function public.hr_company_supervisors() to authenticated;

create or replace function public.hr_assign_company_supervisor(p_application uuid, p_supervisor uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company uuid;
  v_app applications%rowtype;
  v_posting_company uuid;
  v_title text;
  v_student text;
begin
  if (select current_user_role()) is distinct from 'company_hr' then
    raise exception 'Only the company''s HR can assign a company supervisor.' using errcode = '42501';
  end if;
  select company_id into v_company from company_hr where profile_id = auth.uid();

  select * into v_app from applications where application_id = p_application;
  if not found then
    raise exception 'That application was not found.';
  end if;
  select jp.company_id, jp.title into v_posting_company, v_title from job_postings jp where jp.job_posting_id = v_app.job_posting_id;
  if v_posting_company is distinct from v_company then
    raise exception 'That student is not an intern of your company.' using errcode = '42501';
  end if;
  if v_app.status <> 'active' then
    raise exception 'A company supervisor can be assigned once the student has accepted the offer.';
  end if;
  if not (p_supervisor in (select s from public.approved_company_supervisors(v_company) s)) then
    raise exception 'That person is not an approved company supervisor of your company.';
  end if;
  if exists (select 1 from evaluations e where e.student_id = v_app.student_id and e.type = 'workplace') then
    raise exception 'This student has already been evaluated, so the company supervisor can no longer be changed.';
  end if;
  if v_app.company_supervisor_id is not distinct from p_supervisor then
    return;
  end if;

  update applications set company_supervisor_id = p_supervisor where application_id = p_application;

  select coalesce(nullif(btrim(full_name), ''), '') into v_student from profiles where profile_id = v_app.student_id;
  insert into notifications (user_id, title, body, type, related_id, msg_key, msg_args)
  values (p_supervisor, 'New intern assigned',
          coalesce(nullif(v_student, ''), 'A student') || ' (' || v_title || ') has been assigned to you.',
          'application', p_application, 'intern_assigned',
          jsonb_build_object('student', v_student, 'role', v_title));
end;
$$;
revoke all on function public.hr_assign_company_supervisor(uuid, uuid) from public, anon;
grant execute on function public.hr_assign_company_supervisor(uuid, uuid) to authenticated;

insert into public.notification_templates (msg_key, lang, title, body) values
  ('intern_assigned', 'en', 'New intern assigned', '{student} ({role}) has been assigned to you.'),
  ('intern_assigned', 'ms', 'Pelatih baharu ditugaskan', '{student} ({role}) telah ditugaskan kepada anda.'),
  ('intern_assigned', 'zh', '新实习生已分配', '{student}（{role}）已分配给您。')
on conflict do nothing;

-- ---------------------------------------------------------------- enforcement
-- only the assigned company supervisor reviews an intern's reports
create or replace function public.can_manage_company_review(p_report_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from reports r join applications a on a.student_id = r.student_id
                 where r.report_id = p_report_id
                   and a.status = 'active'
                   and a.company_supervisor_id = (select auth.uid())
                   and (select current_user_role()) = 'company_supervisor');
$$;

-- only the assigned company supervisor evaluates an intern
create or replace function public.evaluations_workplace_guard()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_key text;
  v_val numeric;
  v_total numeric := 0;
  v_assigned uuid;
begin
  if new.type <> 'workplace' then
    return new;
  end if;
  if exists (select 1 from public.evaluations e where e.student_id = new.student_id and e.type = 'workplace') then
    raise exception 'This student has already been evaluated. The evaluation is closed and cannot be submitted again.';
  end if;
  select a.company_supervisor_id into v_assigned
    from public.applications a
   where a.student_id = new.student_id and a.status = 'active'
   limit 1;
  if v_assigned is null then
    raise exception 'This student has not been assigned to a company supervisor yet. Ask the company''s HR to assign one.';
  end if;
  if v_assigned is distinct from new.supervisor_id then
    raise exception 'This student is assigned to another company supervisor.';
  end if;
  foreach v_key in array array['technical_knowledge', 'dependability', 'initiative', 'commitment', 'quality_of_work',
                               'working_relationship', 'discipline', 'system_development_skills', 'punctuality', 'attendance'] loop
    v_val := (new.scores->>v_key)::numeric;
    if v_val is null then
      raise exception 'Mark every criterion of the evaluation (missing: %).', v_key;
    end if;
    if v_val < 0 or v_val > 6 or v_val <> trunc(v_val) then
      raise exception 'The mark for % must be a whole number from 0 to 6.', v_key;
    end if;
    v_total := v_total + v_val;
  end loop;
  if new.attendance_with_permission is null or new.attendance_without_permission is null then
    raise exception 'Enter the number of days the student was absent with and without permission.';
  end if;
  if new.overall_grade is null then
    raise exception 'Choose the overall grade (A, B+, B, C or F).';
  end if;
  if char_length(btrim(coalesce(new.comments, ''))) < 10 then
    raise exception 'Write your comments about the student (at least 10 characters).';
  end if;
  if char_length(btrim(coalesce(new.training_notes, ''))) < 10 then
    raise exception 'Describe the training the student underwent (at least 10 characters).';
  end if;
  if char_length(btrim(coalesce(new.designation, ''))) < 2 then
    raise exception 'Enter your designation.';
  end if;
  new.marks_total := v_total;
  new.average_score := round(v_total / 12, 2);  -- the old 1-5 scale, for screens that still show it
  return new;
end;
$$;

-- the company supervisor's statistics count only their own interns
do $$
declare
  d text := pg_get_functiondef('public.company_supervisor_stats()'::regprocedure);
  old_part text := E'where a.status = ''active'' and jp.company_id = v_company)';
  new_part text := E'where a.status = ''active'' and jp.company_id = v_company and a.company_supervisor_id = v_uid)';
begin
  if position(old_part in d) = 0 then
    raise exception 'company_supervisor_stats has an unexpected shape';
  end if;
  execute replace(d, old_part, new_part);
end $$;

-- ---------------------------------------------------------------- existing interns
-- an intern already evaluated stays with the evaluator
update public.applications a
   set company_supervisor_id = e.supervisor_id
  from public.evaluations e
 where e.student_id = a.student_id and e.type = 'workplace'
   and a.status = 'active' and a.company_supervisor_id is null;

do $$
declare
  c record;
begin
  for c in select company_id from public.companies loop
    perform public.refresh_company_supervisor_assignments(c.company_id);
  end loop;
end $$;
