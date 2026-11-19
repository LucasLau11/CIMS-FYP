-- 00056: the intake grade list also returns what a downloaded spreadsheet needs: the registration number, the marks of the
-- monthly reports and the final report, how many monthly reports are graded of how many are required, and the overall
-- grade (A, B+, B, C, F) the company gave. The first eight columns are unchanged, so the screens that read the list keep working.

drop function if exists public.intake_grade_overview(uuid);

create function public.intake_grade_overview(p_intake uuid)
returns table (student_id uuid, full_name text, programme text, internship_status text,
               company_points numeric, academic_points numeric, total numeric, complete boolean,
               student_reg_no text, monthly_points numeric, final_points numeric,
               monthly_graded int, monthly_required int, overall_grade text)
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
           (g->>'company_points')::numeric, (g->>'academic_points')::numeric, (g->>'total')::numeric, (g->>'complete')::boolean,
           s.student_reg_no, (g->'monthly'->>'points')::numeric, (g->'final'->>'points')::numeric,
           (g->'monthly'->>'graded')::int, (g->'monthly'->>'required')::int, g->'company'->>'overall_grade'
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
