-- 00029: remove the parent role and its data (step 2 of 2; DESTRUCTIVE).
--
-- Run only after 00028 (which stopped everything depending on parents) and after the app
-- build without the parent role is in use. This permanently deletes:
--   * every parent account (auth user, profile, parents row),
--   * their parent-child links,
--   * the conversations a parent took part in, with all their messages,
--   * notifications addressed to a parent, and every 'parent_link' notification,
-- and drops the parents and parent_child_links tables, the is_approved_parent_of() function,
-- and the 'parent' / 'parent_link' values from the role and notification-type constraints.
--
-- The whole file runs in one transaction: if anything fails, nothing is deleted.

-- 1. Parent accounts and everything that belongs only to them.
create temporary table _parents on commit drop as
  select profile_id from public.profiles where role = 'parent';

create temporary table _parent_convos on commit drop as
  select distinct conversation_id from public.profile_conversations
   where profile_id in (select profile_id from _parents);

delete from public.messages where conversation_id in (select conversation_id from _parent_convos);
delete from public.profile_conversations where conversation_id in (select conversation_id from _parent_convos);
delete from public.conversations where conversation_id in (select conversation_id from _parent_convos);

delete from public.notifications
 where type = 'parent_link' or user_id in (select profile_id from _parents);

delete from public.parent_child_links;
delete from public.parents;
delete from public.profiles where profile_id in (select profile_id from _parents);
delete from auth.users where id in (select profile_id from _parents);

-- 2. Drop the tables and helpers.
drop trigger if exists check_parent_role on public.parents;
drop table if exists public.parent_child_links;
drop table if exists public.parents;
drop function if exists public.trg_check_parent_role();
drop function if exists public.is_approved_parent_of(uuid);

-- 3. Constraints no longer allow the removed values.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
  check (role = any (array['student', 'academic_supervisor', 'company_hr', 'company_supervisor', 'admin']));

alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications
  add constraint notifications_type_check
  check (type = any (array['application', 'report', 'document', 'message', 'evaluation']));

-- 4. Functions that still mentioned parents.
create or replace function public.promote_to_admin(p_target_profile_id uuid)
returns void
language plpgsql
set search_path to 'public'
as $function$
declare
  v_role text;
begin
  if (select current_user_role()) <> 'admin' then
    raise exception 'only an admin can promote a user to admin';
  end if;

  select role into v_role from profiles where profile_id = p_target_profile_id;

  if v_role is null then
    raise exception 'target profile % not found', p_target_profile_id;
  end if;

  if v_role = 'admin' then
    raise exception 'target profile % is already an admin', p_target_profile_id;
  end if;

  case v_role
    when 'student' then
      delete from students where profile_id = p_target_profile_id;
    when 'academic_supervisor' then
      delete from academic_supervisors where profile_id = p_target_profile_id;
    when 'company_hr' then
      delete from company_hr where profile_id = p_target_profile_id;
    when 'company_supervisor' then
      delete from company_supervisors where profile_id = p_target_profile_id;
    else
      raise exception 'unknown role: %', v_role;
  end case;

  update profiles set role = 'admin' where profile_id = p_target_profile_id;

  insert into administrators (profile_id) values (p_target_profile_id);
end;
$function$;

create or replace function public.anonymise_my_account()
returns void
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_placeholder text;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select role into v_role from profiles where profile_id = v_uid;
  if v_role is null then
    raise exception 'no profile found for this account';
  end if;

  if v_role = 'admin' and
     (select count(*) from profiles where role = 'admin' and approval_status = 'approved') <= 1 then
    raise exception 'the last administrator cannot delete their account';
  end if;

  v_placeholder := 'deleted-' || v_uid || '@deleted.invalid';

  update profiles
    set full_name = 'Deleted user', phone = null, date_of_birth = null,
        address_text = null, address_lat = null, address_lng = null,
        avatar_url = null, email = v_placeholder
    where profile_id = v_uid;

  update students
    set programme = null, faculty = null, semester = null, cgpa = null,
        skills = '{}', resume_path = null, resume_filename = null,
        resume_size_bytes = null, resume_uploaded_at = null, student_reg_no = null
    where profile_id = v_uid;

  delete from work_experiences where student_id = v_uid;
  delete from notifications where user_id = v_uid;

  update messages
    set body = '[message removed]', attachment_path = null,
        attachment_file_name = null, attachment_size_bytes = null
    where sender_id = v_uid;

  update auth.users
    set email = v_placeholder, phone = null, raw_user_meta_data = '{}'::jsonb,
        banned_until = '2999-12-31'::timestamptz
    where id = v_uid;
  update auth.identities
    set identity_data = jsonb_build_object('sub', v_uid::text, 'email', v_placeholder)
    where user_id = v_uid;
  delete from auth.sessions where user_id = v_uid;
end;
$function$;
