-- Task 22: Fresh, realistic seed data across all 6 roles.
--
-- Purpose: the normalized schema (Tasks 1-21) was rewritten and applied on a
-- brand-new Supabase project with ZERO rows in any application table, which
-- blocked meaningful end-to-end manual testing throughout the whole
-- migration. This script seeds one coherent, realistic story spanning every
-- role and every major table so a human can actually log in and click
-- through the app.
--
-- Fixed, memorable UUIDs are used everywhere (never gen_random_uuid()) so
-- this file is deterministic and every id is referenceable from the task
-- report. Pattern: a000...00N = the 6 seeded profile_id/auth.users.id
-- values (N = 1 student, 2 academic_supervisor, 3 company_hr,
-- 4 company_supervisor, 5 parent, 6 admin); b000...00N = the matching
-- auth.identities row; c/d/e/f/1/2/3/4/5-prefixed 0000...000N ids are the
-- company / job_posting / application+interview / report+reviews /
-- document+review / evaluation / conversation+messages /
-- template+submission / parent_child_link rows respectively.
--
-- Login credentials (all 6 accounts share one password):
--   password: FypCims2026!
--   student@fypcims.test            (student)
--   supervisor@fypcims.test         (academic_supervisor)
--   hr@fypcims.test                 (company_hr)
--   companysupervisor@fypcims.test  (company_supervisor)
--   parent@fypcims.test             (parent)
--   admin@fypcims.test              (admin)
--
-- IMPORTANT: `create_profile_with_subtype` is NOT used here -- it relies on
-- auth.uid(), which has no meaning when inserting directly as the
-- postgres/service role. Instead this script mirrors that RPC's body by
-- hand: auth.users -> auth.identities -> profiles -> subtype table, in that
-- order, for each account (profiles row must exist with the correct `role`
-- BEFORE the subtype insert, since the Task 2 role-consistency triggers
-- fire on subtype INSERT and check profiles.role at that moment).

begin;

