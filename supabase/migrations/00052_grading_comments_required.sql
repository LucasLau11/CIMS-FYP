-- 00052: the comment is compulsory in both gradings (at least 10 characters):
--   * the academic supervisor's (or an administrator's) approval of a report, which carries the rubric marks;
--   * the company supervisor's evaluation of the student ("13. Other comments about this student trainee").
-- Grades and evaluations given before this are left as they are (an unchanged approval is not re-checked).
-- A rejection already needs its own reason and is not affected.

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
  if tg_op = 'UPDATE' and old.status = 'approved' and old.marks is not distinct from new.marks and old.grade is not distinct from new.grade
     and old.feedback is not distinct from new.feedback then
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
  if char_length(btrim(coalesce(new.feedback, ''))) < 10 then
    raise exception 'Write a comment for the student before approving the report (at least 10 characters).';
  end if;
  new.grade := v_total;
  return new;
end;
$$;

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
