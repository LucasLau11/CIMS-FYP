-- 00030: let people see the profile of whoever they are chatting with.
--
-- The chat "contact info" screen called get_chat_contact_info(), but the function was never
-- created, so it always came back empty (no phone, no details). It now exists. It returns the
-- other person's profile card: name, role, photo, email, phone, and the details that make sense
-- for their role (programme / faculty / skills for a student, company for HR and company
-- supervisors). It only answers for someone the caller already shares a conversation with
-- (admins may look anyone up), and it hides the placeholder contact details of a deleted account.

create or replace function public.get_chat_contact_info(other_user_id uuid)
returns table (
  profile_id uuid,
  full_name text,
  role text,
  avatar_url text,
  email text,
  phone text,
  programme text,
  faculty text,
  semester int,
  skills text[],
  company_name text,
  company_industry text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not (select is_approved_user()) then
    raise exception 'You must be signed in.';
  end if;

  if (select current_user_role()) is distinct from 'admin' and not exists (
       select 1
         from profile_conversations a
         join profile_conversations b using (conversation_id)
        where a.profile_id = auth.uid() and b.profile_id = other_user_id) then
    raise exception 'You can only view the profile of someone you are chatting with.';
  end if;

  return query
  select p.profile_id,
         p.full_name,
         p.role,
         p.avatar_url,
         case when p.email like '%@deleted.invalid' then null else p.email end,
         p.phone,
         s.programme,
         s.faculty,
         s.semester::int,
         s.skills,
         co.name,
         co.industry
    from profiles p
    left join students s on s.profile_id = p.profile_id
    left join companies co on co.company_id = coalesce(
           (select h.company_id from company_hr h where h.profile_id = p.profile_id),
           (select cs.company_id from company_supervisors cs where cs.profile_id = p.profile_id))
   where p.profile_id = other_user_id;
end;
$$;

revoke all on function public.get_chat_contact_info(uuid) from public, anon;
grant execute on function public.get_chat_contact_info(uuid) to authenticated;
