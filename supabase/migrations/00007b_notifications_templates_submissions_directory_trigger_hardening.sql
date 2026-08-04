-- Task 8's two new trigger functions were left without the execute
-- hardening every other SECURITY DEFINER function in this migration
-- set received. They're trigger-only -- nothing should ever call them
-- directly via RPC, not even `authenticated` (unlike RLS helper
-- functions, which need `authenticated` to keep working). Triggers
-- fire under the function's own security context regardless of the
-- caller's direct execute grants, so revoking all direct access here
-- is safe and strictly tighter than the RLS-helper pattern.

revoke execute on function sync_profile_directory() from public, anon, authenticated;
revoke execute on function sync_profile_directory_from_students() from public, anon, authenticated;
