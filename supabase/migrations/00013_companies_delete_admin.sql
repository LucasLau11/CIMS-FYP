-- Task 17's live testing confirmed companies has no DELETE policy at all
-- (only insert/select/update) -- admin_data_service.dart's deleteCompany()
-- silently no-ops: the UI shows success (no exception) but the row remains.
-- Mirrors the admin-only delete pattern used for the 6 profile subtype
-- tables in migration 00012.
create policy companies_delete_admin on companies for delete to authenticated
  using ((select current_user_role()) = 'admin');
