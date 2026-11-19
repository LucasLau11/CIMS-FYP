-- 00054: the number of monthly reports a student must submit follows the length of their intake.
--   a 3-month intake needs 3 monthly reports, a 6-month intake needs 6 (months = days between the intake's start and
--   end dates / 30.44, rounded, at least 1). A student without an intake has no fixed number.
--   * a student cannot submit more monthly reports than the intake needs (a report rejected by the company or the
--     academic supervisor does not count, so it can be sent again);
--   * the student's grade is complete only when every required monthly report is graded;
--   * my_report_requirements() tells the student's screen how many are required and how many are in.

create or replace function public.intake_months(p_start date, p_end date)
returns int
language sql
immutable
as $$
  select greatest(1, round((p_end - p_start) / 30.4375)::int);
$$;

create or replace function public.required_monthly_reports(p_student uuid)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select public.intake_months(i.start_date, i.end_date)
    from students s join intakes i on i.intake_id = s.intake_id
   where s.profile_id = p_student;
$$;
revoke all on function public.required_monthly_reports(uuid) from public, anon;
grant execute on function public.required_monthly_reports(uuid) to authenticated;

-- monthly reports of a student that still count (not rejected by either supervisor)
create or replace function public.counted_monthly_reports(p_student uuid)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::int
    from reports r
    left join academic_report_reviews ar on ar.report_id = r.report_id
    left join company_report_reviews cr on cr.report_id = r.report_id
   where r.student_id = p_student and r.type = 'monthly'
     and coalesce(ar.status, 'submitted') <> 'rejected'
     and coalesce(cr.status, 'submitted') <> 'rejected';
$$;
revoke all on function public.counted_monthly_reports(uuid) from public, anon;
grant execute on function public.counted_monthly_reports(uuid) to authenticated;

create or replace function public.my_report_requirements()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_intake text;
  v_months int;
  v_submitted int;
  v_final boolean;
begin
  if v_uid is null then
    raise exception 'You must be logged in.';
  end if;
  select i.name, public.intake_months(i.start_date, i.end_date) into v_intake, v_months
    from students s join intakes i on i.intake_id = s.intake_id
   where s.profile_id = v_uid;
  v_submitted := public.counted_monthly_reports(v_uid);
  select exists (select 1 from reports r left join academic_report_reviews ar on ar.report_id = r.report_id
                  where r.student_id = v_uid and r.type = 'final' and coalesce(ar.status, 'submitted') <> 'rejected') into v_final;
  return jsonb_build_object('intake', v_intake, 'required', v_months, 'submitted', v_submitted, 'has_final', v_final);
end;
$$;
revoke all on function public.my_report_requirements() from public, anon;
grant execute on function public.my_report_requirements() to authenticated;

create or replace function public.reports_requirements_guard()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_required int;
begin
  if new.type = 'monthly' then
    v_required := public.required_monthly_reports(new.student_id);
    if v_required is not null and public.counted_monthly_reports(new.student_id) >= v_required then
      raise exception 'You have already submitted all % monthly reports your intake needs.', v_required;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists reports_requirements_guard on public.reports;
create trigger reports_requirements_guard before insert on public.reports
  for each row execute function public.reports_requirements_guard();

-- the grade is complete only when every required monthly report is graded
do $$
declare
  d text := pg_get_functiondef('public.student_grade_summary(uuid)'::regprocedure);
  d1 text;
  d2 text;
  d3 text;
begin
  d1 := replace(d, E'  v_final_pts numeric := 0;\nbegin', E'  v_final_pts numeric := 0;\n  v_req int := public.required_monthly_reports(p_student);\nbegin');
  d2 := replace(d1, E'''monthly'', jsonb_build_object(''reports'', v_m_n,', E'''monthly'', jsonb_build_object(''required'', v_req, ''reports'', v_m_n,');
  d3 := replace(d2, E'''complete'', (v_company->>''evaluated'')::boolean and v_m_avg is not null and v_f_grade is not null',
                    E'''complete'', (v_company->>''evaluated'')::boolean and v_m_avg is not null and v_m_graded >= coalesce(v_req, 1) and v_f_grade is not null');
  if d3 = d or d1 = d or d2 = d1 or d3 = d2 then
    raise exception 'student_grade_summary has an unexpected shape';
  end if;
  execute d3;
end $$;
