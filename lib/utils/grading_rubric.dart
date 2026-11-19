import 'lang.dart';

/// The university's marking rubrics: the academic supervisor's 40 marks (progress and final reports) and the company supervisor's 60 (further down).
///
///   progress report: submission (CLO6) 0-4 + content (CLO1) 0-6                      = 10
///   final report:    submission (CLO6) 0-4 + written presentation (CLO4) 0-6
///                    + awareness of business and entrepreneurial opportunities (CLO5) 0-10
///                    + overall content (CLO4) 0-10                                    = 30
///
/// A student's progress marks are the average over their graded progress reports (10 at most); the final
/// report counts in full (30 at most). The company supervisor's evaluation is the other 60.
/// The database checks the same limits (migration 00045).
class RubricBand {
  const RubricBand(this.min, this.max, this.label, this.text);

  /// The marks this band covers (the same number twice for a single mark).
  final int min;
  final int max;
  final String Function() label;
  final String Function() text;

  bool contains(int mark) => mark >= min && mark <= max;
}

class RubricCriterion {
  const RubricCriterion(this.key, this.maxMark, this.name, this.shortName, this.bands);

  /// The key in the `marks` JSON of the review ("submission", "content", "written", "awareness").
  final String key;
  final int maxMark;
  final String Function() name;
  final String Function() shortName;
  final List<RubricBand> bands;

  RubricBand? bandOf(int mark) {
    for (final b in bands) {
      if (b.contains(mark)) return b;
    }
    return null;
  }
}

String _veryPoor() => tr('Very Poor', ms: 'Sangat Lemah', zh: '很差');
String _poor() => tr('Poor', ms: 'Lemah', zh: '较差');
String _average() => tr('Average', ms: 'Sederhana', zh: '一般');
String _good() => tr('Good', ms: 'Baik', zh: '良好');
String _excellent() => tr('Excellent', ms: 'Cemerlang', zh: '优秀');

final RubricCriterion _progressSubmission = RubricCriterion(
  'submission',
  4,
  () => tr('Submission of progress reports (CLO6)', ms: 'Penghantaran laporan kemajuan (CLO6)', zh: '进度报告的提交（CLO6）'),
  () => tr('Submission', ms: 'Penghantaran', zh: '提交'),
  [
    RubricBand(0, 0, _veryPoor, () => tr('No submission', ms: 'Tiada penghantaran', zh: '未提交')),
    RubricBand(1, 1, _poor, () => tr('Always late for all submissions', ms: 'Sentiasa lewat bagi semua penghantaran', zh: '所有提交都迟交')),
    RubricBand(2, 2, _average, () => tr('Late two times or more', ms: 'Lewat dua kali atau lebih', zh: '迟交两次或以上')),
    RubricBand(3, 3, _good, () => tr('Late one time', ms: 'Lewat sekali', zh: '迟交一次')),
    RubricBand(4, 4, _excellent, () => tr('Always punctual', ms: 'Sentiasa menepati masa', zh: '总是准时')),
  ],
);

final RubricCriterion _progressContent = RubricCriterion(
  'content',
  6,
  () => tr('Content of progress reports (CLO1)', ms: 'Kandungan laporan kemajuan (CLO1)', zh: '进度报告的内容（CLO1）'),
  () => tr('Content', ms: 'Kandungan', zh: '内容'),
  [
    RubricBand(0, 0, _veryPoor, () => tr('No submission or poorly written reports', ms: 'Tiada penghantaran atau laporan ditulis dengan teruk', zh: '未提交或报告写得很差')),
    RubricBand(
        1,
        2,
        _poor,
        () => tr('Description of technical work done is too brief/insufficient with many grammatical and spelling mistakes',
            ms: 'Penerangan kerja teknikal terlalu ringkas/tidak mencukupi dengan banyak kesilapan tatabahasa dan ejaan',
            zh: '所做技术工作的描述过于简短/不足，有许多语法和拼写错误')),
    RubricBand(
        3,
        3,
        _average,
        () => tr('Description of technical work done is average and sufficient with some grammatical and spelling mistakes',
            ms: 'Penerangan kerja teknikal sederhana dan mencukupi dengan beberapa kesilapan tatabahasa dan ejaan',
            zh: '所做技术工作的描述一般且足够，有一些语法和拼写错误')),
    RubricBand(
        4,
        5,
        _good,
        () => tr('Description of technical work done is adequate with negligible grammatical and spelling mistakes',
            ms: 'Penerangan kerja teknikal memadai dengan kesilapan tatabahasa dan ejaan yang boleh diabaikan',
            zh: '所做技术工作的描述适当，语法和拼写错误可忽略')),
    RubricBand(
        6,
        6,
        _excellent,
        () => tr('Description of technical work done is excellent with negligible or no grammatical and spelling mistakes',
            ms: 'Penerangan kerja teknikal cemerlang dengan kesilapan tatabahasa dan ejaan yang boleh diabaikan atau tiada',
            zh: '所做技术工作的描述优秀，语法和拼写错误可忽略或没有')),
  ],
);

