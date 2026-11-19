// What a letter template can fill in by itself, from the profile and the internship (database function
// `letter_context`, migration 00055), and how a template field finds its value.
//
// A template's field has a key ("student_name", "ic", "company_name_2") and a label ("Company address"). Admins pick
// the keys of auto-filled fields from [kLetterAutoFields]; but typed and date fields made by hand have free keys, so
// [resolveLetterValue] also understands common names for the same thing ("ic", "nric", "reg_no", "tel", "date"...),
// a trailing number ("company_name_2" is the company name again) and falls back to the label.

/// The values a letter can use, each with the name shown to the admin in the template designer.
const Map<String, String> kLetterAutoFields = {
  'student_name': 'Student Name',
  'student_reg_no': 'Student Reg. No.',
  'student_ic': 'Student IC Number',
  'student_email': 'Student Email',
  'student_phone': 'Student Phone',
  'student_address': 'Student Address',
  'student_dob': 'Student Date of Birth',
  'programme': 'Programme',
  'faculty': 'Faculty',
  'semester': 'Semester',
  'cgpa': 'CGPA',
  'company_name': 'Company Name',
  'company_address': 'Company Address',
  'company_supervisor': 'Company Supervisor',
  'hr_name': 'Company HR Contact',
  'job_title': 'Job Title / Role',
  'intake_name': 'Intake',
  'internship_start': 'Internship Start Date',
  'internship_end': 'Internship End Date',
  'internship_months': 'Internship Length (months)',
  'today_date': "Today's Date",
};

const Map<String, String> _aliases = {
  'name': 'student_name',
  'full_name': 'student_name',
  'student': 'student_name',
  'student_full_name': 'student_name',
  'reg_no': 'student_reg_no',
  'registration_no': 'student_reg_no',
  'registration_number': 'student_reg_no',
  'student_id': 'student_reg_no',
  'student_no': 'student_reg_no',
  'matric_no': 'student_reg_no',
  'id_no': 'student_reg_no',
  'ic': 'student_ic',
  'ic_no': 'student_ic',
  'ic_number': 'student_ic',
  'nric': 'student_ic',
  'nric_no': 'student_ic',
  'identity_no': 'student_ic',
  'mykad': 'student_ic',
  'email': 'student_email',
  'email_address': 'student_email',
  'phone': 'student_phone',
  'phone_no': 'student_phone',
  'phone_number': 'student_phone',
  'tel': 'student_phone',
  'tel_no': 'student_phone',
  'telephone': 'student_phone',
  'contact_no': 'student_phone',
  'contact_number': 'student_phone',
  'mobile': 'student_phone',
  'mobile_no': 'student_phone',
  'hp': 'student_phone',
  'address': 'student_address',
  'home_address': 'student_address',
  'residential_address': 'student_address',
  'dob': 'student_dob',
  'date_of_birth': 'student_dob',
  'birth_date': 'student_dob',
  'program': 'programme',
  'course': 'programme',
  'company': 'company_name',
  'organisation': 'company_name',
  'organization': 'company_name',
  'company_supervisor_name': 'company_supervisor',
  'supervisor': 'company_supervisor',
  'supervisor_name': 'company_supervisor',
  'hr': 'hr_name',
  'hr_contact': 'hr_name',
  'position': 'job_title',
  'role': 'job_title',
  'designation': 'job_title',
  'job': 'job_title',
  'intake': 'intake_name',
  'start_date': 'internship_start',
  'date_start': 'internship_start',
  'from_date': 'internship_start',
  'end_date': 'internship_end',
  'date_end': 'internship_end',
  'to_date': 'internship_end',
  'duration': 'internship_months',
  'date': 'today_date',
  'today': 'today_date',
  'signed_date': 'today_date',
  'date_signed': 'today_date',
};

String _two(int n) => n.toString().padLeft(2, '0');

/// "03/11/2026": the way dates are written on the letters.
String formatLetterDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

String? _isoToLetterDate(dynamic iso) {
  final d = DateTime.tryParse(iso?.toString() ?? '');
  return d == null ? null : formatLetterDate(d);
}

String? _text(dynamic v) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? null : s;
}

/// The value map of one letter, from the JSON `letter_context` returns. Values that are not known are left out, so a
/// field that has no value stays empty for the person to fill in.
Map<String, String> letterValuesFromContext(Map<String, dynamic> context, {DateTime? today}) {
  final student = Map<String, dynamic>.from((context['student'] as Map?) ?? const {});
  final company = Map<String, dynamic>.from((context['company'] as Map?) ?? const {});
  final internship = Map<String, dynamic>.from((context['internship'] as Map?) ?? const {});
  final cgpa = student['cgpa'];
  final values = <String, String?>{
    'student_name': _text(student['name']),
    'student_reg_no': _text(student['reg_no']),
    'student_ic': _text(student['ic']),
    'student_email': _text(student['email']),
    'student_phone': _text(student['phone']),
    'student_address': _text(student['address']),
    'student_dob': _isoToLetterDate(student['dob']),
    'programme': _text(student['programme']),
    'faculty': _text(student['faculty']),
    'semester': _text(student['semester']),
    'cgpa': cgpa is num ? cgpa.toStringAsFixed(2) : _text(cgpa),
    'company_name': _text(company['name']),
    'company_address': _text(company['address']),
    'company_supervisor': _text(company['supervisor']),
    'hr_name': _text(company['hr_name']),
    'job_title': _text(internship['job_title']),
    'intake_name': _text(internship['intake']),
    'internship_start': _isoToLetterDate(internship['start']),
    'internship_end': _isoToLetterDate(internship['end']),
    'internship_months': _text(internship['months']),
    'today_date': formatLetterDate(today ?? DateTime.now()),
  };
  return {for (final e in values.entries) if (e.value != null) e.key: e.value!};
}

String _normalize(String key) => key
    .toLowerCase()
    .trim()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '')
    .replaceFirst(RegExp(r'_\d+$'), '');

String? _lookup(Map<String, String> values, String key) {
  final k = _normalize(key);
  if (k.isEmpty) return null;
  return values[k] ?? (values.containsKey(_aliases[k]) ? values[_aliases[k]] : null);
}

/// The value for a template field: by its key, else (when the key is a free name such as "text_2") by its label.
String? resolveLetterValue(Map<String, String> values, {required String key, String? label}) {
  final byKey = _lookup(values, key);
  if (byKey != null) return byKey;
  return label == null ? null : _lookup(values, label);
}

/// "03/11/2026" back to a date (the letters' date fields hold dates, the values are text).
DateTime? parseLetterDate(String? text) {
  final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text?.trim() ?? '');
  if (m == null) return null;
  final day = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final year = int.parse(m.group(3)!);
  final d = DateTime(year, month, day);
  return d.month == month && d.day == day ? d : null;
}
