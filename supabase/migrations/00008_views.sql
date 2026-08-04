create view v_student_profile with (security_invoker = true) as
  select p.profile_id, p.full_name, p.email, p.avatar_url, p.phone, p.date_of_birth,
         p.address_text, p.address_lat, p.address_lng, p.language, p.notification_prefs, p.theme_mode,
         s.academic_supervisor_id, s.programme, s.semester, s.faculty, s.cgpa, s.skills,
         s.resume_path, s.resume_filename, s.resume_size_bytes, s.resume_uploaded_at, s.student_reg_no
  from profiles p join students s on s.profile_id = p.profile_id;

create view v_application_with_interview with (security_invoker = true) as
  select a.*, i.interview_id, i.scheduled_at as interview_scheduled_at, i.mode as interview_mode, i.location as interview_location
  from applications a left join interviews i on i.application_id = a.application_id;

create view v_report_with_reviews with (security_invoker = true) as
  select r.*,
         arr.status as academic_status, arr.feedback as academic_feedback, arr.reviewer_id as academic_reviewer_id, arr.reviewed_at as academic_reviewed_at,
         crr.status as company_status, crr.feedback as company_feedback, crr.reviewer_id as company_reviewer_id, crr.reviewed_at as company_reviewed_at
  from reports r
  left join academic_report_reviews arr on arr.report_id = r.report_id
  left join company_report_reviews crr on crr.report_id = r.report_id;

create view v_document_with_review with (security_invoker = true) as
  select d.*, dr.feedback as review_feedback, dr.reviewer_id, dr.reviewed_at
  from documents d left join document_reviews dr on dr.document_id = d.document_id;
