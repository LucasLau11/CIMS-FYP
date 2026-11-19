-- 00025_candidate_resume_lookup.sql
--
-- Follow-up to 00023: students rows are now only readable by people related
-- to the student. HR's "view resume of a matched candidate" feature needs the
-- resume path of a student who has NOT applied yet (their skills just match
-- an open posting), which a direct `students` read no longer permits.
--
-- This returns ONLY the resume path and filename, and only when the existing
-- can_view_resume() rule (the same one that guards the storage object itself)
-- allows it -- so the profile's phone/DOB/address stay hidden.

create or replace function get_candidate_resume(p_student_id uuid)
returns table (resume_path text, resume_filename text)
language sql stable security definer set search_path = public as $$
  select s.resume_path, s.resume_filename
  from students s
  where s.profile_id = p_student_id
    and can_view_resume(p_student_id);
$$;
revoke execute on function get_candidate_resume(uuid) from public, anon;
grant execute on function get_candidate_resume(uuid) to authenticated;
