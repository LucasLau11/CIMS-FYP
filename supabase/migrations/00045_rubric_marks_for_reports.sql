-- 00045: the academic supervisor grades each report with the university's rubric instead of one 0-100 number:
--   progress (monthly) report: submission 0-4 + content 0-6            = 10 marks
--   final report: submission 0-4 + written presentation 0-6
--                 + awareness of business and entrepreneurial opportunities 0-10
--                 + overall content 0-10                                = 30 marks
-- The progress marks of a student are the AVERAGE over their graded progress reports (10 at most), the
-- final report's marks count in full (30 at most): together the 40 of the overall grade. The company
-- supervisor's evaluation is the other 60. (Replaces the 0-100 grade of 00043; `grade` now holds the
-- report's marks, added up from `marks` by the trigger.)

alter table public.academic_report_reviews add column if not exists marks jsonb;
alter table public.academic_report_reviews drop constraint if exists academic_report_reviews_grade_check;
alter table public.academic_report_reviews add constraint academic_report_reviews_grade_check check (grade is null or (grade >= 0 and grade <= 30));

create or replace function public.academic_report_reviews_grade_guard()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_type text;
  v_spec jsonb;
  v_key text;
  v_max int;
  v_val numeric;
  v_total numeric := 0;
begin
  if new.status <> 'approved' then
    new.grade := null;  -- only an approved report carries marks
    new.marks := null;
    return new;
  end if;
  -- unchanged approvals (for example an old one without marks) are left alone
  if tg_op = 'UPDATE' and old.status = 'approved' and old.marks is not distinct from new.marks and old.grade is not distinct from new.grade then
    return new;
  end if;

  select type into v_type from reports where report_id = new.report_id;
  v_spec := case v_type
    when 'final' then '{"submission":4,"written":6,"awareness":10,"content":10}'::jsonb
    else '{"submission":4,"content":6}'::jsonb
  end;
  if new.marks is null then
    raise exception 'Mark every criterion of the report before approving it.';
  end if;
  for v_key, v_max in select key, value::int from jsonb_each_text(v_spec) loop
    v_val := (new.marks->>v_key)::numeric;
    if v_val is null then
      raise exception 'Mark every criterion of the report before approving it (missing: %).', v_key;
    end if;
    if v_val < 0 or v_val > v_max or v_val <> trunc(v_val) then
      raise exception 'The mark for % must be a whole number from 0 to %.', v_key, v_max;
    end if;
    v_total := v_total + v_val;
  end loop;
  new.grade := v_total;
  return new;
end;
$$;

-- The grade summary: progress points = the average of the progress reports' marks (out of 10), final
-- points = the final report's marks (out of 30); each item also carries its marks.
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

  -- progress (monthly) reports: the average of their marks (out of 10)
  select count(*), count(*) filter (where ar.status = 'approved' and ar.grade is not null),
         avg(ar.grade) filter (where ar.status = 'approved' and ar.grade is not null)
    into v_m_n, v_m_graded, v_m_avg
    from reports r left join academic_report_reviews ar on ar.report_id = r.report_id
   where r.student_id = p_student and r.type = 'monthly';
  if v_m_avg is not null then
    v_monthly_pts := round(v_m_avg, 2);
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('period', r.period_label, 'grade', ar.grade, 'marks', ar.marks, 'status', coalesce(ar.status, 'submitted'),
                                               'feedback', ar.feedback, 'submitted_at', r.submitted_at) order by r.submitted_at), '[]'::jsonb)
    into v_monthly
    from reports r left join academic_report_reviews ar on ar.report_id = r.report_id
   where r.student_id = p_student and r.type = 'monthly';

  -- final report (out of 30)
  select count(*), max(ar.grade) filter (where ar.status = 'approved')
    into v_f_reports, v_f_grade
    from reports r left join academic_report_reviews ar on ar.report_id = r.report_id
   where r.student_id = p_student and r.type = 'final';
  if v_f_grade is not null then
    v_final_pts := round(v_f_grade, 2);
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('period', r.period_label, 'grade', ar.grade, 'marks', ar.marks, 'status', coalesce(ar.status, 'submitted'),
                                               'feedback', ar.feedback, 'submitted_at', r.submitted_at) order by r.submitted_at), '[]'::jsonb)
    into v_final
    from reports r left join academic_report_reviews ar on ar.report_id = r.report_id
   where r.student_id = p_student and r.type = 'final';

  return jsonb_build_object(
    'student_id', p_student,
    'company', v_company,
    'monthly', jsonb_build_object('reports', v_m_n, 'graded', v_m_graded, 'average', round(v_m_avg, 2), 'points', v_monthly_pts, 'max', 10, 'items', v_monthly),
    'final', jsonb_build_object('reports', v_f_reports, 'grade', v_f_grade, 'points', v_final_pts, 'max', 30, 'items', v_final),
    'company_points', v_company_pts,
    'academic_points', v_monthly_pts + v_final_pts,
    'total', v_company_pts + v_monthly_pts + v_final_pts,
    'complete', (v_company->>'evaluated')::boolean and v_m_avg is not null and v_f_grade is not null
  );
end;
$$;
revoke all on function public.student_grade_summary(uuid) from public, anon;
grant execute on function public.student_grade_summary(uuid) to authenticated;
