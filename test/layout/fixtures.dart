import 'layout_harness.dart';

/// Deliberately awkward values: names, titles and addresses as long as real
/// people and companies have them, plus one unbroken string with no spaces.
const longName = 'Muhammad Alexander bin Abdullah Al-Rahman Hartono Wijaya';
const longTitle = 'Senior Full-Stack Software Engineering and Machine Learning Intern (Hybrid, Kuala Lumpur)';
const longCompany = 'International Business Machines Technology Solutions Sdn Bhd (Malaysia Regional Office)';
const longLocation = 'Level 42, Menara Kuala Lumpur Sentral Tower 2, Jalan Stesen Sentral 5, Kuala Lumpur Sentral, 50470 Kuala Lumpur, Wilayah Persekutuan';
const longReason =
    'We have decided to proceed with candidates whose experience is closer to the role requirements at this time, '
    'and we encourage you to apply again for future postings that match your skills.';
const unbroken = 'averyveryverylongunbrokenemailaddressthatnevergetsaspace1234567890@subdomain.example-company.com.my';
const longProgramme = 'Bachelor of Computer Science (Honours) in Software Engineering with Industrial Training';

final String me = FakeBackend.userId;
const otherId = '00000000-0000-4000-8000-000000000002';
const companyId = '00000000-0000-4000-8000-0000000000c1';
const postingId = '00000000-0000-4000-8000-0000000000a1';

String ts(int daysAgo) => DateTime.now().subtract(Duration(days: daysAgo)).toUtc().toIso8601String();
String future(int days, {int hour = 10}) {
  final d = DateTime.now().add(Duration(days: days));
  return DateTime.utc(d.year, d.month, d.day, hour).toIso8601String();
}

Map<String, dynamic> company({String name = longCompany}) => {
      'company_id': companyId,
      'name': name,
      'industry': 'Information Technology and Business Process Outsourcing Services',
      'location': longLocation,
      'hr_contact_name': longName,
      'hr_contact_email': unbroken,
      'hr_contact_phone': '+60 12-345 6789',
      'status': 'verified',
      'created_at': ts(30),
    };

Map<String, dynamic> posting({int i = 0, String title = longTitle}) => {
      'job_posting_id': i == 0 ? postingId : '00000000-0000-4000-8000-0000000000a${i + 1}',
      'company_id': companyId,
      'category_id': '00000000-0000-4000-8000-0000000000d1',
      'status': 'open',
      'title': title,
      'description': 'Work with our engineering team on ${'a very long description of responsibilities ' * 12}',
      'location': longLocation,
      'duration_months': 6,
      'allowance_month': 1500,
      'required_skills': ['Flutter', 'Dart', 'PostgreSQL', 'Machine Learning', 'Kubernetes and Cloud Infrastructure', 'Communication'],
      'job_type': 'Full-time',
      'application_deadline': future(20).substring(0, 10),
      'posting_closes_at': future(25),
      'posted_at': ts(3),
      'companies': {'name': company()['name'], 'industry': company()['industry'], 'status': 'verified'},
      'categories': {'category_name': 'Software Engineering and Data Science'},
    };

Map<String, dynamic> student({String id = ''}) => {
      'profile_id': id.isEmpty ? me : id,
      'academic_supervisor_id': otherId,
      'programme': longProgramme,
      'semester': 6,
      'faculty': 'Faculty of Computing and Information Technology',
      'cgpa': 3.65,
      'skills': ['Flutter', 'Dart', 'SQL', 'Python', 'Git', 'Docker', 'Machine Learning Operations'],
      'resume_path': 'x/resume.pdf',
      'resume_filename': 'Muhammad_Alexander_Resume_Final_Version_2026_v3.pdf',
      'resume_size_bytes': 123456,
      'resume_uploaded_at': ts(5),
      'student_reg_no': '24WMR12345',
      'intake_id': null,
      'full_name': longName,
      'email': unbroken,
      'avatar_url': null,
      'phone': '+60123456789',
      'date_of_birth': '2003-05-17',
      'address_text': longLocation,
      'address_lat': 3.1,
      'address_lng': 101.6,
      'language': 'English',
      'notification_prefs': {},
      'theme_mode': 'system',
      'profiles': {'full_name': longName},
      'own_profile': {'full_name': longName},
      'supervisor_profile': {'full_name': 'Dr. $longName'},
    };