final RubricCriterion _finalSubmission = RubricCriterion(
  'submission',
  4,
  () => tr('Submission of final report (CLO6)', ms: 'Penghantaran laporan akhir (CLO6)', zh: '期末报告的提交（CLO6）'),
  () => tr('Submission', ms: 'Penghantaran', zh: '提交'),
  [
    RubricBand(0, 0, _veryPoor, () => tr('No submission', ms: 'Tiada penghantaran', zh: '未提交')),
    RubricBand(1, 1, _poor, () => tr('Late for 3 days or more', ms: 'Lewat 3 hari atau lebih', zh: '迟交 3 天或以上')),
    RubricBand(2, 2, _average, () => tr('Late for 2 days', ms: 'Lewat 2 hari', zh: '迟交 2 天')),
    RubricBand(3, 3, _good, () => tr('Late for 1 day', ms: 'Lewat 1 hari', zh: '迟交 1 天')),
    RubricBand(4, 4, _excellent, () => tr('On time', ms: 'Tepat pada masanya', zh: '准时')),
  ],
);

final RubricCriterion _finalWritten = RubricCriterion(
  'written',
  6,
  () => tr('Written presentation of final report (CLO4)', ms: 'Pembentangan bertulis laporan akhir (CLO4)', zh: '期末报告的书面表达（CLO4）'),
  () => tr('Written presentation', ms: 'Pembentangan bertulis', zh: '书面表达'),
  [
    RubricBand(0, 0, _veryPoor, () => tr('No submission or poorly presented final report', ms: 'Tiada penghantaran atau laporan akhir dibentangkan dengan teruk', zh: '未提交或期末报告呈现很差')),
    RubricBand(
        1,
        2,
        _poor,
        () => tr('Poorly structured, difficult to read and many grammatical and spelling mistakes',
            ms: 'Struktur lemah, sukar dibaca dan banyak kesilapan tatabahasa dan ejaan', zh: '结构差，难以阅读，有许多语法和拼写错误')),
    RubricBand(
        3,
        3,
        _average,
        () => tr('Averagely structured, fairly easy to read with some grammatical and spelling mistakes',
            ms: 'Struktur sederhana, agak mudah dibaca dengan beberapa kesilapan tatabahasa dan ejaan', zh: '结构一般，较容易阅读，有一些语法和拼写错误')),
    RubricBand(
        4,
        5,
        _good,
        () => tr('Good structure, easy to read with minor grammatical and spelling mistakes',
            ms: 'Struktur baik, mudah dibaca dengan kesilapan tatabahasa dan ejaan yang kecil', zh: '结构良好，容易阅读，有少量语法和拼写错误')),
    RubricBand(
        6,
        6,
        _excellent,
        () => tr('Excellent structure, easy to read, excellent grammar and correct spelling',
            ms: 'Struktur cemerlang, mudah dibaca, tatabahasa cemerlang dan ejaan betul', zh: '结构优秀，容易阅读，语法优秀，拼写正确')),
  ],
);

