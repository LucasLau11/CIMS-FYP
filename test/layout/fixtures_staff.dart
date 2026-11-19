import 'fixtures.dart';

Map<String, dynamic> _profileRow(String id, String role, String name, {String approval = 'approved'}) => {
      ...profile(role),
      'profile_id': id,
      'full_name': name,
      'approval_status': approval,
    };

Map<String, dynamic> _embedded(String name) => {'full_name': name, 'email': unbroken, 'approval_status': 'approved'};

/// Tables for the HR, supervisor, company-supervisor and admin screens. The
/// signed-in user is always the first `profiles` row.
Map<String, Object?> staffTables(String role) {
  final base = studentTables();
  final pendingCompany = company(name: 'Pending Verification Company with a Name That Goes On and On Sdn Bhd');
  pendingCompany['status'] = 'pending';
  return {
    ...base,
    'profiles': [
      profile(role),
      _profileRow('00000000-0000-4000-8000-0000000000a1', 'student', longName),
      _profileRow('00000000-0000-4000-8000-0000000000a2', 'academic_supervisor', 'Dr. $longName', approval: 'pending'),
      _profileRow('00000000-0000-4000-8000-0000000000a3', 'company_hr', longName, approval: 'pending'),
      _profileRow('00000000-0000-4000-8000-0000000000a4', 'company_supervisor', longName),
    ],
    'students': [student(), student(id: '00000000-0000-4000-8000-0000000000a1')],
    'v_student_profile': [student(), student(id: '00000000-0000-4000-8000-0000000000a1')],
    'v_student_internship_status': [
      {
        'student_id': me,
        'intake_id': 'i1',
        'intake_name': 'January 2027 Industrial Training Intake',
        'intake_start_date': '2027-01-04',
        'intake_end_date': '2027-06-18',
        'status': 'active',
      },
    ],
    'academic_supervisors': [
      {'profile_id': me, 'profiles': _embedded('Dr. $longName')},
    ],
    'company_hr': [
      {'profile_id': me, 'company_id': companyId, 'profiles': _embedded(longName)},
    ],
    'company_supervisors': [
      {'profile_id': me, 'company_id': companyId, 'profiles': _embedded(longName)},
    ],
    'companies': [company(), pendingCompany],
    'hr_availability': [
      for (final d in [1, 2, 3, 4, 5])
        {'availability_id': 'av$d', 'hr_id': me, 'weekday': d, 'start_time': '09:00:00', 'end_time': '12:00:00', 'slot_minutes': 30, 'created_at': ts(1)},
    ],
    'hr_unavailable_dates': [
      {'hr_id': me, 'blocked_on': future(9).substring(0, 10), 'reason': longReason, 'created_at': ts(1)},
    ],
    'document_templates': [
      {
        'template_id': 't1',
        'purpose': 'parent_acknowledgement',
        'name': 'Parent / Guardian Consent and Acknowledgement Form for Industrial Training 2026',
        'storage_path': 'x.pdf',
        'page_width': 595,
        'page_height': 842,
        'fields': <Object>[],
        'is_active': true,
        'created_by': me,
        'created_at': ts(3),
      },
    ],
    'document_submissions': <Object>[],
    'rpc:get_chat_contact_info': <Object>[],
    'application_notes': <Object>[],
    'rpc:hr_stats': {
      'company_set': true,
      'postings_total': 6,
      'postings_open': 4,
      'applications_total': 31,
      'applicants_unique': 24,
      'by_status': {'pending': 12, 'interview': 8, 'offered': 4, 'active': 5, 'rejected': 2},
      'interviews_upcoming': 3,
      'interviews_completed': 9,
      'per_posting': [
        {'title': 'Senior Full-Stack Developer Intern (Flutter, Dart, Supabase)', 'status': 'open', 'applications': 14, 'interview': 4, 'offered': 2, 'accepted': 2},
        {'title': 'Data Analyst Intern', 'status': 'closed', 'applications': 9, 'interview': 2, 'offered': 1, 'accepted': 1},
      ],
      'weekly': [
        for (var i = 0; i < 8; i++) {'week': '2026-09-${14 + i}', 'count': i * 2},
      ],
    },
    'rpc:academic_supervisor_stats': {
      'students_total': 18,
      'students_placed': 11,
      'reports_total': 40,
      'reports_monthly': 34,
      'reports_final': 6,
      'reports_pending': 9,
      'reports_approved': 28,
      'reports_rejected': 3,
      'documents_pending': 4,
      'documents_approved': 25,
      'evaluations_done': 6,
      'per_student': [
        {'name': 'Muhammad Alexander bin Abdullah Al-Rahman Hartono Wijaya', 'placed': true, 'reports': 4, 'approved': 3, 'pending': 1},
        {'name': 'Siti Aminah', 'placed': false, 'reports': 0, 'approved': 0, 'pending': 0},
      ],
    },
    'rpc:company_supervisor_stats': {
      'company_set': true,
      'students_total': 5,
      'students_evaluated': 3,
      'reports_total': 12,
      'reports_pending': 4,
      'reports_approved': 7,
      'reports_rejected': 1,
      'evaluations_done': 3,
      'per_student': [
        {'name': 'Muhammad Alexander bin Abdullah Al-Rahman Hartono Wijaya', 'evaluated': true, 'reports': 4, 'approved': 3, 'pending': 1},
      ],
    },
    'rpc:admin_platform_stats': {
      'users_by_role': {'student': 120, 'academic_supervisor': 9, 'company_hr': 14, 'company_supervisor': 11, 'admin': 2},
      'pending_approvals': 3,
      'companies_total': 15,
      'companies_by_status': {'verified': 11, 'pending': 4},
      'companies_with_postings': 10,
      'new_companies_30d': 4,
      'new_users_30d': 22,
      'postings_total': 38,
      'postings_open': 21,
      'applications_total': 203,
      'interviews_upcoming': 7,
      'companies_monthly': [
        for (var i = 0; i < 6; i++) {'month': '2026-0${5 + i}', 'count': i + 1},
      ],
      'users_monthly': [
        for (var i = 0; i < 6; i++) {'month': '2026-0${5 + i}', 'count': i * 5},
      ],
    },
    'audit_log': [
      for (final i in [0, 1, 2])
        {
          'audit_id': 'au$i',
          'actor_id': me,
          'actor_role': 'admin',
          'action': ['account_approved', 'company_status_changed', 'supervisor_assigned'][i],
          'summary': 'Account of $longName (company_hr) set to approved by an administrator with a very long explanation',
          'created_at': ts(i + 1),
          'actor': {'full_name': longName, 'email': 'admin@example.com'},
        },
    ],
    'rpc:admin_placement_report': {
      'students_total': 120,
      'students_placed': 47,
      'students_applied': 88,
      'applications_total': 203,
      'by_status': {'pending': 80, 'interview': 40, 'offered': 30, 'active': 47, 'rejected': 6},
      'by_programme': [
        {'programme': 'Bachelor of Information Technology (Honours) in Software Systems Development', 'students': 60, 'placed': 25},
        {'programme': 'Not set', 'students': 5, 'placed': 0},
      ],
      'by_company': [
        {'company': 'International Business Machines Technology Solutions Sdn Bhd', 'postings': 4, 'applications': 90, 'placed': 20},
      ],
      'top_postings': [
        {'title': 'Senior Full-Stack Developer Intern (Flutter, Dart, Supabase)', 'company': 'International Business Machines Technology Solutions Sdn Bhd', 'applications': 40, 'offered': 9, 'placed': 4},
      ],
      'unplaced_students': [
        {'name': longName, 'email': 'a.very.long.email.address.for.a.student@student.example.edu.my', 'reg_no': '23WMR12345', 'programme': 'Bachelor of Information Technology (Honours) in Software Systems Development', 'applications': 2},
      ],
    },
    'rpc:get_candidate_resume': <Object>[],
    'rpc:supervisor_intakes': [
      {'intake_id': '00000000-0000-4000-8000-0000000000b1', 'name': 'September 2026 Internship Intake of a Rather Long Name', 'start_date': '2026-09-01', 'end_date': '2027-02-28', 'student_count': 12},
    ],
    'rpc:intake_grade_overview': [
      {'student_id': '00000000-0000-4000-8000-000000000001', 'full_name': longName, 'programme': longProgramme, 'internship_status': 'completed',
       'company_points': 48, 'academic_points': 34, 'total': 82, 'complete': true},
    ],
    'rpc:student_grade_summary': {
      'student_id': '00000000-0000-4000-8000-000000000001',
      'company': {'evaluated': true, 'rubric': true, 'average': 4, 'percent': 81.7, 'points': 49, 'comments': longReason, 'evaluator': longName,
                  'designation': 'Senior Software Engineering Manager', 'attendance_with': 1, 'attendance_without': 0, 'overall_grade': 'B+',
                  'training_notes': longReason,
                  'scores': {'technical_knowledge': 5, 'dependability': 4, 'initiative': 6, 'commitment': 5, 'quality_of_work': 4,
                             'working_relationship': 6, 'discipline': 5, 'system_development_skills': 3, 'punctuality': 6, 'attendance': 5}},
      'monthly': {'reports': 2, 'graded': 2, 'average': 8, 'points': 8, 'max': 10, 'items': [
        {'period': 'Month 1', 'grade': 9, 'marks': {'submission': 4, 'content': 5}, 'status': 'approved'},
        {'period': 'Month 2', 'grade': 7, 'marks': {'submission': 3, 'content': 4}, 'status': 'approved'}]},
      'final': {'reports': 1, 'grade': 26, 'points': 26, 'max': 30, 'items': [
        {'period': 'Final', 'grade': 26, 'marks': {'submission': 4, 'written': 5, 'awareness': 8, 'content': 9}, 'status': 'approved'}]},
      'company_points': 48, 'academic_points': 34, 'total': 82, 'complete': true,
    },
  };
}