Map<String, dynamic> profile(String role) => {
      'profile_id': me,
      'role': role,
      'email': unbroken,
      'full_name': longName,
      'avatar_url': null,
      'phone': '+60123456789',
      'date_of_birth': '1985-05-17',
      'address_text': longLocation,
      'language': 'English',
      'notification_prefs': {},
      'theme_mode': 'system',
      'created_at': ts(90),
      'approval_status': 'approved',
    };

Map<String, dynamic> interview({String status = 'scheduled', List<Map<String, dynamic>> changes = const []}) => {
      'interview_id': '00000000-0000-4000-8000-0000000000f1',
      'interviewer_id': me,
      'scheduled_at': future(3),
      'ends_at': future(3, hour: 11),
      'mode': 'in_person',
      'location': longLocation,
      'status': status,
      'interview_changes': changes,
      // A request from the other side, waiting for this user to accept or decline.
      'interview_reschedule_requests': [
        {
          'request_id': '00000000-0000-4000-8000-0000000000f9',
          'requested_by': otherId,
          'requested_role': 'student',
          'proposed_start': future(5),
          'proposed_end': future(5, hour: 11),
          'reason': longReason,
          'status': 'pending',
          'response_note': null,
          'created_at': ts(0),
        },
      ],
    };

Map<String, dynamic> application(String status, {int i = 1, bool withInterview = false}) {
  final p = posting(i: i);
  return {
    'application_id': '00000000-0000-4000-8000-0000000000b$i',
    'student_id': me,
    'job_posting_id': p['job_posting_id'],
    'status': status,
    'cover_letter': 'Dear hiring manager, ${'I am very interested in this role and believe my skills fit well. ' * 8}',
    'skills': ['Flutter', 'Dart', 'PostgreSQL and Data Modelling'],
    'applied_at': ts(i + 1),
    'updated_at': ts(i),
    'rejection_reason': status == 'rejected' ? longReason : null,
    'internships': p,
    'job_postings': {'job_posting_id': p['job_posting_id'], 'title': p['title'], 'company_id': companyId, 'companies': {'name': longCompany}},
    'interviews': withInterview ? interview(changes: [
      {'action': 'rescheduled', 'actor_role': 'company_hr', 'reason': longReason, 'old_start': future(2), 'new_start': future(3), 'created_at': ts(1)},
    ]) : null,
  };
}

List<Map<String, dynamic>> applications() => [
      application('pending', i: 1),
      application('interview', i: 2, withInterview: true),
      application('offered', i: 3),
      application('active', i: 4),
      application('rejected', i: 5),
      application('unavailable', i: 6),
    ];

List<Map<String, dynamic>> notifications() => [
      for (var i = 0; i < 5; i++)
        {
          'notification_id': '00000000-0000-4000-8000-0000000000e$i',
          'user_id': me,
          'title': i.isEven ? 'Candidate no longer available for $longTitle' : 'Interview rescheduled',
          'body': '$longName moved the interview for $longTitle to Wed 4 Nov 2026, 10:30 AM. Reason: $longReason',
          'type': ['application', 'report', 'document', 'message', 'application'][i],
          'related_id': postingId,
          'read': i > 2,
          'created_at': ts(i),
        },
    ];

List<Map<String, dynamic>> documents() => [
      for (final c in ['offer_letter', 'indemnity_letter', 'company_acceptance_letter', 'other'])
        {
          'document_id': '00000000-0000-4000-8000-0000000000c${c.length}',
          'student_id': me,
          'category': c,
          'status': 'approved',
          'title': 'A very long custom document title for the other documents section number one',
          'storage_path': 'x/doc.pdf',
          'file_name': 'Final_Signed_Company_Acceptance_Letter_Muhammad_Alexander_2026.pdf',
          'file_size_bytes': 2345678,
          'uploaded_at': ts(2),
        },
    ];

List<Map<String, dynamic>> reports() => [
      for (var i = 0; i < 3; i++)
        {
          'report_id': '00000000-0000-4000-8000-0000000000r$i',
          'student_id': me,
          'type': i == 2 ? 'final' : 'monthly',
          'period_label': 'Month ${i + 1} of industrial training',
          'notes': 'Notes: $longReason',
          'storage_path': 'x/report.pdf',
          'file_name': 'Monthly_Progress_Report_Month_${i + 1}_Muhammad_Alexander_Final.pdf',
          'file_size_bytes': 1234567,
          'submitted_at': ts(i + 1),
          'academic_status': ['submitted', 'approved', 'rejected'][i],
          'academic_feedback': i == 0 ? null : longReason,
          'academic_reviewer_id': otherId,
          'academic_reviewed_at': ts(i),
          'company_status': ['approved', 'submitted', 'rejected'][i],
          'company_feedback': longReason,
          'company_reviewer_id': otherId,
          'company_reviewed_at': ts(i),
        },
    ];