final RubricCriterion _finalAwareness = RubricCriterion(
  'awareness',
  10,
  () => tr('Awareness of business and entrepreneurial opportunities (CLO5)',
      ms: 'Kesedaran tentang peluang perniagaan dan keusahawanan (CLO5)', zh: '对商业和创业机会的认识（CLO5）'),
  () => tr('Business awareness', ms: 'Kesedaran perniagaan', zh: '商业认识'),
  [
    RubricBand(0, 0, _veryPoor, () => tr('No submission or evidence in report on this awareness', ms: 'Tiada penghantaran atau bukti dalam laporan tentang kesedaran ini', zh: '未提交，或报告中没有体现这种认识')),
    RubricBand(1, 4, _poor, () => tr('One or two statements in report on this awareness', ms: 'Satu atau dua pernyataan dalam laporan tentang kesedaran ini', zh: '报告中有一两句关于这种认识的陈述')),
    RubricBand(5, 5, _average, () => tr('Description is vague and awareness is not well highlighted', ms: 'Penerangan kabur dan kesedaran tidak diketengahkan dengan baik', zh: '描述含糊，这种认识没有被很好地突出')),
    RubricBand(6, 7, _good, () => tr('Description is good and awareness is well highlighted', ms: 'Penerangan baik dan kesedaran diketengahkan dengan baik', zh: '描述良好，这种认识被很好地突出')),
    RubricBand(8, 10, _excellent, () => tr('Excellent description and awareness is strongly emphasized', ms: 'Penerangan cemerlang dan kesedaran ditekankan dengan kuat', zh: '描述优秀，这种认识被着重强调')),
  ],
);

final RubricCriterion _finalContent = RubricCriterion(
  'content',
  10,
  () => tr('Overall content of final report (CLO4)', ms: 'Kandungan keseluruhan laporan akhir (CLO4)', zh: '期末报告的整体内容（CLO4）'),
  () => tr('Overall content', ms: 'Kandungan keseluruhan', zh: '整体内容'),
  [
    RubricBand(0, 0, _veryPoor, () => tr('No submission or poorly written final report', ms: 'Tiada penghantaran atau laporan akhir ditulis dengan teruk', zh: '未提交或期末报告写得很差')),
    RubricBand(1, 4, _poor, () => tr('Too brief, poorly written and lack of explanation', ms: 'Terlalu ringkas, ditulis dengan teruk dan kurang penjelasan', zh: '过于简短，写得差，缺乏解释')),
    RubricBand(5, 5, _average, () => tr('Averagely written with some explanations', ms: 'Ditulis secara sederhana dengan beberapa penjelasan', zh: '写得一般，有一些解释')),
    RubricBand(6, 7, _good, () => tr('Good contents with adequate explanations', ms: 'Kandungan baik dengan penjelasan yang memadai', zh: '内容良好，解释充分')),
    RubricBand(8, 10, _excellent, () => tr('Excellent contents with well-written explanations', ms: 'Kandungan cemerlang dengan penjelasan yang ditulis dengan baik', zh: '内容优秀，解释写得很好')),
  ],
);

/// The criteria a progress (monthly) report is marked on, 10 marks in all.
List<RubricCriterion> get progressReportRubric => [_progressSubmission, _progressContent];

/// The criteria the final report is marked on, 30 marks in all.
List<RubricCriterion> get finalReportRubric => [_finalSubmission, _finalWritten, _finalAwareness, _finalContent];

List<RubricCriterion> rubricFor({required bool isFinal}) => isFinal ? finalReportRubric : progressReportRubric;

int rubricMaxTotal({required bool isFinal}) => rubricFor(isFinal: isFinal).fold(0, (sum, c) => sum + c.maxMark);

/// "Submission 4/4 · Content 5/6" for the marks saved on a review.
String marksSummary(Map? marks, {required bool isFinal}) {
  if (marks == null) return '';
  final parts = <String>[];
  for (final c in rubricFor(isFinal: isFinal)) {
    final v = marks[c.key];
    if (v != null) parts.add('${c.shortName()} $v/${c.maxMark}');
  }
  return parts.join(' · ');
}


// ---------------------------------------------------------------------------------------
// The company supervisor's form: 10 criteria marked 0-6 (0 / 1-2 / 3 / 4-5 / 6) = 60 marks, the company's
// share of the overall grade. The database checks the same keys and limits (migration 00046).
// ---------------------------------------------------------------------------------------

/// The five bands every company criterion shares (0, 1-2, 3, 4-5, 6) with their own descriptions.
List<RubricBand> _companyBands(String Function() veryPoor, String Function() poor, String Function() average, String Function() good, String Function() excellent) => [
      RubricBand(0, 0, _veryPoor, veryPoor),
      RubricBand(1, 2, _poor, poor),
      RubricBand(3, 3, _average, average),
      RubricBand(4, 5, _good, good),
      RubricBand(6, 6, _excellent, excellent),
    ];

RubricCriterion _company(String key, String Function() name, String Function() shortName, List<RubricBand> bands) => RubricCriterion(key, 6, name, shortName, bands);

