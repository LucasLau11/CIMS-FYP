import 'lang.dart';

/// Field validation rules for the whole app.
///
/// Every function takes the raw value and returns `null` when it is valid, or
/// a short, specific message that tells the person exactly what to fix. The
/// message is in the language the app is showing (English, Malay or Chinese).
/// Keeping the rules here (no widgets, no Supabase) means the same rule is used
/// by the live field checks and by the submit buttons, and it is unit-tested.
/// A written reason (rejecting, cancelling, rescheduling, declining) must have at least this many
/// characters, so "no" or "x" cannot stand as an explanation. The database enforces the same number.
const int kMinReasonLength = 100;

class Validators {
  Validators._();

  static String _req(String field) {
    final f = fieldLabel(field);
    return tr('$field is required.', ms: '$f diperlukan.', zh: '$f不能为空。');
  }

  // ---------------------------------------------------------------- generic

  /// A value that must not be blank.
  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return _req(field);
    return null;
  }

  /// Text with optional length limits. [min] only applies when something has
  /// been typed or the field is [required].
  static String? text(
    String? value, {
    String field = 'This field',
    bool required = true,
    int min = 0,
    int max = 1000,
  }) {
    final v = value?.trim() ?? '';
    final f = fieldLabel(field);
    if (v.isEmpty) return required ? _req(field) : null;
    if (v.length < min) {
      return tr('$field must be at least $min characters (now ${v.length}).',
          ms: '$f mesti sekurang-kurangnya $min aksara (sekarang ${v.length}).',
          zh: '$f至少需要 $min 个字符（当前 ${v.length} 个）。');
    }
    if (v.length > max) {
      return tr('$field must be at most $max characters (now ${v.length}).',
          ms: '$f mesti tidak melebihi $max aksara (sekarang ${v.length}).',
          zh: '$f最多 $max 个字符（当前 ${v.length} 个）。');
    }
    return null;
  }

  // ------------------------------------------------------------------ email

  static const List<String> allowedEmailDomains = [
    'outlook.com',
    'gmail.com',
    'hotmail.com',
    'student.tarc.edu.my',
    'tarc.edu.my',
  ];

  static final RegExp _emailFormat = RegExp(r'^[\w.\-+]+@[\w\-]+(\.[\w\-]+)+$');

  /// Format only (used when logging in, so an older account is never locked
  /// out by a domain rule). Like [email], it only judges what was typed; it
  /// never says whether an account exists (that would let anyone discover who
  /// is registered).
  static String? emailFormat(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return tr('Email is required.', ms: 'E-mel diperlukan.', zh: '邮箱不能为空。');
    if (v.length > 254) return tr('Email is too long.', ms: 'E-mel terlalu panjang.', zh: '邮箱过长。');
    if (!v.contains('@')) {
      return tr('Email must contain "@", for example name@gmail.com.',
          ms: 'E-mel mesti mengandungi "@", contohnya name@gmail.com.',
          zh: '邮箱必须包含“@”，例如 name@gmail.com。');
    }
    if (!_emailFormat.hasMatch(v)) {
      return tr('Enter a valid email address, for example name@gmail.com.',
          ms: 'Masukkan alamat e-mel yang sah, contohnya name@gmail.com.',
          zh: '请输入有效的邮箱地址，例如 name@gmail.com。');
    }
    return null;
  }

  /// Format plus the allowed-domain list (used when signing up).
  static String? email(String? value) {
    final format = emailFormat(value);
    if (format != null) return format;
    final v = value!.trim();
    final lower = v.toLowerCase();
    if (!allowedEmailDomains.any((d) => lower.endsWith('@$d'))) {
      return tr(
          'Email must end with @gmail.com, @outlook.com, @hotmail.com, '
          '@student.tarc.edu.my or @tarc.edu.my.',
          ms: 'E-mel mesti berakhir dengan @gmail.com, @outlook.com, @hotmail.com, '
              '@student.tarc.edu.my atau @tarc.edu.my.',
          zh: '邮箱必须以 @gmail.com、@outlook.com、@hotmail.com、'
              '@student.tarc.edu.my 或 @tarc.edu.my 结尾。');
    }
    return null;
  }

  // --------------------------------------------------------------- password

  /// bcrypt only reads the first 72 bytes, so longer passwords add no safety.
  static const int passwordMaxLength = 72;

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return tr('Password is required.', ms: 'Kata laluan diperlukan.', zh: '密码不能为空。');
    if (v.length < 8) {
      return tr('Password must be at least 8 characters (now ${v.length}).',
          ms: 'Kata laluan mesti sekurang-kurangnya 8 aksara (sekarang ${v.length}).',
          zh: '密码至少需要 8 个字符（当前 ${v.length} 个）。');
    }
    if (v.length > passwordMaxLength) {
      return tr('Password must be at most $passwordMaxLength characters.',
          ms: 'Kata laluan mesti tidak melebihi $passwordMaxLength aksara.',
          zh: '密码最多 $passwordMaxLength 个字符。');
    }
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return tr('Add at least one uppercase letter (A-Z).', ms: 'Tambah sekurang-kurangnya satu huruf besar (A-Z).', zh: '请至少添加一个大写字母（A-Z）。');
    }
    if (!RegExp(r'[a-z]').hasMatch(v)) {
      return tr('Add at least one lowercase letter (a-z).', ms: 'Tambah sekurang-kurangnya satu huruf kecil (a-z).', zh: '请至少添加一个小写字母（a-z）。');
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) {
      return tr('Add at least one number (0-9).', ms: 'Tambah sekurang-kurangnya satu nombor (0-9).', zh: '请至少添加一个数字（0-9）。');
    }
    if (!_hasSymbol(v)) {
      return tr(r'Add at least one symbol, for example ! @ # $ %.',
          ms: r'Tambah sekurang-kurangnya satu simbol, contohnya ! @ # $ %.',
          zh: r'请至少添加一个符号，例如 ! @ # $ %。');
    }
    return null;
  }

  static bool _hasSymbol(String v) => RegExp(r'[^A-Za-z0-9\s]').hasMatch(v);

  /// One entry per password rule, for the live checklist under a password
  /// field.
  static List<PasswordCheck> passwordChecks(String value) => [
        PasswordCheck(tr('At least 8 characters', ms: 'Sekurang-kurangnya 8 aksara', zh: '至少 8 个字符'), value.length >= 8),
        PasswordCheck(tr('An uppercase letter', ms: 'Satu huruf besar', zh: '一个大写字母'), RegExp(r'[A-Z]').hasMatch(value)),
        PasswordCheck(tr('A lowercase letter', ms: 'Satu huruf kecil', zh: '一个小写字母'), RegExp(r'[a-z]').hasMatch(value)),
        PasswordCheck(tr('A number', ms: 'Satu nombor', zh: '一个数字'), RegExp(r'[0-9]').hasMatch(value)),
        PasswordCheck(tr('A symbol (! @ # \$ %)', ms: 'Satu simbol (! @ # \$ %)', zh: '一个符号（! @ # \$ %）'), _hasSymbol(value)),
      ];

  static String? confirmPassword(String? value, String original) {
    final v = value ?? '';
    if (v.isEmpty) {
      return tr('Re-enter your password to confirm it.', ms: 'Masukkan semula kata laluan anda untuk mengesahkannya.', zh: '请再次输入密码以确认。');
    }
    if (v != original) return tr('Passwords do not match.', ms: 'Kata laluan tidak sepadan.', zh: '两次输入的密码不一致。');
    return null;
  }

  // -------------------------------------------------------------- one-time code

  static String? otpCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return tr('Enter the code from your email.', ms: 'Masukkan kod daripada e-mel anda.', zh: '请输入邮件中的验证码。');
    if (!RegExp(r'^\d+$').hasMatch(v)) return tr('The code contains digits only.', ms: 'Kod hanya mengandungi digit.', zh: '验证码只包含数字。');
    // Supabase sends 6 digits by default but the project can be set to up to 10;
    // accept the whole range so the app keeps working if that setting changes.
    if (v.length < 6) {
      return tr('The code has at least 6 digits (you have entered ${v.length}).',
          ms: 'Kod mempunyai sekurang-kurangnya 6 digit (anda telah memasukkan ${v.length}).',
          zh: '验证码至少有 6 位数字（您输入了 ${v.length} 位）。');
    }
    if (v.length > 10) return tr('The code has at most 10 digits.', ms: 'Kod mempunyai paling banyak 10 digit.', zh: '验证码最多 10 位数字。');
    return null;
  }

  // ------------------------------------------------------------------ people

  static final RegExp _nameFormat = RegExp(r"^[\p{L}][\p{L}\s.'’\-]*$", unicode: true);

  static String? fullName(String? value, {String field = 'Full name'}) {
    final v = value?.trim() ?? '';
    final f = fieldLabel(field);
    if (v.isEmpty) return _req(field);
    if (v.length < 2) return tr('$field is too short.', ms: '$f terlalu pendek.', zh: '$f过短。');
    if (v.length > 100) {
      return tr('$field must be at most 100 characters.', ms: '$f mesti tidak melebihi 100 aksara.', zh: '$f最多 100 个字符。');
    }
    if (!_nameFormat.hasMatch(v)) {
      return tr("$field may only contain letters, spaces and . ' - (no digits or symbols).",
          ms: "$f hanya boleh mengandungi huruf, ruang dan . ' - (tiada digit atau simbol).",
          zh: "$f只能包含字母、空格以及 . ' -（不能有数字或符号）。");
    }
    return null;
  }

  /// Malaysian mobile / landline, or an international number written with a
  /// leading + (companies and exchange students may have one).
  static String? phone(String? value, {bool required = true}) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return required ? tr('Phone number is required.', ms: 'Nombor telefon diperlukan.', zh: '电话号码不能为空。') : null;
    if (RegExp(r'[^0-9+\-\s()]').hasMatch(raw)) {
      return tr('Phone number may only contain digits, spaces, + and -.',
          ms: 'Nombor telefon hanya boleh mengandungi digit, ruang, + dan -.',
          zh: '电话号码只能包含数字、空格、+ 和 -。');
    }
    final digits = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    final malaysianMobile = RegExp(r'^(?:\+?60|0)1\d{8,9}$');
    final malaysianLandline = RegExp(r'^(?:\+?60|0)[3-9]\d{7,8}$');
    final international = RegExp(r'^\+(?!60)\d{8,14}$');
    if (malaysianMobile.hasMatch(digits) ||
        malaysianLandline.hasMatch(digits) ||
        international.hasMatch(digits)) {
      return null;
    }
    return tr('Enter a valid phone number, for example 012-345 6789 or +60 12-345 6789.',
        ms: 'Masukkan nombor telefon yang sah, contohnya 012-345 6789 atau +60 12-345 6789.',
        zh: '请输入有效的电话号码，例如 012-345 6789 或 +60 12-345 6789。');
  }

  static String? dateOfBirth(DateTime? value, {DateTime? today, int minAge = 15}) {
    if (value == null) return tr('Date of birth is required.', ms: 'Tarikh lahir diperlukan.', zh: '出生日期不能为空。');
    final now = today ?? DateTime.now();
    if (value.isAfter(now)) {
      return tr('Date of birth cannot be in the future.', ms: 'Tarikh lahir tidak boleh pada masa hadapan.', zh: '出生日期不能是未来的日期。');
    }
    var age = now.year - value.year;
    if (now.month < value.month || (now.month == value.month && now.day < value.day)) age--;
    if (age < minAge) {
      return tr('You must be at least $minAge years old.', ms: 'Anda mesti berumur sekurang-kurangnya $minAge tahun.', zh: '您必须年满 $minAge 岁。');
    }
    if (age > 100) return tr('Enter a valid date of birth.', ms: 'Masukkan tarikh lahir yang sah.', zh: '请输入有效的出生日期。');
    return null;
  }

  /// TARUMT student registration number such as 24WMR12345 (optional).
  /// A Malaysian IC number: 12 digits, written 030514-10-1234 or 030514101234. Optional.
  static String? icNumber(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^\d{6}-?\d{2}-?\d{4}$').hasMatch(v)) {
      return tr('Use the format 030514-10-1234 (12 digits).', ms: 'Gunakan format 030514-10-1234 (12 digit).', zh: '请使用 030514-10-1234 的格式（12 位数字）。');
    }
    return null;
  }

  /// 030514101234 or 030514-10-1234 -> 030514-10-1234 (how it is written on a letter).
  static String normalizeIc(String value) {
    final d = value.replaceAll(RegExp(r'\D'), '');
    return d.length == 12 ? '${d.substring(0, 6)}-${d.substring(6, 8)}-${d.substring(8)}' : value.trim();
  }

  static String? studentRegNo(String? value, {bool required = false}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? tr('Registration number is required.', ms: 'Nombor pendaftaran diperlukan.', zh: '学号不能为空。') : null;
    if (!RegExp(r'^\d{2}[A-Za-z]{3}\d{5}$').hasMatch(v)) {
      return tr('Use the format 24WMR12345 (2 digits, 3 letters, 5 digits).',
          ms: 'Gunakan format 24WMR12345 (2 digit, 3 huruf, 5 digit).',
          zh: '请使用 24WMR12345 的格式（2 位数字、3 个字母、5 位数字）。');
    }
    return null;
  }

  /// One skill tag. [existing] are the skills already added (compared
  /// ignoring case) so the same one cannot be added twice.
  static String? skill(String? value, {List<String> existing = const [], int maxSkills = 30}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // nothing typed yet is not an error
    if (v.length < 2) return tr('A skill needs at least 2 characters.', ms: 'Kemahiran memerlukan sekurang-kurangnya 2 aksara.', zh: '技能至少需要 2 个字符。');
    if (v.length > 40) {
      return tr('A skill can be at most 40 characters (now ${v.length}).',
          ms: 'Kemahiran boleh mempunyai paling banyak 40 aksara (sekarang ${v.length}).',
          zh: '技能最多 40 个字符（当前 ${v.length} 个）。');
    }
    if (!RegExp(r'^[\p{L}\p{N}][\p{L}\p{N}\s.+#&/\-]*$', unicode: true).hasMatch(v)) {
      return tr('Skills may only use letters, numbers, spaces and . + # & / -',
          ms: 'Kemahiran hanya boleh menggunakan huruf, nombor, ruang dan . + # & / -',
          zh: '技能只能使用字母、数字、空格以及 . + # & / -');
    }
    if (existing.any((s) => s.toLowerCase() == v.toLowerCase())) {
      return tr('"$v" is already in your list.', ms: '"$v" sudah ada dalam senarai anda.', zh: '“$v”已在您的列表中。');
    }
    if (existing.length >= maxSkills) {
      return tr('You can add at most $maxSkills skills.', ms: 'Anda boleh menambah paling banyak $maxSkills kemahiran.', zh: '最多可添加 $maxSkills 项技能。');
    }
    return null;
  }

  // ----------------------------------------------------------------- academic

  /// CGPA between 0.00 and 4.00 with at most two decimals.
  static String? cgpa(String? value, {bool required = true}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? tr('CGPA is required.', ms: 'CGPA diperlukan.', zh: 'CGPA 不能为空。') : null;
    if (!RegExp(r'^\d(\.\d{1,2})?$').hasMatch(v)) {
      return tr('Enter CGPA as a number such as 3.50 (at most 2 decimals).',
          ms: 'Masukkan CGPA sebagai nombor seperti 3.50 (paling banyak 2 perpuluhan).',
          zh: '请将 CGPA 输入为数字，例如 3.50（最多 2 位小数）。');
    }
    final n = double.parse(v);
    if (n < 0 || n > 4.0) return tr('CGPA must be between 0.00 and 4.00.', ms: 'CGPA mesti antara 0.00 dan 4.00.', zh: 'CGPA 必须在 0.00 到 4.00 之间。');
    return null;
  }

  static String? semester(int? value, {int max = 4}) {
    if (value == null) return tr('Select your semester.', ms: 'Pilih semester anda.', zh: '请选择您的学期。');
    if (value < 1 || value > max) {
      return tr('Semester must be between 1 and $max.', ms: 'Semester mesti antara 1 dan $max.', zh: '学期必须在 1 到 $max 之间。');
    }
    return null;
  }

  /// A whole number inside [min]..[max].
  static String? wholeNumber(
    String? value, {
    required String field,
    required int min,
    required int max,
    bool required = true,
  }) {
    final v = value?.trim() ?? '';
    final f = fieldLabel(field);
    if (v.isEmpty) return required ? _req(field) : null;
    if (!RegExp(r'^\d+$').hasMatch(v)) {
      return tr('$field must be a whole number.', ms: '$f mesti nombor bulat.', zh: '$f必须是整数。');
    }
    final n = int.parse(v);
    if (n < min || n > max) {
      return tr('$field must be between $min and $max.', ms: '$f mesti antara $min dan $max.', zh: '$f必须在 $min 到 $max 之间。');
    }
    return null;
  }

  /// A money amount, not negative, at most two decimals.
  static String? money(
    String? value, {
    String field = 'Amount',
    bool required = true,
    double max = 100000,
  }) {
    final v = value?.trim() ?? '';
    final f = fieldLabel(field);
    if (v.isEmpty) return required ? _req(field) : null;
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v)) {
      return tr('$field must be a number such as 800 or 800.50.', ms: '$f mesti nombor seperti 800 atau 800.50.', zh: '$f必须是数字，例如 800 或 800.50。');
    }
    if (double.parse(v) > max) {
      return tr('$field is too large (maximum ${max.toStringAsFixed(0)}).',
          ms: '$f terlalu besar (maksimum ${max.toStringAsFixed(0)}).',
          zh: '$f过大（最大 ${max.toStringAsFixed(0)}）。');
    }
    return null;
  }

  static String? year(String? value, {String field = 'Year', bool required = true, DateTime? today}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? _req(field) : null;
    final now = today ?? DateTime.now();
    return wholeNumber(v, field: field, min: 1980, max: now.year + 1, required: required);
  }

  // -------------------------------------------------------------- dates / times

  static String? dateNotInPast(DateTime? value, {String field = 'Date', DateTime? today}) {
    if (value == null) return _req(field);
    final now = today ?? DateTime.now();
    final d = DateTime(value.year, value.month, value.day);
    final t = DateTime(now.year, now.month, now.day);
    final f = fieldLabel(field);
    if (d.isBefore(t)) return tr('$field cannot be in the past.', ms: '$f tidak boleh pada masa lalu.', zh: '$f不能是过去的日期。');
    return null;
  }

  /// [end] must come after [start] (same day is not allowed).
  static String? endAfterStart(DateTime? start, DateTime? end,
      {String startLabel = 'start date', String endLabel = 'End date'}) {
    if (end == null) return _req(endLabel);
    if (start == null) return null; // the start field reports its own error
    if (!end.isAfter(start)) {
      final e = fieldLabel(endLabel);
      final s = fieldLabel(startLabel);
      return tr('$endLabel must be after the $startLabel.', ms: '$e mesti selepas $s.', zh: '$e必须晚于$s。');
    }
    return null;
  }

  /// A date and time that must be at least [minLead] from now.
  static String? dateTimeInFuture(DateTime? value,
      {String field = 'Date and time', Duration minLead = Duration.zero, DateTime? now}) {
    if (value == null) return _req(field);
    final reference = now ?? DateTime.now();
    final f = fieldLabel(field);
    if (value.isBefore(reference.add(minLead))) {
      return minLead == Duration.zero
          ? tr('$field must be in the future.', ms: '$f mesti pada masa hadapan.', zh: '$f必须是未来的时间。')
          : tr('$field must be at least ${_describe(minLead)} from now.',
              ms: '$f mesti sekurang-kurangnya ${_describe(minLead)} dari sekarang.',
              zh: '$f必须至少在 ${_describe(minLead)} 之后。');
    }
    return null;
  }

  static String _describe(Duration d) {
    if (d.inMinutes % 60 == 0 && d.inHours >= 1) {
      return tr(d.inHours == 1 ? '1 hour' : '${d.inHours} hours', ms: '${d.inHours} jam', zh: '${d.inHours} 小时');
    }
    return tr('${d.inMinutes} minutes', ms: '${d.inMinutes} minit', zh: '${d.inMinutes} 分钟');
  }

  // -------------------------------------------------------------------- misc

  static String? url(String? value, {bool required = false}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? tr('A link is required.', ms: 'Pautan diperlukan.', zh: '链接不能为空。') : null;
    final uri = Uri.tryParse(v);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty || !uri.host.contains('.')) {
      return tr('Enter a full link starting with https://', ms: 'Masukkan pautan penuh bermula dengan https://', zh: '请输入以 https:// 开头的完整链接');
    }
    return null;
  }

  /// A rating between [min] and [max] given as a number.
  static String? rating(num? value, {int min = 1, int max = 5, String field = 'Rating'}) {
    if (value == null) return _req(field);
    if (value < min || value > max) {
      final f = fieldLabel(field);
      return tr('$field must be between $min and $max.', ms: '$f mesti antara $min dan $max.', zh: '$f必须在 $min 到 $max 之间。');
    }
    return null;
  }
}

/// One row of the live password checklist.
class PasswordCheck {
  final String label;
  final bool met;
  const PasswordCheck(this.label, this.met);
}