List<Map<String, dynamic>> evaluations() => [
      for (var i = 0; i < 2; i++)
        {
          'evaluation_id': '00000000-0000-4000-8000-0000000000v$i',
          'student_id': me,
          'supervisor_id': otherId,
          'type': i == 0 ? 'academic' : 'workplace',
          'scores': {'Technical competency': 4, 'Communication skills': 3, 'Professionalism and discipline': 5, 'Problem-solving ability': 2, 'Teamwork and collaboration': 4},
          'average_score': 3.6,
          'comments': longReason,
          'created_at': ts(i),
        },
    ];

List<Map<String, dynamic>> conversations() => [
      {'conversation_id': 'c1', 'last_message_at': ts(0), 'created_at': ts(3)},
      {'conversation_id': 'c2', 'last_message_at': ts(1), 'created_at': ts(4)},
    ];

List<Map<String, dynamic>> profileConversations() => [
      for (final c in ['c1', 'c2']) ...[
        {'conversation_id': c, 'profile_id': me, 'archived': false, 'muted': false, 'blocked_by': false},
        {'conversation_id': c, 'profile_id': otherId, 'archived': false, 'muted': false, 'blocked_by': false},
      ],
    ];

List<Map<String, dynamic>> messages() => [
      for (var i = 0; i < 4; i++)
        {
          'message_id': 'm$i',
          'conversation_id': i.isEven ? 'c1' : 'c2',
          'sender_id': i.isEven ? me : otherId,
          'body': 'Hello $longName, regarding $longTitle: $longReason $unbroken',
          'created_at': ts(i),
          'read_at': i > 1 ? ts(i) : null,
          'attachment_path': i == 1 ? 'x/file.pdf' : null,
          'attachment_file_name': i == 1 ? 'Attachment_With_A_Really_Long_File_Name_That_Keeps_Going_And_Going_2026.pdf' : null,
          'attachment_size_bytes': i == 1 ? 123456 : null,
          'edited_at': null,
          'deleted_for': <String>[],
        },
    ];

List<Map<String, dynamic>> directory() => [
      {'profile_id': otherId, 'full_name': longName, 'role': 'academic_supervisor', 'avatar_url': null, 'skills': <String>[], 'programme': longProgramme},
    ];

/// Rows for every table the student screens read.
Map<String, Object?> studentTables() => {
      'profiles': [profile('student')],
      'students': [student()],
      'v_student_profile': [student()],
      'profile_directory': directory(),
      // everyone in the directory counts as someone this user may start a chat with
      'rpc:messageable_profile_ids': [for (final d in directory()) d['profile_id']],
      'job_postings': [for (var i = 0; i < 4; i++) posting(i: i)],
      'applications': applications(),
      'companies': [company()],
      'company_reviews': [
        {'company_review_id': 'r1', 'company_id': companyId, 'student_id': otherId, 'rating': 4, 'review': longReason, 'created_at': ts(2), 'updated_at': ts(2)}
      ],
      'v_notifications': notifications(),
      'documents': documents(),
      'v_document_with_review': documents(),
      'reports': reports(),
      'v_report_with_reviews': reports(),
      'evaluations': evaluations(),
      'work_experiences': [
        {'work_experience_id': 'w1', 'student_id': me, 'company_name': longCompany, 'position': longTitle, 'description': longReason, 'start_year': 2023, 'end_year': null, 'is_current': true, 'created_at': ts(9)}
      ],
      'conversations': conversations(),
      'profile_conversations': profileConversations(),
      'messages': messages(),
      'categories': [{'category_id': 'd1', 'category_name': 'Software Engineering and Data Science'}],
      'intakes': [
        {'intake_id': 'i1', 'name': 'January 2027 Industrial Training Intake', 'start_date': '2027-01-04', 'end_date': '2027-06-18', 'created_by': otherId, 'created_at': ts(9)}
      ],
    };
