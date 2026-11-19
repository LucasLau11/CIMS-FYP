import 'validators.dart';

/// One student the administrator wants an account for, read from a pasted list
/// or a CSV file, with the reason it cannot be created if it is not valid.
class StudentDraft {
  const StudentDraft({
    required this.line,
    required this.email,
    required this.fullName,
    this.regNo = '',
    this.programme = '',
    this.problem,
  });

  /// 1-based line in the pasted text / file, for error messages.
  final int line;
  final String email;
  final String fullName;
  final String regNo;
  final String programme;
  final String? problem;

  bool get ok => problem == null;

  Map<String, String> toJson() => {
        'email': email,
        'full_name': fullName,
        if (regNo.isNotEmpty) 'student_reg_no': regNo,
        if (programme.isNotEmpty) 'programme': programme,
      };
}

/// Reads student rows such as
///
///     email,full_name,student_reg_no,programme
///     ali@student.tarc.edu.my,Ali bin Abu,24WMR12345,Software Engineering
///
/// The header row is optional. Commas, semicolons and tabs are all accepted
/// (spreadsheets export any of them), and values may be quoted. Without a
/// header, the cell containing an "@" is the email and the others are, in
/// order, the name, registration number and programme.
class StudentImport {
  StudentImport._();

  static const int maxStudents = 200;

  /// [studentFields] false reads supervisor rows (email and name only): the
  /// registration number and programme are ignored.
  static List<StudentDraft> parse(String text, {bool studentFields = true}) {
    final lines = text.split(RegExp(r'\r?\n'));
    final nonEmpty = <int>[for (var i = 0; i < lines.length; i++) if (lines[i].trim().isNotEmpty) i];
    if (nonEmpty.isEmpty) return const [];

    final delimiter = _delimiterFor(lines[nonEmpty.first]);
    final rows = <(int, List<String>)>[
      for (final i in nonEmpty) (i + 1, _split(lines[i], delimiter).map((c) => c.trim()).toList()),
    ];

    // Header: the first row has no "@" and names an email column.
    Map<String, int>? columns;
    final first = rows.first.$2;
    if (!first.any((c) => c.contains('@')) && first.any((c) => _isEmailHeader(c))) {
      columns = {};
      for (var i = 0; i < first.length; i++) {
        final key = _headerKey(first[i]);
        if (key != null) columns.putIfAbsent(key, () => i);
      }
      rows.removeAt(0);
    }

    final drafts = <StudentDraft>[];
    final seen = <String>{};
    for (final (line, cells) in rows) {
      String email, name, regNo, programme;
      if (columns != null) {
        String at(String key) {
          final i = columns![key];
          return (i == null || i >= cells.length) ? '' : cells[i];
        }

        email = at('email');
        name = at('name');
        regNo = studentFields ? at('reg') : '';
        programme = studentFields ? at('programme') : '';
      } else {
        final emailIndex = cells.indexWhere((c) => c.contains('@'));
        final at = emailIndex < 0 ? 0 : emailIndex;
        email = cells.isEmpty ? '' : cells[at];
        final rest = [for (var i = 0; i < cells.length; i++) if (i != at) cells[i]];
        name = rest.isNotEmpty ? rest[0] : '';
        regNo = studentFields && rest.length > 1 ? rest[1] : '';
        programme = studentFields && rest.length > 2 ? rest[2] : '';
      }

      String? problem = Validators.emailFormat(email) ?? Validators.fullName(name) ?? Validators.studentRegNo(regNo);
      if (problem == null && programme.length > 150) problem = 'The programme is too long (150 characters at most).';
      if (problem == null && !seen.add(email.toLowerCase())) problem = 'This email appears more than once in the list.';
      drafts.add(StudentDraft(line: line, email: email, fullName: name, regNo: regNo, programme: programme, problem: problem));
    }
    return drafts;
  }

  static String _delimiterFor(String line) {
    var best = ',';
    var bestCount = -1;
    for (final d in [',', ';', '\t']) {
      final count = d.allMatches(line).length;
      if (count > bestCount) {
        best = d;
        bestCount = count;
      }
    }
    return best;
  }

  static bool _isEmailHeader(String cell) => _headerKey(cell) == 'email';

  static String? _headerKey(String cell) {
    final c = cell.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (c == 'email' || c == 'emailaddress' || c == 'studentemail') return 'email';
    if (c == 'name' || c == 'fullname' || c == 'studentname') return 'name';
    if (c == 'studentregno' || c == 'regno' || c == 'registrationnumber' || c == 'studentid' || c == 'reg') return 'reg';
    if (c == 'programme' || c == 'program') return 'programme';
    return null;
  }

  /// Splits one line at [delimiter], honouring "double quoted" values.
  static List<String> _split(String line, String delimiter) {
    final cells = <String>[];
    final cur = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (quoted) {
        if (c == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            cur.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          cur.write(c);
        }
      } else if (c == '"') {
        quoted = true;
      } else if (c == delimiter) {
        cells.add(cur.toString());
        cur.clear();
      } else {
        cur.write(c);
      }
    }
    cells.add(cur.toString());
    return cells;
  }
}
