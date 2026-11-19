# Migrations

Every schema change for this project is a numbered SQL file here, applied
via the Supabase MCP `apply_migration` tool and committed to git in the
same commit as the file itself. This is the durability practice from
`docs/superpowers/plans/2026-08-04-normalized-schema-migration.md` —
future schema changes (e.g. tutor-requested ERD revisions) should follow
the same pattern: new numbered file, applied, committed. Never apply
untracked ad-hoc SQL directly against the project.

Project: Lucas FYP - CIMS Project (lgosyvuwtkzrjvsbxyed), org "Lucas FYP Org".

## Known gap: the live database is ahead of these files

The live project's migration history contains changes that were applied
directly and never saved as files here — for example
`fix_can_notify_cross_user_rls`, `fix_academic_supervisor_sees_company_review`,
`intakes_and_evaluation_gating`, `fix_v_student_internship_status_security_definer`,
`offer_letter_and_company_document_visibility`, `offer_letter_storage_access`
and `company_acceptance_letter_filled_by_hr`. Running only the files in this
folder on an empty database will therefore NOT reproduce the live schema.

Fix: with the Supabase CLI linked to the project, run `supabase db pull` and
commit the generated file(s). Until then, treat the live database as the
source of truth.

`00023_security_hardening.sql`, `00024_signup_name_and_account_anonymise.sql`,
`00025_candidate_resume_lookup.sql` and
`00026_rejection_reason_and_single_accepted_offer.sql` and
`00027_interview_slots_cancel_reschedule.sql` were applied to the live
project and are included here, as is `00028_parent_role_detach.sql`.
`00030_chat_contact_profile.sql`, `00031_admin_created_students.sql` and
`00032_posting_expiry_and_reschedule_approval.sql` (checks: `../tests/reschedule_approval_check.sql`) were applied too (the second one
also needs the `admin-create-students` Edge Function in `../functions/`, deployed with verify_jwt on).
`00033_applicant_notes.sql`, `00034_interview_reminders.sql`, `00035_schedule_maintenance_jobs.sql` (turns on pg_cron),
`00036_audit_log.sql` (checks: `../tests/audit_log_check.sql`), `00037_admin_placement_report.sql`,
`00038_chat_rules.sql` (checks: `../tests/chat_rules_check.sql`), `00039_staff_stats_and_supervisor_accounts.sql`
(checks: `../tests/staff_stats_check.sql`) and `00040_apply_only_to_verified_companies.sql`
(checks: `../tests/unverified_company_check.sql`), `00041_bug_round_notifications_accounts.sql` (message-key notifications, accounts
created by an administrator, login hint, deleted accounts hidden; the Edge Functions `admin-create-students` and
`send-push-notification` were redeployed with it) and `00042_admin_suspend_remove_and_notification_backfill.sql`
(suspend / remove accounts, company staff, old notifications given keys; applied as 00042a and 00042b) `00043_reason_min_100_and_report_grades.sql` (reasons need 100 characters; grading 60% company, monthly reports 20, final report 20) and
`00044_company_verification_documents.sql` (company legal documents, admin verification, no postings before it, HR accounts
approved at sign-up) `00045_rubric_marks_for_reports.sql` (the academic supervisor marks each report with the university rubric: progress 10, final 30) `00046_company_evaluation_rubric.sql` (the company supervisor's 10-criteria, 60-mark form) `00047_hide_unconfirmed_signups_from_admin.sql` (sign-ups never confirmed by email are hidden from the administrator's lists; nothing is deleted) `00048_close_evaluation_after_submit.sql` (one company evaluation per student, then it is closed) `00049_offer_letter_with_the_offer.sql` (the offer letter is attached when HR makes the offer, stored per application, required for new offers, copied to the student's documents when they accept) `00050_hr_acceptance_letter_and_template_delete.sql` (company HR can store and save the filled acceptance letter; the administrator can delete a template's PDF) `00051_allow_company_notification_type.sql` (the administrator can verify or reject a company again: the notification it sends was of a type the table refused) `00052_grading_comments_required.sql` (the comment is compulsory when approving a report grade and in the company evaluation) `00053_company_supervisor_assignment.sql` (each intern has one company supervisor: automatic when the company has one, assigned by HR when it has several) `00054_monthly_reports_by_intake_length.sql` (monthly reports required = months of the intake) `00055_letter_autofill_details.sql` (letters fill in from the profile; private IC number) `00056_intake_grade_overview_more_columns.sql` (more columns for the grade downloads) were applied too. Run all checks
with `../tests/run_checks.sh` (needs `SUPABASE_DB_URL`).
`00029_remove_parent_role.sql` is **written but not applied**: it permanently
deletes the parent account data and tables, and waits for the owner's
confirmation. Checks are in
`../tests/applications_lifecycle_check.sql` (00026) and
`../tests/interview_slots_check.sql` (00027).
