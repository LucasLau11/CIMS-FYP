-- Task 19's live testing confirmed parent_child_links has no DELETE policy
-- at all -- ParentDataService.cancelLinkRequest() silently no-ops (the
-- UI shows success, the pending link request row remains). A parent
-- should be able to cancel their own still-pending request; once a
-- student has responded (approved/rejected), the record becomes the
-- consent/audit trail and shouldn't be deletable by either side, so this
-- is scoped to pending rows only, by the requesting parent.
create policy parent_child_links_delete_own_pending on parent_child_links for delete to authenticated
  using (parent_id = (select auth.uid()) and status = 'pending');
