-- 00039: report statistics for every staff role, and admin-created academic supervisor accounts.
--
-- Statistics: four functions, each answering one role with plain numbers (the app writes the labels,
-- so they follow the app's language). Each one only ever looks at the caller's own scope:
--   hr_stats()                  their company's postings, applications and interviews
--   academic_supervisor_stats() the students assigned to them: placement, reports, documents
--   company_supervisor_stats()  the students placed at their company: reports, evaluations
--   admin_platform_stats()      accounts and companies on the platform, and how they grew
--
-- Accounts: an academic supervisor created by an administrator (through the admin-create-students
-- Edge Function, which marks the auth user with app_metadata.created_by_admin) is approved right away,
-- because the administrator is the one approving. A self sign-up is still 'pending'.

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_role text := new.raw_user_meta_data->>'app_role';
  v_name text := left(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 100);
  -- app_metadata can only be written with the service role, never by a client sign-up.
  v_by_admin boolean := coalesce((new.raw_app_meta_data->>'created_by_admin')::boolean, false);
  v_must_change boolean := v_by_admin and coalesce((new.raw_app_meta_data->>'must_change_password')::boolean, false);
begin
  if v_role is null or v_role not in
     ('student', 'academic_supervisor', 'company_hr', 'company_supervisor') then
    return new;
  end if;

  if v_role = 'student' and not v_by_admin then
    raise exception 'Student accounts are created by the administrator.';
  end if;

  insert into profiles (profile_id, role, email, full_name, approval_status, must_change_password)
  values (
    new.id, v_role, new.email, v_name,
    case when v_role in ('academic_supervisor', 'company_hr', 'company_supervisor') and not v_by_admin
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
$function$;

-- ---------------------------------------------------------------- company HR
create or replace function public.hr_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_company uuid;
  r jsonb;
begin
  if (select current_user_role()) is distinct from 'company_hr' then
    raise exception 'Only company HR can open these statistics.';
  end if;
  select company_id into v_company from company_hr where profile_id = v_uid;
  if v_company is null then
    return jsonb_build_object('company_set', false);
  end if;

  with p as (select job_posting_id, title, status from job_postings where company_id = v_company),
       a as (select ap.application_id, ap.student_id, ap.job_posting_id, ap.status, ap.applied_at
               from applications ap join p on p.job_posting_id = ap.job_posting_id)
  select jsonb_build_object(
    'company_set',          true,
    'postings_total',       (select count(*) from p),
    'postings_open',        (select count(*) from p where status = 'open'),
    'applications_total',   (select count(*) from a),
    'applicants_unique',    (select count(distinct student_id) from a),
    'by_status',            coalesce((select jsonb_object_agg(status, n) from (select status, count(*) n from a group by status) t), '{}'::jsonb),
    'interviews_upcoming',  (select count(*) from interviews i join a on a.application_id = i.application_id where i.status = 'scheduled' and i.scheduled_at > now()),
    'interviews_completed', (select count(*) from interviews i join a on a.application_id = i.application_id where i.status = 'completed'),
    'per_posting',          coalesce((select jsonb_agg(jsonb_build_object('title', title, 'status', status, 'applications', applications,
                                                                         'interview', interview, 'offered', offered, 'accepted', accepted))
                                        from (select p.title, p.status,
                                                     count(a.application_id) as applications,
                                                     count(a.application_id) filter (where a.status = 'interview') as interview,
                                                     count(a.application_id) filter (where a.status = 'offered') as offered,
                                                     count(a.application_id) filter (where a.status = 'active') as accepted
                                                from p left join a on a.job_posting_id = p.job_posting_id
                                               group by p.job_posting_id, p.title, p.status
                                               order by count(a.application_id) desc, p.title
                                               limit 15) t), '[]'::jsonb),
    'weekly',               coalesce((select jsonb_agg(jsonb_build_object('week', to_char(w, 'YYYY-MM-DD'), 'count', n) order by w)
                                        from (select gs as w,
                                                     (select count(*) from a where a.applied_at >= gs and a.applied_at < gs + interval '7 days') as n
                                                from generate_series(date_trunc('week', now()) - interval '7 weeks', date_trunc('week', now()), interval '1 week') gs) t), '[]'::jsonb)
  ) into r;
  return r;
end;
$$;

revoke all on function public.hr_stats() from public, anon;
grant execute on function public.hr_stats() to authenticated;

-- ----------------------------------------------------------- academic supervisor
create or replace function public.academic_supervisor_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  r jsonb;
begin
  if (select current_user_role()) is distinct from 'academic_supervisor' then
    raise exception 'Only an academic supervisor can open these statistics.';
  end if;

  with s as (select profile_id from students where academic_supervisor_id = v_uid),
       placed as (select distinct student_id from applications where status = 'active' and student_id in (select profile_id from s)),
       rep as (select * from v_report_with_reviews where student_id in (select profile_id from s)),
       doc as (select * from documents where student_id in (select profile_id from s))
  select jsonb_build_object(
    'students_total',    (select count(*) from s),
    'students_placed',   (select count(*) from placed),
    'reports_total',     (select count(*) from rep),
    'reports_monthly',   (select count(*) from rep where type = 'monthly'),
    'reports_final',     (select count(*) from rep where type = 'final'),
    'reports_pending',   (select count(*) from rep where academic_status is null or academic_status = 'submitted'),
    'reports_approved',  (select count(*) from rep where academic_status = 'approved'),
    'reports_rejected',  (select count(*) from rep where academic_status is not null and academic_status not in ('submitted', 'approved')),
    'documents_pending', (select count(*) from doc where status = 'submitted'),
    'documents_approved',(select count(*) from doc where status = 'approved'),
    'evaluations_done',  (select count(*) from evaluations where supervisor_id = v_uid and type = 'academic'),
    'per_student',       coalesce((select jsonb_agg(jsonb_build_object('name', name, 'placed', placed, 'reports', reports, 'approved', approved, 'pending', pending))
                                     from (select coalesce(nullif(btrim(p.full_name), ''), p.email) as name,
                                                  (pl.student_id is not null) as placed,
                                                  count(rep.report_id) as reports,
                                                  count(rep.report_id) filter (where rep.academic_status = 'approved') as approved,
                                                  count(rep.report_id) filter (where rep.academic_status is null or rep.academic_status = 'submitted') as pending
                                             from s
                                             join profiles p on p.profile_id = s.profile_id
                                             left join placed pl on pl.student_id = s.profile_id
                                             left join rep on rep.student_id = s.profile_id
                                            group by p.profile_id, p.full_name, p.email, pl.student_id
                                            order by count(rep.report_id) filter (where rep.academic_status is null or rep.academic_status = 'submitted') desc, 1
                                            limit 50) t), '[]'::jsonb)
  ) into r;
  return r;
end;
$$;

revoke all on function public.academic_supervisor_stats() from public, anon;
grant execute on function public.academic_supervisor_stats() to authenticated;

-- ------------------------------------------------------------ company supervisor
create or replace function public.company_supervisor_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_company uuid;
  r jsonb;
begin
  if (select current_user_role()) is distinct from 'company_supervisor' then
    raise exception 'Only a company supervisor can open these statistics.';
  end if;
  select company_id into v_company from company_supervisors where profile_id = v_uid;
  if v_company is null then
    return jsonb_build_object('company_set', false);
  end if;

  with s as (select distinct a.student_id as profile_id
               from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
              where a.status = 'active' and jp.company_id = v_company),
       rep as (select * from v_report_with_reviews where student_id in (select profile_id from s))
  select jsonb_build_object(
    'company_set',        true,
    'students_total',     (select count(*) from s),
    'reports_total',      (select count(*) from rep),
    'reports_pending',    (select count(*) from rep where company_status is null or company_status = 'submitted'),
    'reports_approved',   (select count(*) from rep where company_status = 'approved'),
    'reports_rejected',   (select count(*) from rep where company_status is not null and company_status not in ('submitted', 'approved')),
    'evaluations_done',   (select count(*) from evaluations where supervisor_id = v_uid and type = 'workplace'),
    'students_evaluated', (select count(distinct student_id) from evaluations where supervisor_id = v_uid and type = 'workplace'),
    'per_student',        coalesce((select jsonb_agg(jsonb_build_object('name', name, 'evaluated', evaluated, 'reports', reports, 'approved', approved, 'pending', pending))
                                      from (select coalesce(nullif(btrim(p.full_name), ''), p.email) as name,
                                                   exists (select 1 from evaluations e where e.student_id = s.profile_id and e.supervisor_id = v_uid and e.type = 'workplace') as evaluated,
                                                   count(rep.report_id) as reports,
                                                   count(rep.report_id) filter (where rep.company_status = 'approved') as approved,
                                                   count(rep.report_id) filter (where rep.company_status is null or rep.company_status = 'submitted') as pending
                                              from s
                                              join profiles p on p.profile_id = s.profile_id
                                              left join rep on rep.student_id = s.profile_id
                                             group by p.profile_id, p.full_name, p.email, s.profile_id
                                             order by 1
                                             limit 50) t), '[]'::jsonb)
  ) into r;
  return r;
end;
$$;

revoke all on function public.company_supervisor_stats() from public, anon;
grant execute on function public.company_supervisor_stats() to authenticated;

-- ----------------------------------------------------------------------- admin
create or replace function public.admin_platform_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  r jsonb;
begin
  if (select current_user_role()) is distinct from 'admin' then
    raise exception 'Only an administrator can open the platform statistics.';
  end if;

  select jsonb_build_object(
    'users_by_role',         coalesce((select jsonb_object_agg(role, n)
                                         from (select role, count(*) n from profiles
                                                where approval_status = 'approved' and email not like '%@deleted.invalid' group by role) t), '{}'::jsonb),
    'pending_approvals',     (select count(*) from profiles where approval_status = 'pending' and email not like '%@deleted.invalid'),
    'companies_total',       (select count(*) from companies),
    'companies_by_status',   coalesce((select jsonb_object_agg(coalesce(status, 'unknown'), n) from (select status, count(*) n from companies group by status) t), '{}'::jsonb),
    'companies_with_postings', (select count(distinct company_id) from job_postings),
    'new_companies_30d',     (select count(*) from companies where created_at > now() - interval '30 days'),
    'new_users_30d',         (select count(*) from profiles where created_at > now() - interval '30 days' and email not like '%@deleted.invalid'),
    'postings_total',        (select count(*) from job_postings),
    'postings_open',         (select count(*) from job_postings where status = 'open'),
    'applications_total',    (select count(*) from applications),
    'interviews_upcoming',   (select count(*) from interviews where status = 'scheduled' and scheduled_at > now()),
    'companies_monthly',     coalesce((select jsonb_agg(jsonb_build_object('month', to_char(m, 'YYYY-MM'), 'count', n) order by m)
                                         from (select gs as m, (select count(*) from companies c where c.created_at >= gs and c.created_at < gs + interval '1 month') as n
                                                 from generate_series(date_trunc('month', now()) - interval '5 months', date_trunc('month', now()), interval '1 month') gs) t), '[]'::jsonb),
    'users_monthly',         coalesce((select jsonb_agg(jsonb_build_object('month', to_char(m, 'YYYY-MM'), 'count', n) order by m)
                                         from (select gs as m, (select count(*) from profiles p where p.created_at >= gs and p.created_at < gs + interval '1 month' and p.email not like '%@deleted.invalid') as n
                                                 from generate_series(date_trunc('month', now()) - interval '5 months', date_trunc('month', now()), interval '1 month') gs) t), '[]'::jsonb)
  ) into r;
  return r;
end;
$$;

revoke all on function public.admin_platform_stats() from public, anon;
grant execute on function public.admin_platform_stats() to authenticated;
