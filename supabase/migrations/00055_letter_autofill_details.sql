-- 00055: documents that are filled and signed in the app (indemnity letter, company acceptance letter) take their details
-- from the profile instead of asking for them again.
--
--   * student_identity: the student's IC number, kept apart from the general student record (students.* is readable by
--     more people than should see an IC). Readable and editable by the student, readable by an administrator, and used
--     only through letter_context() by the company HR whose intern it is.
--   * letter_context(application): everything a letter can fill in by itself, for the student (own profile and own
--     accepted internship), for the company HR of an accepted intern, and for an administrator:
--       student  : name, registration no., IC, e-mail, phone, birth date, address, programme, faculty, semester, CGPA
--       company  : name, address, company supervisor (assigned one), HR contact
--       internship: job title, intake name, start and end dates, number of months

create table if not exists public.student_identity (
  profile_id uuid primary key references public.students(profile_id) on delete cascade,
  ic_number text check (ic_number is null or ic_number ~ '^\d{6}-?\d{2}-?\d{4}$'),
  updated_at timestamptz not null default now()
);
alter table public.student_identity enable row level security;

drop policy if exists student_identity_own on public.student_identity;
create policy student_identity_own on public.student_identity for all to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

drop policy if exists student_identity_admin_select on public.student_identity;
create policy student_identity_admin_select on public.student_identity for select to authenticated
  using ((select current_user_role()) = 'admin');

create or replace function public.letter_context(p_application uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text := (select current_user_role());
  v_app applications%rowtype;
  v_student uuid;
  v_company uuid;
  v_job record;
  v_sup text;
  v_sup_ids uuid[];
  v_intake record;
  v_student_json jsonb;
  v_company_json jsonb := '{}'::jsonb;
  v_internship_json jsonb := '{}'::jsonb;
begin
  if v_uid is null then
    raise exception 'You must be logged in.';
  end if;

  if v_role = 'student' then
    v_student := v_uid;
    select * into v_app from applications where student_id = v_uid and status = 'active' limit 1;
  elsif v_role in ('company_hr', 'admin') then
    select * into v_app from applications where application_id = p_application;
    if not found then
      raise exception 'That application was not found.';
    end if;
    v_student := v_app.student_id;
    if v_role = 'company_hr' then
      select jp.company_id into v_company from job_postings jp where jp.job_posting_id = v_app.job_posting_id;
      if not public.is_my_company(v_company) or v_app.status <> 'active' then
        raise exception 'You can only fill letters for students who accepted an offer from your company.' using errcode = '42501';
      end if;
    end if;
  else
    raise exception 'Not allowed.' using errcode = '42501';
  end if;

  select jsonb_build_object(
           'name', p.full_name, 'reg_no', s.student_reg_no, 'ic', si.ic_number, 'email', p.email, 'phone', p.phone,
           'dob', p.date_of_birth, 'address', p.address_text, 'programme', s.programme, 'faculty', s.faculty,
           'semester', s.semester, 'cgpa', s.cgpa)
    into v_student_json
    from profiles p
    join students s on s.profile_id = p.profile_id
    left join student_identity si on si.profile_id = p.profile_id
   where p.profile_id = v_student;

  if v_app.application_id is not null then
    select jp.title, jp.company_id, c.name as company_name, c.location as company_address, c.hr_contact_name
      into v_job
      from job_postings jp join companies c on c.company_id = jp.company_id
     where jp.job_posting_id = v_app.job_posting_id;

    -- the assigned company supervisor, or the only one the company has
    if v_app.company_supervisor_id is not null then
      select coalesce(nullif(btrim(full_name), ''), email) into v_sup from profiles where profile_id = v_app.company_supervisor_id;
    else
      select coalesce(array_agg(s), '{}') into v_sup_ids from public.approved_company_supervisors(v_job.company_id) s;
      if array_length(v_sup_ids, 1) = 1 then
        select coalesce(nullif(btrim(full_name), ''), email) into v_sup from profiles where profile_id = v_sup_ids[1];
      end if;
    end if;

    v_company_json := jsonb_build_object('name', v_job.company_name, 'address', v_job.company_address,
                                         'supervisor', v_sup, 'hr_name', v_job.hr_contact_name);
    v_internship_json := jsonb_build_object('job_title', v_job.title);
  end if;

  select i.name, i.start_date, i.end_date, public.intake_months(i.start_date, i.end_date) as months
    into v_intake
    from students s join intakes i on i.intake_id = s.intake_id
   where s.profile_id = v_student;
  if found then
    v_internship_json := v_internship_json || jsonb_build_object('intake', v_intake.name, 'start', v_intake.start_date,
                                                                  'end', v_intake.end_date, 'months', v_intake.months);
  end if;

  return jsonb_build_object('student', v_student_json, 'company', v_company_json, 'internship', v_internship_json);
end;
$$;
revoke all on function public.letter_context(uuid) from public, anon;
grant execute on function public.letter_context(uuid) to authenticated;
