-- 00026: mandatory rejection reason + one accepted offer per student.
--
-- Application life cycle after this migration:
--
--   pending ──> interview ──> offered ──> active          (student accepts)
--      │            │            │
--      └────────────┴────────────┴──> rejected            (HR; reason required)
--
--   pending / interview / offered ──> unavailable         (set automatically when the
--                                                         student accepts a different offer)
--
-- 'active' keeps its old meaning everywhere else in the app: the student is a confirmed
-- intern at that company. What changes is who gets to say so. HR can now only *offer*;
-- the student confirms by calling accept_offer(), which closes every other open application.

-- ---------------------------------------------------------------------------------------
-- 1. Columns and constraints
-- ---------------------------------------------------------------------------------------
alter table public.applications add column if not exists rejection_reason text;

-- The one existing rejected row predates the rule. Give it an honest placeholder rather than
-- weakening the constraint.
update public.applications
   set rejection_reason = 'No reason was recorded (rejected before reasons were required).'
 where status = 'rejected' and rejection_reason is null;

alter table public.applications drop constraint if exists applications_status_check;
alter table public.applications
  add constraint applications_status_check
  check (status = any (array['pending','interview','offered','active','rejected','unavailable']));

alter table public.applications
  add constraint applications_rejection_reason_check
  check (
    (status = 'rejected' and char_length(btrim(coalesce(rejection_reason, ''))) between 10 and 500)
    or (status <> 'rejected' and rejection_reason is null)
  );

-- Test data: one student was marked active at three postings. Keep the most recently updated
-- one and close the rest so the one-active rule below can be created.
with ranked as (
  select application_id,
         row_number() over (partition by student_id order by updated_at desc, applied_at desc) as rn
    from public.applications
   where status = 'active'
)
update public.applications a
   set status = 'unavailable', updated_at = now()
  from ranked r
 where a.application_id = r.application_id and r.rn > 1;

create unique index if not exists applications_one_active_per_student
  on public.applications (student_id) where status = 'active';

-- ---------------------------------------------------------------------------------------
-- 2. Guard: who may do what to an application through the API
-- ---------------------------------------------------------------------------------------
-- The old UPDATE policy let the student (and any company supervisor) write any column, so a
-- student could simply set their own application to 'active'. RLS cannot express "this
-- column, only to those values", so a trigger does. It only restricts API callers
-- (authenticated/anon); migrations and the SECURITY DEFINER functions below run as the
-- function owner and pass straight through.
create or replace function public.applications_guard()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_role text;
begin
  if current_user not in ('authenticated', 'anon') then
    return coalesce(new, old);
  end if;

  v_role := (select current_user_role());

  if tg_op = 'INSERT' then
    if new.status <> 'pending' then
      raise exception 'A new application must start as pending.';
    end if;
    new.rejection_reason := null;
    if exists (select 1 from applications where student_id = new.student_id and status = 'active') then
      raise exception 'You have already accepted an internship offer, so you cannot apply to other postings.';
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    if v_role = 'admin' then
      return old;
    end if;
    if old.status <> 'pending' then
      raise exception 'Only a pending application can be withdrawn.';
    end if;
    return old;
  end if;

  -- UPDATE
  if v_role = 'admin' then
    return new;
  end if;

  if new.student_id is distinct from old.student_id
     or new.job_posting_id is distinct from old.job_posting_id
     or new.cover_letter is distinct from old.cover_letter
     or new.skills is distinct from old.skills
     or new.applied_at is distinct from old.applied_at then
    raise exception 'The details of an application cannot be changed.';
  end if;

  if new.status is distinct from old.status then
    if v_role is distinct from 'company_hr' then
      raise exception 'Only the company''s HR can change the status of an application.';
    end if;
    if not (
      (old.status = 'pending'   and new.status in ('interview', 'offered', 'rejected'))
      or (old.status = 'interview' and new.status in ('offered', 'rejected'))
      or (old.status = 'offered'   and new.status = 'rejected')
    ) then
      raise exception 'An application cannot move from % to %.', old.status, new.status;
    end if;
    if new.status = 'rejected' and char_length(btrim(coalesce(new.rejection_reason, ''))) < 10 then
      raise exception 'Please give a reason of at least 10 characters when rejecting an application.';
    end if;
    if new.status <> 'rejected' then
      new.rejection_reason := null;
    end if;
  elsif new.rejection_reason is distinct from old.rejection_reason then
    raise exception 'The rejection reason cannot be changed after the application was rejected.';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists applications_guard on public.applications;
create trigger applications_guard
  before insert or update or delete on public.applications
  for each row execute function public.applications_guard();

-- ---------------------------------------------------------------------------------------
-- 3. accept_offer: the student's one atomic "yes"
-- ---------------------------------------------------------------------------------------
create or replace function public.accept_offer(p_application_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid  uuid := auth.uid();
  v_app  applications%rowtype;
  v_name text;
begin
  if v_uid is null or (select current_user_role()) is distinct from 'student' then
    raise exception 'Only a signed-in student can accept an offer.';
  end if;

  -- Lock every application this student has, so two taps or two devices cannot both win.
  perform 1 from applications where student_id = v_uid for update;

  select * into v_app from applications
   where application_id = p_application_id and student_id = v_uid;
  if not found then
    raise exception 'That application was not found.';
  end if;
  if v_app.status = 'active' then
    raise exception 'You have already accepted this offer.';
  end if;
  if v_app.status <> 'offered' then
    raise exception 'This application does not have an offer you can accept.';
  end if;
  if exists (select 1 from applications where student_id = v_uid and status = 'active') then
    raise exception 'You have already accepted another offer. Only one internship can be active.';
  end if;

  select full_name into v_name from profiles where profile_id = v_uid;

  update applications set status = 'active', updated_at = now()
   where application_id = p_application_id;

  -- Tell the company whose offer was accepted.
  insert into notifications (user_id, title, body, type, related_id)
  select h.profile_id,
         'Offer accepted',
         coalesce(nullif(btrim(v_name), ''), 'A student') || ' accepted your offer for ' || jp.title || '.',
         'application',
         v_app.application_id
    from job_postings jp
    join company_hr h on h.company_id = jp.company_id
   where jp.job_posting_id = v_app.job_posting_id;

  -- Close everything else that was still open, and tell those companies.
  with closed as (
    update applications set status = 'unavailable', updated_at = now()
     where student_id = v_uid
       and application_id <> p_application_id
       and status in ('pending', 'interview', 'offered')
    returning application_id, job_posting_id
  )
  insert into notifications (user_id, title, body, type, related_id)
  select h.profile_id,
         'Candidate no longer available',
         coalesce(nullif(btrim(v_name), ''), 'A student') || ' accepted another offer, so their application for '
           || jp.title || ' has been closed.',
         'application',
         c.application_id
    from closed c
    join job_postings jp on jp.job_posting_id = c.job_posting_id
    join company_hr h on h.company_id = jp.company_id;
end;
$$;

revoke all on function public.accept_offer(uuid) from public, anon;
grant execute on function public.accept_offer(uuid) to authenticated;
