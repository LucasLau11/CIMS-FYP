-- Task 16 review: interview double-booking race + empty categories table

-- Fix: interviews had no unique constraint on application_id, so the
-- check-then-insert-or-update pattern in updateApplicationStatus() wasn't
-- atomic -- a rapid double-submit (or any concurrent caller) could create
-- two interview rows for the same application. Add the constraint and let
-- the app switch to upsert(onConflict: 'application_id').
alter table interviews add constraint interviews_application_id_unique unique (application_id);

-- Fix: categories was completely empty and admin-only writable, so every
-- HR-created/edited posting's category silently resolved to null --
-- confirmed live by Task 16's review. Seed the 5 names hr_postings_screen.dart
-- already hardcodes in its dropdown, so the existing case-insensitive
-- _resolveCategoryId() match in hr_data_service.dart starts working for the
-- common case without touching the screen (which is out of this task's
-- scope). The screen's free-text "Custom..." option still can't resolve to
-- anything new -- HR has no write access to categories by design -- that
-- narrower gap is left for a follow-up admin-categories management task.
insert into categories (category_name) values
  ('Software'), ('Data'), ('Design'), ('Network'), ('Business')
on conflict (category_name) do nothing;