-- ============================================================================
-- 1. auth.users -- 6 real, working accounts (bcrypt password hash via
--    pgcrypto, same algorithm GoTrue itself uses).
--    confirmed_at is a GENERATED ALWAYS column (LEAST(email_confirmed_at,
--    phone_confirmed_at)) and must NOT appear in the column list.
-- ============================================================================

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token,
  is_sso_user, is_anonymous
) values
  ('00000000-0000-0000-0000-000000000000', 'a0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'student@fypcims.test', extensions.crypt('FypCims2026!', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(),
   '', '', '', '', false, false),
  ('00000000-0000-0000-0000-000000000000', 'a0000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'supervisor@fypcims.test', extensions.crypt('FypCims2026!', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(),
   '', '', '', '', false, false),
  ('00000000-0000-0000-0000-000000000000', 'a0000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   'hr@fypcims.test', extensions.crypt('FypCims2026!', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(),
   '', '', '', '', false, false),
  ('00000000-0000-0000-0000-000000000000', 'a0000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated',
   'companysupervisor@fypcims.test', extensions.crypt('FypCims2026!', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(),
   '', '', '', '', false, false),
  ('00000000-0000-0000-0000-000000000000', 'a0000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated',
   'parent@fypcims.test', extensions.crypt('FypCims2026!', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(),
   '', '', '', '', false, false),
  ('00000000-0000-0000-0000-000000000000', 'a0000000-0000-0000-0000-000000000006', 'authenticated', 'authenticated',
   'admin@fypcims.test', extensions.crypt('FypCims2026!', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(),
   '', '', '', '', false, false);

-- ============================================================================
-- 2. auth.identities -- one 'email' provider identity per user.
--    `email` is GENERATED ALWAYS (lower(identity_data->>'email')) and must
--    NOT appear in the column list; it's supplied via identity_data instead.
-- ============================================================================

insert into auth.identities (
  id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
   '{"sub":"a0000000-0000-0000-0000-000000000001","email":"student@fypcims.test","email_verified":true,"provider":"email"}'::jsonb,
   'email', now(), now(), now()),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002',
   '{"sub":"a0000000-0000-0000-0000-000000000002","email":"supervisor@fypcims.test","email_verified":true,"provider":"email"}'::jsonb,
   'email', now(), now(), now()),
  ('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003',
   '{"sub":"a0000000-0000-0000-0000-000000000003","email":"hr@fypcims.test","email_verified":true,"provider":"email"}'::jsonb,
   'email', now(), now(), now()),
  ('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000004',
   '{"sub":"a0000000-0000-0000-0000-000000000004","email":"companysupervisor@fypcims.test","email_verified":true,"provider":"email"}'::jsonb,
   'email', now(), now(), now()),
  ('b0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000005',
   '{"sub":"a0000000-0000-0000-0000-000000000005","email":"parent@fypcims.test","email_verified":true,"provider":"email"}'::jsonb,
   'email', now(), now(), now()),
  ('b0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000006',
   '{"sub":"a0000000-0000-0000-0000-000000000006","email":"admin@fypcims.test","email_verified":true,"provider":"email"}'::jsonb,
   'email', now(), now(), now());

-- ============================================================================
-- 3. profiles -- base identity row for all 6 accounts (role set here first,
--    subtype tables inserted after, per the role-consistency trigger note
--    above).
-- ============================================================================

insert into profiles (profile_id, role, email, full_name, phone, language, theme_mode) values
  ('a0000000-0000-0000-0000-000000000001', 'student', 'student@fypcims.test', 'Tan Wei Ming', '+60123456781', 'English', 'system'),
  ('a0000000-0000-0000-0000-000000000002', 'academic_supervisor', 'supervisor@fypcims.test', 'Dr. Lim Siew Hoon', '+60123456782', 'English', 'system'),
  ('a0000000-0000-0000-0000-000000000003', 'company_hr', 'hr@fypcims.test', 'Nurul Aina binti Rahman', '+60123456783', 'English', 'system'),
  ('a0000000-0000-0000-0000-000000000004', 'company_supervisor', 'companysupervisor@fypcims.test', 'Rajesh Kumar', '+60123456784', 'English', 'system'),
  ('a0000000-0000-0000-0000-000000000005', 'parent', 'parent@fypcims.test', 'Tan Ah Kow', '+60123456785', 'English', 'system'),
  ('a0000000-0000-0000-0000-000000000006', 'admin', 'admin@fypcims.test', 'System Administrator', '+60123456786', 'English', 'system');

-- ============================================================================
-- 4. companies -- one seeded company that HR/company-supervisor belong to.
-- ============================================================================

insert into companies (company_id, name, industry, location, hr_contact_name, hr_contact_email, hr_contact_phone, status) values
  ('c0000000-0000-0000-0000-000000000001', 'Skylark Technologies Sdn Bhd', 'Information Technology', 'Kuala Lumpur, Malaysia',
   'Nurul Aina binti Rahman', 'hr@fypcims.test', '+60123456783', 'verified');

-- ============================================================================
-- 5. Subtype rows -- one per role, mirroring create_profile_with_subtype.
-- ============================================================================

insert into students (profile_id, academic_supervisor_id, programme, semester, faculty, cgpa, skills, student_reg_no) values
  ('a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002',
   'Bachelor of Computer Science (Software Engineering)', 6, 'Faculty of Computing', 3.65,
   array['Flutter','Dart','SQL','Python','Git'], 'TP012345');

insert into academic_supervisors (profile_id) values
  ('a0000000-0000-0000-0000-000000000002');

insert into parents (profile_id) values
  ('a0000000-0000-0000-0000-000000000005');

insert into company_hr (profile_id, company_id) values
  ('a0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001');

insert into company_supervisors (profile_id, company_id) values
  ('a0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000001');

insert into administrators (profile_id) values
  ('a0000000-0000-0000-0000-000000000006');

-- ============================================================================
-- 6. parent_child_links -- approved link between the seeded parent and student.
-- ============================================================================

insert into parent_child_links (pc_link_id, parent_id, student_id, relationship, status, requested_at, responded_at) values
  ('50000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001',
   'father', 'approved', now() - interval '20 days', now() - interval '19 days');

-- ============================================================================
-- 7. job_postings / applications / interviews -- the student applies to the
--    seeded company's posting and is invited to interview.
--    category_id reuses the existing 'Software' row (category names are
--    already seeded by migration 00011 -- do not create a duplicate).
-- ============================================================================

insert into job_postings (
  job_posting_id, company_id, category_id, status, title, description, location,
  duration_months, allowance_month, required_skills, job_type, application_deadline, posting_closes_at, posted_at
) values (
  'd0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001',
  (select category_id from categories where category_name = 'Software'),
  'open', 'Mobile App Development Intern',
  'Join our mobile team to build and ship features in our Flutter-based customer app. You will work alongside senior engineers on real production code.',
  'Kuala Lumpur, Malaysia', 6, 1200.00, array['Flutter','Dart','Git'], 'internship',
  date '2026-09-30', now() + interval '55 days', now() - interval '10 days'
);

insert into applications (application_id, student_id, job_posting_id, status, cover_letter, skills, applied_at, updated_at) values
  ('e0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001',
   'interview',
   'I am a Year 3 Software Engineering student with hands-on Flutter experience from coursework and personal projects, and I would love to contribute to Skylark''s mobile team.',
   array['Flutter','Dart'], now() - interval '8 days', now() - interval '2 days');

insert into interviews (interview_id, application_id, scheduled_at, mode, location) values
  ('e0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001',
   now() + interval '3 days', 'online', 'Google Meet (link sent via email)');

-- ============================================================================
-- 8. reports -- one monthly report with BOTH review stages: an academic
--    review by the seeded academic_supervisor and a company review by the
--    seeded company_supervisor (matching the two-stage approval flow).
--    NOTE: storage_path/file_name are placeholders -- no real file was
--    uploaded to the `student_files` bucket for this row. See task report
--    for why (flagged the same way as the document_templates limitation).
-- ============================================================================

insert into reports (report_id, student_id, type, period_label, notes, storage_path, file_name, file_size_bytes, submitted_at) values
  ('f0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'monthly', 'August 2026',
   'Completed onboarding, set up the local dev environment, and shipped my first small bug fix to the mobile app.',
   'student_files/a0000000-0000-0000-0000-000000000001/reports/august-2026-monthly-report.pdf',
   'august-2026-monthly-report.pdf', 184320, now() - interval '5 days');

insert into academic_report_reviews (academic_report_review_id, report_id, reviewer_id, status, feedback, reviewed_at) values
  ('f0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002',
   'approved', 'Good first report -- clear structure and reflective notes. Keep documenting specific tasks going forward.', now() - interval '3 days');

insert into company_report_reviews (company_report_review_id, report_id, reviewer_id, status, feedback, reviewed_at) values
  ('f0000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000004',
   'approved', 'Confirmed -- matches what I observed on the floor this month. Nice progress ramping up.', now() - interval '2 days');

-- ============================================================================
-- 9. documents -- one offer letter, approved, with a document_review by the
--    student's academic supervisor. storage_path is a placeholder (same
--    caveat as the report above -- no real object was uploaded).
-- ============================================================================

insert into documents (document_id, student_id, category, status, title, storage_path, file_name, file_size_bytes, uploaded_at) values
  ('10000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'offer_letter', 'approved',
   'Skylark Technologies Internship Offer Letter',
   'student_files/a0000000-0000-0000-0000-000000000001/documents/offer-letter.pdf',
   'offer-letter.pdf', 92160, now() - interval '9 days');

insert into document_reviews (document_review_id, document_id, reviewer_id, feedback, reviewed_at) values
  ('10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002',
   'Offer letter checks out -- company, role, and duration all match the approved application.', now() - interval '7 days');

-- ============================================================================
-- 10. evaluations -- one academic evaluation by the assigned academic
--     supervisor (append-only table, no reviews table involved).
-- ============================================================================

insert into evaluations (evaluation_id, student_id, supervisor_id, type, scores, average_score, comments, created_at) values
  ('20000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002',
   'academic',
   '{"technical_skills":8,"communication":9,"initiative":8,"professionalism":9,"teamwork":8}'::jsonb,
   8.4, 'Strong start to the internship. Communicates clearly and is proactive about asking for feedback.',
   now() - interval '1 day');

-- ============================================================================
-- 11. Messaging -- one conversation between the student and their academic
--     supervisor, with a short back-and-forth.
-- ============================================================================

insert into conversations (conversation_id, last_message_at, created_at) values
  ('30000000-0000-0000-0000-000000000001', now() - interval '4 days', now() - interval '6 days');

insert into profile_conversations (conversation_id, profile_id) values
  ('30000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001'),
  ('30000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002');

insert into messages (message_id, conversation_id, sender_id, body, created_at, read_at) values
  ('30000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
   'Hi Dr. Lim, I just submitted my August monthly report -- could you take a look when you have a moment?',
   now() - interval '6 days', now() - interval '6 days' + interval '2 hours'),
  ('30000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002',
   'Thanks for the update, I reviewed it and left feedback -- overall a solid first report, keep it up.',
   now() - interval '5 days', now() - interval '5 days' + interval '1 hour'),
  ('30000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
   'Thank you! I will make sure next month''s report has more specific task breakdowns.',
   now() - interval '4 days', null);

-- ============================================================================
-- 12. document_templates / document_submissions -- the parent-acknowledgement
--     template flow.
--     LIMITATION (flagged per task brief guidance): no real PDF was
--     available to upload to the `document_templates` storage bucket for
--     this seed, so storage_path below is a placeholder that will 404 if a
--     screen tries to fetch it. is_active is deliberately set to FALSE so
--     this row does NOT surface as a real, selectable active template in
--     the parent-acknowledgement UI flow (which expects to actually be able
--     to download/render it) -- avoiding a silent broken-download bug.
-- ============================================================================

insert into document_templates (template_id, purpose, name, storage_path, page_width, page_height, fields, is_active, created_by, created_at) values
  ('40000000-0000-0000-0000-000000000001', 'parent_acknowledgement', 'Parent/Guardian Consent & Acknowledgement Form',
   'document_templates/placeholder/parent-consent-template.pdf', 595, 842, '[]'::jsonb, false,
   'a0000000-0000-0000-0000-000000000006', now() - interval '15 days');

insert into document_submissions (submission_id, template_id, student_id, submitted_by, values, generated_pdf_path, submitted_at) values
  ('40000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
   'a0000000-0000-0000-0000-000000000005',
   '{"parent_name":"Tan Ah Kow","student_name":"Tan Wei Ming","signature_date":"2026-07-20","acknowledged":true}'::jsonb,
   'document_submissions/placeholder/40000000-0000-0000-0000-000000000002.pdf',
   now() - interval '14 days');

commit;
