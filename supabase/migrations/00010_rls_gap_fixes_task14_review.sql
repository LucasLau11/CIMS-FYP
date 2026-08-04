-- Task 14's live RLS-impersonation testing surfaced several pre-existing
-- gaps from earlier tasks' migrations (2-9) -- correct application-layer
-- code silently failing because the RLS policy set never granted the
-- operation it needs. None of these were fixable from student_data_service.dart's
-- Dart-only scope, so they're closed here as a dedicated follow-up before
-- Tasks 15-20 (the remaining service rewrites) all inherit the same gaps
-- through messaging/reports/documents, which every role's service touches.

-- CRITICAL: starting a new conversation could never add the other
-- participant. profile_conversations_insert_self only allowed
-- `profile_id = auth.uid()`, so the second of the two inserts in
-- getOrCreateConversation() (add the other party) was always RLS-denied --
-- breaking "start new chat" for every role.
--
-- Fix: allow inserting someone ELSE's membership row only when the caller
-- is ALREADY a member of that same conversation. This covers the real
-- bootstrap sequence (insert your own row first, then the other party's --
-- by the second insert you're already a member) without a blanket
-- `with check (true)`, which would let any authenticated user self-join an
-- arbitrary conversation_id they merely learned of (a meaningful privacy
-- regression `is_conversation_member`-gated reads are supposed to prevent).
-- A member-only "add others" grant also generalizes correctly if group
-- conversations are ever added -- existing members can add people,
-- non-members can never bootstrap membership for themselves via this path.
drop policy if exists profile_conversations_insert_self on profile_conversations;
create policy profile_conversations_insert_self_or_existing_member on profile_conversations for insert to authenticated
  with check (
    profile_id = (select auth.uid())
    or exists (
      select 1 from profile_conversations pc
      where pc.conversation_id = profile_conversations.conversation_id
        and pc.profile_id = (select auth.uid())
    )
  );

-- HIGH: reports had no UPDATE policy at all. submitReport()'s two-step
-- flow (insert bare row, upload file, then update the row with
-- storage_path/file_name/file_size_bytes) silently no-ops on the last
-- step -- the file uploads, but the report row never links to it, so
-- "view attachment" never appears. Self-update only, mirroring
-- reports_insert_own's actor (the report's own author); admin included
-- for consistency with every other table's admin-override pattern in
-- this migration set.
create policy reports_update_own on reports for update to authenticated
  using (student_id = (select auth.uid()) or (select current_user_role()) = 'admin')
  with check (student_id = (select auth.uid()) or (select current_user_role()) = 'admin');

-- MEDIUM: applications/conversations/messages/documents had table-level
-- DELETE grants (so the calls didn't error) but zero DELETE policies, so
-- RLS silently filtered every delete to 0 rows affected -- withdraw/delete
-- actions appeared to succeed client-side but never removed anything.
create policy applications_delete_own on applications for delete to authenticated
  using (student_id = (select auth.uid()) or (select current_user_role()) = 'admin');

create policy conversations_delete_member on conversations for delete to authenticated
  using (is_conversation_member(conversation_id));

create policy messages_delete_sender on messages for delete to authenticated
  using (sender_id = (select auth.uid()) or (select current_user_role()) = 'admin');

create policy documents_delete_own on documents for delete to authenticated
  using (student_id = (select auth.uid()) or (select current_user_role()) = 'admin');

-- LOW: applyToInternship()'s existing PostgrestException handling for
-- e.code == '23505' (unique violation -> "already applied") was dead code
-- since no unique constraint enforced it -- duplicate applications were
-- silently possible. Restores the constraint the Dart code already
-- expected; the (student_id, job_posting_id) pair is the natural key for
-- "has this student applied to this posting."
alter table applications add constraint applications_student_job_posting_unique unique (student_id, job_posting_id);
