-- CRITICAL fix from Task 8's review: notifications_insert_system used
-- `with check (true)` -- any authenticated user could insert a
-- notification row targeting ANY other user_id with arbitrary
-- title/body/type/related_id. The plan's own Task 11 documents a
-- Database Webhook on notifications INSERT that fires a real push
-- notification (OneSignal), so this was a live, exploitable spoofing
-- vector with a confirmed delivery path, not a theoretical one.
--
-- A strict "self-notify only" check was considered and rejected: this
-- app's real notification pattern is almost always someone OTHER than
-- the recipient creating the row (HR notifying a student of an
-- interview, a supervisor notifying a student of a report review,
-- etc.), so self = target would block legitimate use.
--
-- Instead, can_notify() ties notification-creation authority to the
-- SAME relationship checks already built and independently reviewed
-- for the corresponding domain action in Tasks 3-8, keyed by
-- notifications.type: academic supervision (report/document/evaluation),
-- company-via-application (application/report/evaluation), parent-child
-- links (parent_link), and conversation membership (message). This is a
-- new design decision made in response to the review finding -- not
-- specified in the original plan -- and should be treated as
-- provisional: confirm it matches every real notification call site
-- once the service layer (Tasks 13-20) actually wires up notification
-- sends, and revisit if a legitimate flow turns out to be blocked.

create or replace function can_notify(p_user_id uuid, p_type text) returns boolean
language sql stable security definer set search_path = public as $$
  select
    p_user_id = (select auth.uid())
    or (select current_user_role()) = 'admin'
    or case p_type
      when 'application' then
        exists (select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
                 where a.student_id = p_user_id and is_my_company(jp.company_id))
      when 'report' then
        is_academic_supervisor_of(p_user_id)
        or exists (select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
                    where a.student_id = p_user_id and is_my_company(jp.company_id))
      when 'document' then
        is_academic_supervisor_of(p_user_id)
      when 'evaluation' then
        is_academic_supervisor_of(p_user_id)
        or exists (select 1 from applications a join job_postings jp on jp.job_posting_id = a.job_posting_id
                    where a.student_id = p_user_id and is_my_company(jp.company_id))
      when 'parent_link' then
        is_approved_parent_of(p_user_id)
        or exists (select 1 from parent_child_links where parent_id = p_user_id and student_id = (select auth.uid()))
        or exists (select 1 from parent_child_links where student_id = p_user_id and parent_id = (select auth.uid()))
      when 'message' then
        exists (
          select 1 from profile_conversations pc1
          join profile_conversations pc2 using (conversation_id)
          where pc1.profile_id = (select auth.uid()) and pc2.profile_id = p_user_id
        )
      else false
    end;
$$;

revoke execute on function can_notify(uuid, text) from public, anon;
grant execute on function can_notify(uuid, text) to authenticated;

drop policy if exists notifications_insert_system on notifications;
create policy notifications_insert_authorized on notifications for insert to authenticated
  with check (can_notify(user_id, type));
