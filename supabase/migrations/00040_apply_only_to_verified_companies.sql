-- 00040: students can see postings of a company that is still waiting for verification, but cannot
-- apply to them. The app already greyed the button out; this makes the database refuse it too, so
-- the rule cannot be bypassed by calling the API directly.

create or replace function public.applications_guard()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
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
    if not exists (
         select 1 from job_postings jp
          where jp.job_posting_id = new.job_posting_id
            and jp.status = 'open'
            and not posting_has_expired(jp.application_deadline, jp.posting_closes_at)) then
      raise exception 'This posting is closed and no longer accepts applications.';
    end if;
    if not exists (
         select 1 from job_postings jp
           join companies c on c.company_id = jp.company_id
          where jp.job_posting_id = new.job_posting_id
            and c.status = 'verified') then
      raise exception 'This company has not been verified yet, so you cannot apply to its postings.';
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
$function$;
