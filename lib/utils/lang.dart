import '../services/locale_controller.dart';

/// Picks the text for the language the app is showing. For messages that are
/// built outside a widget (form validation, error text) where there is no
/// BuildContext to read the localisation from. Widgets should use the ARB
/// files (`AppLocalizations`) instead.
String tr(String en, {required String ms, required String zh}) {
  switch (LocaleController.instance.currentLocale.value.languageCode) {
    case 'ms':
      return ms;
    case 'zh':
      return zh;
    default:
      return en;
  }
}

const Map<String, List<String>> _fieldNames = {
  // English: [Malay, Chinese]
  'This field': ['Ruangan ini', '此项'],
  'Full name': ['Nama penuh', '姓名'],
  'Company name': ['Nama syarikat', '公司名称'],
  'The reason': ['Sebab', '原因'],
  'The comment': ['Komen', '评论'],
  'Description': ['Penerangan', '描述'],
  'Cover letter': ['Surat lamaran', '求职信'],
  'Your review': ['Ulasan anda', '您的评价'],
  'The location': ['Lokasi', '地点'],
  'Start year': ['Tahun mula', '开始年份'],
  'End year': ['Tahun tamat', '结束年份'],
  'Programme': ['Program', '专业'],
  'Position': ['Jawatan', '职位'],
  'Period': ['Tempoh', '时期'],
  'Notes': ['Nota', '备注'],
  'Label': ['Label', '标签'],
  'Job title': ['Tajuk jawatan', '职位名称'],
  'Intake name': ['Nama pengambilan', '批次名称'],
  'Industry': ['Industri', '行业'],
  'Document title': ['Tajuk dokumen', '文件标题'],
  'Custom category': ['Kategori tersuai', '自定义类别'],
  'Contact name': ['Nama hubungan', '联系人姓名'],
  'Auto-close date': ['Tarikh tutup automatik', '自动关闭日期'],
  'Allowance': ['Elaun', '津贴'],
  'Amount': ['Jumlah', '金额'],
  'Year': ['Tahun', '年份'],
  'Date': ['Tarikh', '日期'],
  'Date and time': ['Tarikh dan masa', '日期和时间'],
  'Rating': ['Penilaian', '评分'],
  'End date': ['Tarikh tamat', '结束日期'],
  'start date': ['tarikh mula', '开始日期'],
};

/// A field name as passed by the screens (English) in the app's language.
/// Names that are not in the list stay as they were given.
String fieldLabel(String english) {
  final entry = _fieldNames[english];
  if (entry == null) return english;
  return tr(english, ms: entry[0], zh: entry[1]);
}

const Map<String, List<String>> _phrases = {
  // English: [Malay, Chinese]
  'Cancel': ['Batal', '取消'],
  'Save': ['Simpan', '保存'],
  'Delete': ['Padam', '删除'],
  'Reject': ['Tolak', '拒绝'],
  'Approve': ['Luluskan', '批准'],
  'Create': ['Cipta', '创建'],
  'Done': ['Selesai', '完成'],
  'Continue': ['Teruskan', '继续'],
  'Remove': ['Buang', '移除'],
  'Name': ['Nama', '名称'],
  'Used for': ['Digunakan untuk', '用途'],
  'Pending approvals': ['Menunggu kelulusan', '待批准'],
  'Nothing waiting': ['Tiada yang menunggu', '没有待处理项'],
  'Upload template': ['Muat naik templat', '上传模板'],
  'No templates yet': ['Belum ada templat', '暂无模板'],
  'Intakes': ['Pengambilan', '实习批次'],
  'No intakes yet': ['Belum ada pengambilan', '暂无实习批次'],
  'Completed': ['Selesai', '已完成'],
  'Ongoing': ['Sedang berjalan', '进行中'],
  'Failed': ['Gagal', '未通过'],
  'Not started': ['Belum bermula', '未开始'],
  'Unassigned': ['Belum ditetapkan', '未分配'],
  'Assign students': ['Tetapkan pelajar', '分配学生'],
  'Already in another intake — will be moved here': ['Sudah dalam pengambilan lain — akan dipindahkan ke sini', '已在另一个批次中，将移到此批次'],
  'Manage students': ['Urus pelajar', '管理学生'],
  'Review new supervisor and company accounts': ['Semak akaun penyelia dan syarikat baharu', '审核新的导师和公司账户'],
  'Field': ['Medan', '字段'],
  'Label': ['Label', '标签'],
  'Add at least one field before saving.': ['Tambah sekurang-kurangnya satu medan sebelum menyimpan.', '保存前请至少添加一个字段。'],
  'Template saved and activated.': ['Templat disimpan dan diaktifkan.', '模板已保存并启用。'],
  'Could not load template': ['Tidak dapat memuatkan templat', '无法加载模板'],
  'Could not save': ['Tidak dapat menyimpan', '无法保存'],
  'Could not delete': ['Tidak dapat memadam', '无法删除'],
  'Could not remove': ['Tidak dapat membuang', '无法移除'],
  'Could not add': ['Tidak dapat menambah', '无法添加'],
  'Could not upload template': ['Tidak dapat memuat naik templat', '无法上传模板'],
  'Could not submit evaluation': ['Tidak dapat menghantar penilaian', '无法提交评估'],
  'Could not save review': ['Tidak dapat menyimpan ulasan', '无法保存评价'],
  'Could not open file': ['Tidak dapat membuka fail', '无法打开文件'],
  'Could not open chat': ['Tidak dapat membuka sembang', '无法打开聊天'],
  'Could not join company': ['Tidak dapat menyertai syarikat', '无法加入公司'],
  'Could not register company': ['Tidak dapat mendaftar syarikat', '无法注册公司'],
  'Could not load this PDF for preview.': ['Tidak dapat memuatkan PDF ini untuk pratonton.', '无法加载此 PDF 进行预览。'],
  'Could not load this image for preview.': ['Tidak dapat memuatkan imej ini untuk pratonton.', '无法加载此图片进行预览。'],
  'Could not load this document for preview.': ['Tidak dapat memuatkan dokumen ini untuk pratonton.', '无法加载此文档进行预览。'],
  'Open externally': ['Buka dalam aplikasi lain', '用其他应用打开'],
  'My interview availability': ['Ketersediaan temu duga saya', '我的面试可用时间'],
  'No matching candidates': ['Tiada calon yang sepadan', '没有匹配的候选人'],
  'View profile': ['Lihat profil', '查看资料'],
  'Skills': ['Kemahiran', '技能'],
  'Resume': ['Resume', '简历'],
  'Message': ['Mesej', '发消息'],
  'Privacy notice': ['Notis privasi', '隐私声明'],
  'Delete my account': ['Padam akaun saya', '删除我的账户'],
  'Please fix the highlighted fields.': ['Sila betulkan medan yang diserlahkan.', '请修正标出的字段。'],
  'Reason': ['Sebab', '原因'],
};

/// A fixed English phrase in the app's language (for text built outside a widget, or labels that
/// were written as plain English). Phrases that are not in the list stay as they were given.
String tt(String english) {
  final entry = _phrases[english];
  if (entry == null) return english;
  return tr(english, ms: entry[0], zh: entry[1]);
}
