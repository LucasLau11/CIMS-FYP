-- Task 10's review flagged public_bucket_allows_listing: avatars_select_public
-- had no `to authenticated` restriction, so an unauthenticated client could
-- call storage.objects .list()/.download() and enumerate every avatar file --
-- and since the avatars path convention is flat {userId}.{ext}
-- (auth_service.dart:229), that's a full enumeration of every registered
-- user's UUID, not just avatar images.
--
-- This does not affect normal avatar display: Supabase serves public-bucket
-- files via getPublicUrl(), which bypasses storage.objects RLS entirely for
-- the actual GET path -- that's what makes a bucket "public" in the first
-- place. This SELECT policy only gates the authenticated Storage API's
-- list()/download() calls, so restricting it to `authenticated` closes the
-- anonymous-enumeration hole with no functional downside.

drop policy if exists avatars_select_public on storage.objects;
create policy avatars_select_public on storage.objects for select to authenticated
  using (bucket_id = 'avatars');
