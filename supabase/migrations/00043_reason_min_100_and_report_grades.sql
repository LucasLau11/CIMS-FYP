-- 00043: (a) reasons need at least 100 characters; (b) grading.
-- Applied as 00043a_reason_min_100, 00043b_report_grades_and_student_grade and 00043c_report_view_grade.

-- (a) Reasons (cancel / reschedule / decline an interview, reject an application) must have at least
-- 100 characters. The four functions are patched in place.
do $$
declare
  f text;
  d text;
begin
  foreach f in array array[
    'public.request_reschedule(uuid,timestamp with time zone,text)',
    'public.respond_reschedule(uuid,boolean,text)',
    'public.cancel_interview(uuid,text)',
    'public.applications_guard()'
  ] loop
    d := pg_get_functiondef(f::regprocedure);
    d := replace(d, '< 10)', '< 100)');
    d := replace(d, '< 10 ', '< 100 ');
    d := replace(d, '< 10' || chr(10), '< 100' || chr(10));
    d := replace(d, '10 to 500', '100 to 500');
    d := replace(d, '10 char', '100 char');
    execute d;
  end loop;
end $$;

-- (b) Grading: 60% from the company supervisor's evaluation, 40% from the academic supervisor.
-- The academic 40 comes from the supervisor's grades (0-100) on the student's reports:
--   monthly reports: the average of their grades is worth 20 points
--   final report:    its grade is worth 20 points
-- A report is graded when the academic supervisor approves it.

alter table public.academic_report_reviews add column if not exists grade numeric(5,2);
alter table public.academic_report_reviews drop constraint if exists academic_report_reviews_grade_check;
alter table public.academic_report_reviews add constraint academic_report_reviews_grade_check check (grade is null or (grade >= 0 and grade <= 100));

create or replace function public.academic_report_reviews_grade_guard()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status <> 'approved' then
    new.grade := null;  -- only an approved report carries a grade
  elsif new.grade is null
        and (tg_op = 'INSERT' or old.status is distinct from 'approved' or old.grade is distinct from new.grade) then
    raise exception 'Give the report a grade from 0 to 100 when approving it.';
  end if;
  return new;
end;
$$;

drop trigger if exists academic_report_reviews_grade_guard on public.academic_report_reviews;
create trigger academic_report_reviews_grade_guard
  before insert or update on public.academic_report_reviews
  for each row execute function public.academic_report_reviews_grade_guard();

-- One student's grade with its parts. Administrators see every student, an academic supervisor the
-- students assigned to them.
create or replace function public.student_grade_summary(p_student uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_role text := (select current_user_role());
  v_company jsonb;
  v_ev evaluations%rowtype;
  v_ev_name text;
  v_monthly jsonb;
  v_final jsonb;
  v_m_n int;
  v_m_graded int;
  v_m_avg numeric;
  v_f_grade numeric;
  v_f_reports int;
  v_company_pts numeric := 0;
  v_monthly_pts numeric := 0;
  v_final_pts numeric := 0;
begin
  if not (v_role = 'admin' or (v_role = 'academic_supervisor' and is_academic_supervisor_of(p_student))) then
    raise exception 'You cannot see this student''s grade.' using errcode = '42501';
  end if;

  -- company evaluation (the latest one): average of 1-5 -> percent -> 60 points
  select * into v_ev from evaluations where student_id = p_student and type = 'workplace' order by created_at desc limit 1;
  if found then
    select coalesce(nullif(btrim(full_name), ''), email) into v_ev_name from profiles where profile_id = v_ev.supervisor_id;
    v_company_pts := round(coalesce(v_ev.average_score, 0) / 5 * 60, 2);
    v_company := jsonb_build_object('evaluated', true, 'average', v_ev.average_score, 'percent', round(coalesce(v_ev.average_score, 0) / 5 * 100, 1),
                                    'points', v_company_pts, 'scores', v_ev.scores, 'comments', v_ev.comments,
                                    'evaluated_at', v_ev.created_at, 'evaluator', v_ev_name);
  else
    v_company := jsonb_build_object('evaluated', false, 'points', 0);
  end if;

  -- monthly reports
  select count(*), count(*) filter (where ar.status = 'approved' and ar.grade is not null),
         avg(ar.grade) filter (where ar.status = 'approved' and ar.grade is not null)
    into v_m_n, v_m_graded, v_m_avg
    from reports r left join academic_report_reviews ar on ar.report_id = r.report_id
   where r.student_id = p_student and r.type = 'monthly';
  if v_m_avg is not null then
    v_monthly_pts := round(v_m_avg * 0.20, 2);
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('period', r.period_label, 'grade', ar.grade, 'status', coalesce(ar.status, 'submitted'),
                                               'feedback', ar.feedback, 'submitted_at', r.submitted_at) order by r.submitted_at), '[]'::jsonb)
    into v_monthly
    from reports r left join academic_report_reviews ar on ar.report_id = r.report_id
   where r.student_id = p_student and r.type = 'monthly';

  -- final report
  select count(*), max(ar.grade) filter (where ar.status = 'approved')
    into v_f_reports, v_f_grade
    from reports r left join academic_report_reviews ar on ar.report_id = r.report_id
   where r.student_id = p_student and r.type = 'final';
  if v_f_grade is not null then
    v_final_pts := round(v_f_grade * 0.20, 2);
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('period', r.period_label, 'grade', ar.grade, 'status', coalesce(ar.status, 'submitted'),
                                               'feedback', ar.feedback, 'submitted_at', r.submitted_at) order by r.submitted_at), '[]'::jsonb)
    into v_final
    from reports r left join academic_report_reviews ar on ar.report_id = r.report_id
   where r.student_id = p_student and r.type = 'final';

  return jsonb_build_object(
    'student_id', p_student,
    'company', v_company,
    'monthly', jsonb_build_object('reports', v_m_n, 'graded', v_m_graded, 'average', round(v_m_avg, 1), 'points', v_monthly_pts, 'items', v_monthly),
    'final', jsonb_build_object('reports', v_f_reports, 'grade', v_f_grade, 'points', v_final_pts, 'items', v_final),
    'company_points', v_company_pts,
    'academic_points', v_monthly_pts + v_final_pts,
    'total', v_company_pts + v_monthly_pts + v_final_pts,
    'complete', (v_company->>'evaluated')::boolean and v_m_avg is not null and v_f_grade is not null
  );