final List<RubricCriterion> _companyRubric = [
  _company(
    'technical_knowledge',
    () => tr('1. Technical Knowledge (CLO1)', ms: '1. Pengetahuan Teknikal (CLO1)', zh: '1. 技术知识（CLO1）'),
    () => tr('Technical knowledge', ms: 'Pengetahuan teknikal', zh: '技术知识'),
    _companyBands(
      () => tr('Has no technical knowledge', ms: 'Tiada pengetahuan teknikal', zh: '没有技术知识'),
      () => tr('Has little technical knowledge', ms: 'Mempunyai sedikit pengetahuan teknikal', zh: '技术知识很少'),
      () => tr('Has sufficient technical knowledge', ms: 'Mempunyai pengetahuan teknikal yang mencukupi', zh: '具有足够的技术知识'),
      () => tr('Has good technical knowledge', ms: 'Mempunyai pengetahuan teknikal yang baik', zh: '具有良好的技术知识'),
      () => tr('Has excellent technical knowledge', ms: 'Mempunyai pengetahuan teknikal yang cemerlang', zh: '具有优秀的技术知识'),
    ),
  ),
  _company(
    'dependability',
    () => tr('2. Dependability (CLO3)', ms: '2. Kebolehpercayaan (CLO3)', zh: '2. 可靠性（CLO3）'),
    () => tr('Dependability', ms: 'Kebolehpercayaan', zh: '可靠性'),
    _companyBands(
      () => tr('Not able to complete any job', ms: 'Tidak dapat menyiapkan sebarang tugas', zh: '无法完成任何工作'),
      () => tr('Needs close supervision and always unreliable in completing job', ms: 'Memerlukan penyeliaan rapi dan sentiasa tidak boleh diharap menyiapkan tugas', zh: '需要密切监督，完成工作总是不可靠'),
      () => tr('Needs a lot of supervision and sometimes unreliable in completing job', ms: 'Memerlukan banyak penyeliaan dan kadangkala tidak boleh diharap menyiapkan tugas', zh: '需要大量监督，完成工作有时不可靠'),
      () => tr('Needs some supervision and reliable in completing job', ms: 'Memerlukan sedikit penyeliaan dan boleh diharap menyiapkan tugas', zh: '需要一些监督，完成工作可靠'),
      () => tr('No need supervision and always reliable in completing job', ms: 'Tidak memerlukan penyeliaan dan sentiasa boleh diharap menyiapkan tugas', zh: '无需监督，完成工作总是可靠'),
    ),
  ),
  _company(
    'initiative',
    () => tr('3. Initiative (CLO4)', ms: '3. Inisiatif (CLO4)', zh: '3. 主动性（CLO4）'),
    () => tr('Initiative', ms: 'Inisiatif', zh: '主动性'),
    _companyBands(
      () => tr('Not willing to learn', ms: 'Tidak sanggup belajar', zh: '不愿意学习'),
      () => tr('Occasionally willing and proactive in learning and working', ms: 'Kadangkala sanggup dan proaktif dalam belajar dan bekerja', zh: '偶尔愿意并主动学习和工作'),
      () => tr('Acceptable willing and proactive in learning and working', ms: 'Sanggup dan proaktif pada tahap yang boleh diterima dalam belajar dan bekerja', zh: '在学习和工作中的意愿和主动性尚可接受'),
      () => tr('Usually willing and proactive in learning and working', ms: 'Biasanya sanggup dan proaktif dalam belajar dan bekerja', zh: '通常愿意并主动学习和工作'),
      () => tr('Always willing and proactive in learning and working', ms: 'Sentiasa sanggup dan proaktif dalam belajar dan bekerja', zh: '总是愿意并主动学习和工作'),
    ),
  ),
  _company(
    'commitment',
    () => tr('4. Commitment (CLO4)', ms: '4. Komitmen (CLO4)', zh: '4. 敬业度（CLO4）'),
    () => tr('Commitment', ms: 'Komitmen', zh: '敬业度'),
    _companyBands(
      () => tr('Not committed in work', ms: 'Tidak komited dalam kerja', zh: '对工作没有投入'),
      () => tr('Not committed in work assigned', ms: 'Tidak komited dalam kerja yang diberikan', zh: '对分配的工作不够投入'),
      () => tr('Acceptable commitment in work assigned', ms: 'Komitmen yang boleh diterima dalam kerja yang diberikan', zh: '对分配的工作投入程度尚可接受'),
      () => tr('Committed in work assigned', ms: 'Komited dalam kerja yang diberikan', zh: '对分配的工作投入'),
      () => tr('Very committed in work assigned', ms: 'Sangat komited dalam kerja yang diberikan', zh: '对分配的工作非常投入'),
    ),
  ),
  _company(
    'quality_of_work',
    () => tr('5. Quality of Work (CLO6)', ms: '5. Kualiti Kerja (CLO6)', zh: '5. 工作质量（CLO6）'),
    () => tr('Quality of work', ms: 'Kualiti kerja', zh: '工作质量'),
    _companyBands(
      () => tr('Very poor quality of work', ms: 'Kualiti kerja sangat lemah', zh: '工作质量很差'),
      () => tr('Performance does not meet the minimum requirement', ms: 'Prestasi tidak memenuhi keperluan minimum', zh: '表现未达到最低要求'),
      () => tr('Performance generally meets the minimum requirement', ms: 'Prestasi secara amnya memenuhi keperluan minimum', zh: '表现基本达到最低要求'),
      () => tr('Performance consistently exceeds the minimum requirement', ms: 'Prestasi secara konsisten melebihi keperluan minimum', zh: '表现持续超过最低要求'),
      () => tr('Performance far exceeds the minimum requirement', ms: 'Prestasi jauh melebihi keperluan minimum', zh: '表现远超最低要求'),
    ),
  ),
  _company(
    'working_relationship',
    () => tr('6. Working Relationship with Staff (CLO3)', ms: '6. Hubungan Kerja dengan Kakitangan (CLO3)', zh: '6. 与员工的工作关系（CLO3）'),
    () => tr('Working relationship', ms: 'Hubungan kerja', zh: '工作关系'),
    _companyBands(
      () => tr('A very poor team member', ms: 'Ahli pasukan yang sangat lemah', zh: '团队成员表现很差'),
      () => tr('Rarely tactful, poor teamwork and not cooperative', ms: 'Jarang bertolak ansur, kerja berpasukan lemah dan tidak bekerjasama', zh: '很少得体，团队合作差，不合作'),
      () => tr('Occasionally tactful, fair teamwork and cooperative', ms: 'Kadangkala bertolak ansur, kerja berpasukan sederhana dan bekerjasama', zh: '偶尔得体，团队合作一般，愿意合作'),
      () => tr('Usually tactful, good teamwork and cooperative', ms: 'Biasanya bertolak ansur, kerja berpasukan baik dan bekerjasama', zh: '通常得体，团队合作良好，愿意合作'),
      () => tr('Always tactful, excellent teamwork and cooperative', ms: 'Sentiasa bertolak ansur, kerja berpasukan cemerlang dan bekerjasama', zh: '总是得体，团队合作优秀，乐于合作'),
    ),
  ),
  _company(
    'discipline',
    () => tr('7. Discipline (CLO6)', ms: '7. Disiplin (CLO6)', zh: '7. 纪律（CLO6）'),
    () => tr('Discipline', ms: 'Disiplin', zh: '纪律'),
    _companyBands(
      () => tr('Did not follow company rules', ms: 'Tidak mematuhi peraturan syarikat', zh: '不遵守公司规定'),
      () => tr('Rarely follow company rules and procedures', ms: 'Jarang mematuhi peraturan dan prosedur syarikat', zh: '很少遵守公司规定和程序'),
      () => tr('Sometimes do not follow company rules and procedures', ms: 'Kadangkala tidak mematuhi peraturan dan prosedur syarikat', zh: '有时不遵守公司规定和程序'),
      () => tr('Usually follow company rules and procedures', ms: 'Biasanya mematuhi peraturan dan prosedur syarikat', zh: '通常遵守公司规定和程序'),
      () => tr('Always follow company rules and procedures', ms: 'Sentiasa mematuhi peraturan dan prosedur syarikat', zh: '总是遵守公司规定和程序'),
    ),
  ),
  _company(
    'system_development_skills',
    () => tr('8. System Development Skills/Technical Skills (CLO2)', ms: '8. Kemahiran Pembangunan Sistem/Kemahiran Teknikal (CLO2)', zh: '8. 系统开发技能/技术技能（CLO2）'),
    () => tr('System development skills', ms: 'Kemahiran pembangunan sistem', zh: '系统开发技能'),
    _companyBands(
      () => tr('No programming/technical skills', ms: 'Tiada kemahiran pengaturcaraan/teknikal', zh: '没有编程/技术技能'),
      () => tr('Has little programming/technical skills', ms: 'Mempunyai sedikit kemahiran pengaturcaraan/teknikal', zh: '编程/技术技能很少'),
      () => tr('Able to develop programs but with errors/Able to apply technical skills but with errors',
          ms: 'Mampu membangunkan program tetapi dengan kesilapan/Mampu menggunakan kemahiran teknikal tetapi dengan kesilapan', zh: '能开发程序但有错误/能运用技术技能但有错误'),
      () => tr('Able to develop good programs and with few errors/Able to apply technical skills with few errors',
          ms: 'Mampu membangunkan program yang baik dengan sedikit kesilapan/Mampu menggunakan kemahiran teknikal dengan sedikit kesilapan', zh: '能开发良好的程序且错误很少/能运用技术技能且错误很少'),
      () => tr('Excellent and impressive programming skills/Excellent and impressive technical skills',
          ms: 'Kemahiran pengaturcaraan yang cemerlang dan mengagumkan/Kemahiran teknikal yang cemerlang dan mengagumkan', zh: '编程技能优秀且令人印象深刻/技术技能优秀且令人印象深刻'),
    ),
  ),
  _company(
    'punctuality',
    () => tr('9. Punctuality (CLO4)', ms: '9. Menepati Masa (CLO4)', zh: '9. 守时（CLO4）'),
    () => tr('Punctuality', ms: 'Menepati masa', zh: '守时'),
    _companyBands(
      () => tr('Always late for work', ms: 'Sentiasa lewat bekerja', zh: '上班总是迟到'),
      () => tr('Frequently late for work or meeting', ms: 'Kerap lewat bekerja atau mesyuarat', zh: '上班或开会经常迟到'),
      () => tr('Occasionally late for work or meeting', ms: 'Kadangkala lewat bekerja atau mesyuarat', zh: '上班或开会偶尔迟到'),
      () => tr('Usually come on time for work or meeting', ms: 'Biasanya datang tepat pada masanya untuk bekerja atau mesyuarat', zh: '上班或开会通常准时'),
      () => tr('Always come on time for work or meeting', ms: 'Sentiasa datang tepat pada masanya untuk bekerja atau mesyuarat', zh: '上班或开会总是准时'),
    ),
  ),
  _company(
    'attendance',
    () => tr('10. Attendance (CLO4)', ms: '10. Kehadiran (CLO4)', zh: '10. 出勤（CLO4）'),
    () => tr('Attendance', ms: 'Kehadiran', zh: '出勤'),
    _companyBands(
      () => tr('Absent from work for more than 6 days', ms: 'Tidak hadir bekerja lebih daripada 6 hari', zh: '缺勤超过 6 天'),
      () => tr('Poor attendance at work or meeting', ms: 'Kehadiran yang lemah di tempat kerja atau mesyuarat', zh: '上班或开会出勤差'),
      () => tr('Fair attendance at work or meeting', ms: 'Kehadiran yang sederhana di tempat kerja atau mesyuarat', zh: '上班或开会出勤一般'),
      () => tr('Good attendance at work or meeting', ms: 'Kehadiran yang baik di tempat kerja atau mesyuarat', zh: '上班或开会出勤良好'),
      () => tr('Excellent attendance at work or meeting', ms: 'Kehadiran yang cemerlang di tempat kerja atau mesyuarat', zh: '上班或开会出勤优秀'),
    ),
  ),
];

/// The 10 criteria of the company supervisor's evaluation, 6 marks each (60 in all).
List<RubricCriterion> get companyEvaluationRubric => _companyRubric;

int get companyEvaluationMaxTotal => _companyRubric.fold(0, (sum, c) => sum + c.maxMark);

/// The overall grades of the form (question 12), with the rating each stands for.
const List<(String, String)> kOverallGrades = [
  ('A', 'Excellent'),
  ('B+', 'Good'),
  ('B', 'Good'),
  ('C', 'Average'),
  ('F', 'Poor'),
];

String overallGradeRating(String rating) {
  switch (rating) {
    case 'Excellent':
      return tr('Excellent', ms: 'Cemerlang', zh: '优秀');
    case 'Good':
      return tr('Good', ms: 'Baik', zh: '良好');
    case 'Average':
      return tr('Average', ms: 'Sederhana', zh: '一般');
    default:
      return tr('Poor', ms: 'Lemah', zh: '较差');
  }
}
