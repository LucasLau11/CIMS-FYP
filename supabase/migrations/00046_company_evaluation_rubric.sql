-- 00046: the company supervisor evaluates the trainee with the university's company assessment form:
--   10 criteria marked 0-6 each (0 / 1-2 / 3 / 4-5 / 6)                = 60 marks (the company's 60% of the grade)
--   attendance (days absent with and without permission), an overall grade (A, B+, B, C, F),
--   other comments, and a few words about the training the student underwent.
-- Evaluations written before this (average of five 1-5 sliders) still count: average / 5 x 60.

alter table public.evaluations add column if not exists marks_total smallint;
alter table public.evaluations add column if not exists attendance_with_permission int;
alter table public.evaluations add column if not exists attendance_without_permission int;
alter table public.evaluations add column if not exists overall_grade text;
alter table public.evaluations add column if not exists training_notes text;
alter table public.evaluations add column if not exists designation text;

alter table public.evaluations drop constraint if exists evaluations_overall_grade_check;
alter table public.evaluations add constraint evaluations_overall_grade_check check (overall_grade is null or overall_grade in ('A', 'B+', 'B', 'C', 'F'));
alter table public.evaluations drop constraint if exists evaluations_attendance_check;
alter table public.evaluations add constraint evaluations_attendance_check check (
  (attendance_with_permission is null or attendance_with_permission between 0 and 400)
  and (attendance_without_permission is null or attendance_without_permission between 0 and 400));

create or replace function public.evaluations_workplace_guard()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_key text;
  v_val numeric;
  v_total numeric := 0;
begin
  if new.type <> 'workplace' then
    return new;
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
drop trigger if exists evaluations_workplace_guard on public.evaluations;
create trigger evaluations_workplace_guard before insert on public.evaluations
  for each row execute function public.evaluations_workplace_guard();

-- the grade summary counts the rubric marks (or the old average) as the company's points
do $$
declare
  d text := pg_get_functiondef('public.student_grade_summary(uuid)'::regprocedure);
  old_part text := E'    v_company_pts := round(coalesce(v_ev.average_score, 0) / 5 * 60, 2);\n    v_company := jsonb_build_object(''evaluated'', true, ''average'', v_ev.average_score, ''percent'', round(coalesce(v_ev.average_score, 0) / 5 * 100, 1),\n                                    ''points'', v_company_pts, ''scores'', v_ev.scores, ''comments'', v_ev.comments,\n                                    ''evaluated_at'', v_ev.created_at, ''evaluator'', v_ev_name);';
  new_part text := E'    if v_ev.marks_total is not null then\n      v_company_pts := v_ev.marks_total;\n    else\n      v_company_pts := round(coalesce(v_ev.average_score, 0) / 5 * 60, 2);\n    end if;\n    v_company := jsonb_build_object(''evaluated'', true, ''rubric'', v_ev.marks_total is not null, ''average'', v_ev.average_score,\n                                    ''percent'', round(v_company_pts / 60 * 100, 1), ''points'', v_company_pts, ''scores'', v_ev.scores,\n                                    ''comments'', v_ev.comments, ''attendance_with'', v_ev.attendance_with_permission,\n                                    ''attendance_without'', v_ev.attendance_without_permission, ''overall_grade'', v_ev.overall_grade,\n                                    ''training_notes'', v_ev.training_notes, ''designation'', v_ev.designation,\n                                    ''evaluated_at'', v_ev.created_at, ''evaluator'', v_ev_name);';
begin
  if position(old_part in d) = 0 then
    raise exception 'student_grade_summary has an unexpected shape';
  end if;
  execute replace(d, old_part, new_part);
end $$;
