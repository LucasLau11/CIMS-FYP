-- 00033: private shortlist flag and notes that company HR keep on an applicant.
--
-- Only company HR of the posting's company can read or write a row. Students,
-- company supervisors, academic supervisors and admins never see it: it is HR's own
-- working note, not part of the application.

create table if not exists public.application_notes (
  application_id uuid primary key references public.applications(application_id) on delete cascade,
  shortlisted    boolean not null default false,
  note           text,
  updated_by     uuid references public.profiles(profile_id) on delete set null,
  updated_at     timestamptz not null default now(),
  constraint application_notes_note_length check (note is null or char_length(note) <= 2000)
);

alter table public.application_notes enable row level security;

create or replace function public.is_hr_of_application(p_application_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select (select is_approved_user()) and exists (
    select 1
      from applications a
      join job_postings jp on jp.job_posting_id = a.job_posting_id
      join company_hr h on h.company_id = jp.company_id
     where a.application_id = p_application_id
       and h.profile_id = (select auth.uid()));
$$;

revoke all on function public.is_hr_of_application(uuid) from public, anon;
grant execute on function public.is_hr_of_application(uuid) to authenticated;

create policy application_notes_select_hr on public.application_notes
  for select to authenticated using (is_hr_of_application(application_id));
create policy application_notes_insert_hr on public.application_notes
  for insert to authenticated with check (is_hr_of_application(application_id));
create policy application_notes_update_hr on public.application_notes
  for update to authenticated using (is_hr_of_application(application_id)) with check (is_hr_of_application(application_id));
create policy application_notes_delete_hr on public.application_notes
  for delete to authenticated using (is_hr_of_application(application_id));

create or replace function public.application_notes_stamp()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_by := auth.uid();
  new.updated_at := now();
  return new;
end;
$$;

create trigger application_notes_stamp
  before insert or update on public.application_notes
  for each row execute function public.application_notes_stamp();
