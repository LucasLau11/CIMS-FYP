-- 00048: a student gets ONE company evaluation. After the company supervisor submits it the evaluation is closed:
-- a second one is refused (the app shows "Evaluation submitted" instead of the Evaluate button).
-- Evaluations were already append-only (no update / delete policy), so a submitted one can never be changed.

create unique index if not exists evaluations_one_workplace_per_student
  on public.evaluations (student_id) where type = 'workplace';

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
  if exists (select 1 from public.evaluations e where e.student_id = new.student_id and e.type = 'workplace') then
    raise exception 'This student has already been evaluated. The evaluation is closed and cannot be submitted again.';
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
