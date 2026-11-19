import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/lang.dart';
import '../widgets/common/shared_widgets.dart';

/// In-app privacy notice, shown at sign-up and from the profile screens, in the language the app is
/// showing (English, Malay or Chinese).
///
/// Written to match what CIMS actually does — keep it in sync if data
/// handling changes (for example, when the resume-analysis service changes).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static List<_Section> get _sections => [
        _Section(
          tr('Who we are', ms: 'Siapa kami', zh: '我们是谁'),
          tr(
            'CIMS (Centralized Internship Management System) is a final-year project '
                'for Tunku Abdul Rahman University of Management and Technology (TARUMT). '
                'It helps students, supervisors and companies manage internships '
                'in one place. This notice explains how your personal data is handled, in '
                'line with the Personal Data Protection Act 2010 (Malaysia).',
            ms: 'CIMS (Centralized Internship Management System) ialah projek tahun akhir '
                'untuk Universiti Pengurusan dan Teknologi Tunku Abdul Rahman (TARUMT). '
                'Ia membantu pelajar, penyelia dan syarikat menguruskan latihan industri '
                'di satu tempat. Notis ini menerangkan bagaimana data peribadi anda dikendalikan, '
                'selaras dengan Akta Perlindungan Data Peribadi 2010 (Malaysia).',
            zh: 'CIMS（集中式实习管理系统）是敦姑阿都拉曼管理与科技大学（TARUMT）的毕业设计项目。'
                '它帮助学生、导师和公司在同一个地方管理实习。本声明说明您的个人数据如何被处理，'
                '并符合马来西亚《2010年个人数据保护法》。',
          ),
        ),
        _Section(
          tr('What we collect', ms: 'Apa yang kami kumpul', zh: '我们收集什么'),
          tr(
            '• Account details: email address, name, role and password (stored as a one-way hash, never in plain text).\n'
                '• Profile details you enter: phone number, date of birth, home address, programme, faculty, semester, CGPA, skills and work experience.\n'
                '• Files you upload: your resume, profile photo, reports, signed forms and chat attachments.\n'
                '• Activity in the app: applications, interviews, messages, notifications, evaluations and company reviews.',
            ms: '• Butiran akaun: alamat e-mel, nama, peranan dan kata laluan (disimpan sebagai cincang sehala, tidak pernah dalam teks biasa).\n'
                '• Butiran profil yang anda masukkan: nombor telefon, tarikh lahir, alamat rumah, program, fakulti, semester, CGPA, kemahiran dan pengalaman kerja.\n'
                '• Fail yang anda muat naik: resume, gambar profil, laporan, borang bertandatangan dan lampiran sembang.\n'
                '• Aktiviti dalam aplikasi: permohonan, temu duga, mesej, notifikasi, penilaian dan ulasan syarikat.',
            zh: '• 账户信息：电子邮件、姓名、角色和密码（以单向哈希保存，绝不以明文保存）。\n'
                '• 您填写的资料：电话号码、出生日期、住址、专业、学院、学期、CGPA、技能和工作经历。\n'
                '• 您上传的文件：简历、头像、报告、已签署的表格和聊天附件。\n'
                '• 应用内的活动：申请、面试、消息、通知、评估和公司评价。',
          ),
        ),
        _Section(
          tr('Why we collect it', ms: 'Mengapa kami mengumpulnya', zh: '我们为何收集'),
          tr(
            'To run the internship process: matching students to postings, letting '
                'supervisors and companies review applications and reports, '
                'collecting required forms, sending messages and notifications, and '
                'recording evaluations.',
            ms: 'Untuk menjalankan proses latihan industri: memadankan pelajar dengan iklan, membolehkan '
                'penyelia dan syarikat menyemak permohonan dan laporan, '
                'mengumpul borang yang diperlukan, menghantar mesej dan notifikasi, serta '
                'merekod penilaian.',
            zh: '用于运行实习流程：为学生匹配职位、让导师和公司审阅申请与报告、'
                '收集所需表格、发送消息和通知，以及记录评估。',
          ),
        ),
        _Section(
          tr('Who can see it', ms: 'Siapa boleh melihatnya', zh: '谁可以看到'),
          tr(
            '• You can see everything on your own account.\n'
                '• Your academic supervisor can see your profile, reports, documents and evaluations.\n'
                '• A company can see the profile, resume and reports of students who apply to it. Companies can also see the skills, programme and name of students whose skills match one of their open postings.\n'
                '• Administrators can see all records in order to run the programme.\n'
                '• Supervisor and company accounts must be approved by an administrator before they can see any student data.',
            ms: '• Anda boleh melihat semua perkara pada akaun anda sendiri.\n'
                '• Penyelia akademik anda boleh melihat profil, laporan, dokumen dan penilaian anda.\n'
                '• Syarikat boleh melihat profil, resume dan laporan pelajar yang memohon kepadanya. Syarikat juga boleh melihat kemahiran, program dan nama pelajar yang kemahirannya sepadan dengan salah satu iklan terbuka mereka.\n'
                '• Pentadbir boleh melihat semua rekod untuk menjalankan program.\n'
                '• Akaun penyelia dan syarikat mesti diluluskan oleh pentadbir sebelum boleh melihat sebarang data pelajar.',
            zh: '• 您可以查看自己账户上的所有内容。\n'
                '• 您的学术导师可以查看您的资料、报告、文件和评估。\n'
                '• 公司可以查看向其申请的学生的资料、简历和报告。公司还可以看到技能与其开放职位相符的学生的技能、专业和姓名。\n'
                '• 管理员为了运行项目可以查看所有记录。\n'
                '• 导师和公司账户必须经管理员批准后，才能查看任何学生数据。',
          ),
        ),
        _Section(
          tr('Where it is processed', ms: 'Di mana ia diproses', zh: '在哪里处理'),
          tr(
            '• Your data and files are stored with Supabase (cloud hosting in Singapore).\n'
                '• Push notifications are delivered through OneSignal and Google Firebase Cloud Messaging.\n'
                '• When you use resume autofill, the text of your resume is sent to the project\'s resume-analysis service to pre-fill your profile. You can always edit or ignore the suggestions.',
            ms: '• Data dan fail anda disimpan di Supabase (pengehosan awan di Singapura).\n'
                '• Notifikasi tolak dihantar melalui OneSignal dan Google Firebase Cloud Messaging.\n'
                '• Apabila anda menggunakan isian automatik resume, teks resume anda dihantar kepada perkhidmatan analisis resume projek ini untuk mengisi profil anda terlebih dahulu. Anda sentiasa boleh mengedit atau mengabaikan cadangan itu.',
            zh: '• 您的数据和文件存储在 Supabase（位于新加坡的云托管）。\n'
                '• 推送通知通过 OneSignal 和 Google Firebase Cloud Messaging 发送。\n'
                '• 使用简历自动填写时，您的简历文本会发送到本项目的简历分析服务，用于预填您的资料。您随时可以修改或忽略这些建议。',
          ),
        ),
        _Section(
          tr('Your choices and rights', ms: 'Pilihan dan hak anda', zh: '您的选择和权利'),
          tr(
            '• View and correct your details at any time from your profile.\n'
                '• Remove your resume or profile photo from your profile.\n'
                '• Ask for your account and personal data to be deleted or anonymised from Profile › Delete my account, or by contacting the internship office. Records that the university must keep for academic purposes (such as submitted reports and evaluations) are kept without your personal details.',
            ms: '• Lihat dan betulkan butiran anda pada bila-bila masa daripada profil anda.\n'
                '• Buang resume atau gambar profil anda daripada profil anda.\n'
                '• Minta akaun dan data peribadi anda dipadam atau dinyahkenalkan daripada Profil › Padam akaun saya, atau dengan menghubungi pejabat latihan industri. Rekod yang mesti disimpan oleh universiti untuk tujuan akademik (seperti laporan dan penilaian yang dihantar) disimpan tanpa butiran peribadi anda.',
            zh: '• 您可以随时在个人资料中查看并更正您的信息。\n'
                '• 您可以在个人资料中删除简历或头像。\n'
                '• 您可以在“个人资料 › 删除我的账户”中，或联系实习办公室，要求删除或匿名化您的账户和个人数据。大学因学术目的必须保留的记录（例如已提交的报告和评估）会在去除您个人信息后保留。',
          ),
        ),
        _Section(
          tr('Keeping your data safe', ms: 'Menjaga keselamatan data anda', zh: '保障数据安全'),
          tr(
            'Access is limited by role, communication is encrypted in transit, and '
                'passwords are stored as hashes. No system is perfectly secure; please '
                'use a strong, unique password and log out on shared devices.',
            ms: 'Akses dihadkan mengikut peranan, komunikasi disulitkan semasa penghantaran, dan '
                'kata laluan disimpan sebagai cincang. Tiada sistem yang selamat sepenuhnya; sila '
                'gunakan kata laluan yang kukuh dan unik, serta log keluar pada peranti kongsi.',
            zh: '访问权限按角色限制，传输过程中的通信经过加密，密码以哈希形式保存。'
                '没有任何系统是绝对安全的；请使用强而唯一的密码，并在共用设备上退出登录。',
          ),
        ),
        _Section(
          tr('Changes', ms: 'Perubahan', zh: '更新'),
          tr(
            'If we change how data is handled, this notice will be updated in the app.',
            ms: 'Jika kami mengubah cara data dikendalikan, notis ini akan dikemas kini dalam aplikasi.',
            zh: '如果我们改变数据的处理方式，本声明将在应用内更新。',
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: tt('Privacy notice')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final section in sections) ...[
            Text(section.title,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(section.body,
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}
