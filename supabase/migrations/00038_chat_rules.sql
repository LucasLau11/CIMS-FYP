-- 00038: who may START a conversation with whom, enforced in the database.
--
-- Rules (the caller's role -> who they can start a chat with):
--   admin               anyone
--   academic supervisor their assigned students, and the company supervisors of the companies
--                       where those students are placed (an 'active' application)
--   company HR          any student, and the company supervisors of their own company
--   student             any company HR, their academic supervisor, and the company supervisors of
--                       the company where they are placed
--   company supervisor  the students placed at their company, those students' academic
--                       supervisors, and the HR of their own company
-- Anyone can always keep writing in a conversation that already exists. Accounts that are not
-- approved, or that were deleted, can never be started a chat with.
--
-- Before this, the rule lived only in the app and the tables allowed anyone to insert
-- conversation rows. Now the tables cannot be inserted into directly: conversations are created
-- by start_conversation(), which checks can_message().

create or replace function public.can_message(p_target uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text := (select current_user_role());
  v_trole text;
  v_ok boolean;
  v_email text;
  v_company uuid;
begin
  if v_uid is null or v_role is null or p_target is null or p_target = v_uid then
    return false;
  end if;

  select role, approval_status = 'approved', email into v_trole, v_ok, v_email from profiles where profile_id = p_target;
  if v_trole is null or not coalesce(v_ok, false) or v_email like '%@deleted.invalid' then
    return false;
  end if;

  if v_role = 'admin' then
    return true;
  end if;

  if v_role = 'academic_supervisor' then
    if v_trole = 'student' then
      return exists (select 1 from students where profile_id = p_target and academic_supervisor_id = v_uid);
    elsif v_trole = 'company_supervisor' then
      return exists (
        select 1
          from company_supervisors cs
         where cs.profile_id = p_target
           and exists (select 1
                         from applications a
                         join job_postings jp on jp.job_posting_id = a.job_posting_id
                         join students s on s.profile_id = a.student_id
                        where a.status = 'active' and s.academic_supervisor_id = v_uid and jp.company_id = cs.company_id));
    end if;
    return false;
  end if;

  if v_role = 'company_hr' then
    if v_trole = 'student' then
      return true;
    elsif v_trole = 'company_supervisor' then
      select company_id into v_company from company_hr where profile_id = v_uid;
      return v_company is not null and exists (select 1 from company_supervisors where profile_id = p_target and company_id = v_company);
    end if;
    return false;
  end if;

  if v_role = 'student' then
    if v_trole = 'company_hr' then
      return true;
    elsif v_trole = 'academic_supervisor' then
      return exists (select 1 from students where profile_id = v_uid and academic_supervisor_id = p_target);
    elsif v_trole = 'company_supervisor' then
      return exists (
        select 1
          from company_supervisors cs
         where cs.profile_id = p_target
           and exists (select 1
                         from applications a
                         join job_postings jp on jp.job_posting_id = a.job_posting_id
                        where a.student_id = v_uid and a.status = 'active' and jp.company_id = cs.company_id));
    end if;
    return false;
  end if;

  if v_role = 'company_supervisor' then
    select company_id into v_company from company_supervisors where profile_id = v_uid;
    if v_company is null then
      return false;
    end if;
    if v_trole = 'student' then
      return exists (select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
                      where a.student_id = p_target and a.status = 'active' and jp.company_id = v_company);
    elsif v_trole = 'academic_supervisor' then
      return exists (select 1
                       from applications a
                       join job_postings jp on jp.job_posting_id = a.job_posting_id
                       join students s on s.profile_id = a.student_id
                      where a.status = 'active' and jp.company_id = v_company and s.academic_supervisor_id = p_target);
    elsif v_trole = 'company_hr' then
      return exists (select 1 from company_hr where profile_id = p_target and company_id = v_company);
    end if;
    return false;
  end if;

  return false;
end;
$$;

revoke all on function public.can_message(uuid) from public, anon;
grant execute on function public.can_message(uuid) to authenticated;

-- The people the signed-in user may start a chat with (what the "new message" list shows).
create or replace function public.messageable_profile_ids()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select pd.profile_id from profile_directory pd where can_message(pd.profile_id);
$$;

revoke all on function public.messageable_profile_ids() from public, anon;
grant execute on function public.messageable_profile_ids() to authenticated;

-- Opens the conversation with someone, creating it when allowed. An existing conversation is
-- always returned (so replying never depends on these rules); a new one needs can_message().
create or replace function public.start_conversation(p_other uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  if v_uid is null or not (select is_approved_user()) then
    raise exception 'You must be signed in.';
  end if;
  if p_other is null or p_other = v_uid then
    raise exception 'Choose someone else to message.';
  end if;

  select a.conversation_id into v_id
    from profile_conversations a
    join profile_conversations b on b.conversation_id = a.conversation_id
   where a.profile_id = v_uid and b.profile_id = p_other
   limit 1;
  if v_id is not null then
    return v_id;
  end if;

  if not can_message(p_other) then
    raise exception 'You cannot start a conversation with this person. You can reply once they message you.';
  end if;

  insert into conversations default values returning conversation_id into v_id;
  insert into profile_conversations (conversation_id, profile_id) values (v_id, v_uid), (v_id, p_other);
  return v_id;
end;
$$;

revoke all on function public.start_conversation(uuid) from public, anon;
grant execute on function public.start_conversation(uuid) to authenticated;

-- No more direct inserts from the app: every new conversation goes through start_conversation().
drop policy if exists conversations_insert_authenticated on public.conversations;
drop policy if exists profile_conversations_insert_self_or_existing_member on public.profile_conversations;