end;
$$;
revoke all on function public.student_grade_summary(uuid) from public, anon;
grant execute on function public.student_grade_summary(uuid) to authenticated;

-- The students of one intake with their grades (administrators: all; academic supervisors: their own).
create or replace function public.intake_grade_overview(p_intake uuid)
returns table (student_id uuid, full_name text, programme text, internship_status text,
               company_points numeric, academic_points numeric, total numeric, complete boolean)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_role text := (select current_user_role());
begin
  if v_role not in ('admin', 'academic_supervisor') then
    raise exception 'You cannot see this.' using errcode = '42501';
  end if;
  return query
    select s.profile_id, p.full_name, s.programme, st.status,
           (g->>'company_points')::numeric, (g->>'academic_points')::numeric, (g->>'total')::numeric, (g->>'complete')::boolean
      from students s
      join profiles p on p.profile_id = s.profile_id
      left join v_student_internship_status st on st.student_id = s.profile_id
      cross join lateral student_grade_summary(s.profile_id) g
     where s.intake_id = p_intake
       and p.email not like '%@deleted.invalid'
       and (v_role = 'admin' or s.academic_supervisor_id = auth.uid())
     order by p.full_name;
end;
$$;
revoke all on function public.intake_grade_overview(uuid) from public, anon;
grant execute on function public.intake_grade_overview(uuid) to authenticated;

-- The intakes in which the signed-in academic supervisor has students.
create or replace function public.supervisor_intakes()
returns table (intake_id uuid, name text, start_date date, end_date date, student_count bigint)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if (select current_user_role()) is distinct from 'academic_supervisor' then
    raise exception 'You cannot see this.' using errcode = '42501';
  end if;
  return query
    select i.intake_id, i.name, i.start_date, i.end_date, count(s.profile_id)
      from intakes i
      join students s on s.intake_id = i.intake_id and s.academic_supervisor_id = auth.uid()
     group by i.intake_id, i.name, i.start_date, i.end_date
     order by i.start_date desc;
end;
$$;
revoke all on function public.supervisor_intakes() from public, anon;
grant execute on function public.supervisor_intakes() to authenticated;

-- the report view also carries the grade
create or replace view public.v_report_with_reviews
with (security_invoker = true) as
 SELECT r.report_id,
    r.student_id,
    r.type,
    r.period_label,
    r.notes,
    r.storage_path,
    r.file_name,
    r.file_size_bytes,
    r.submitted_at,
    arr.status AS academic_status,
    arr.feedback AS academic_feedback,
    arr.reviewer_id AS academic_reviewer_id,
    arr.reviewed_at AS academic_reviewed_at,
    crr.status AS company_status,
    crr.feedback AS company_feedback,
    crr.reviewer_id AS company_reviewer_id,
    crr.reviewed_at AS company_reviewed_at,
    arr.grade AS academic_grade
   FROM reports r
     LEFT JOIN academic_report_reviews arr ON arr.report_id = r.report_id
     LEFT JOIN company_report_reviews crr ON crr.report_id = r.report_id;
