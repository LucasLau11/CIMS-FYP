import '../../l10n/app_localizations.dart';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/admin_data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_text.dart';
import '../../utils/student_import.dart';
import '../../utils/validators.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../widgets/common/validated_field.dart';

/// Where an administrator creates student accounts, one at a time or from a
/// list / CSV file. Students do not sign themselves up. Each account gets a
/// random password that meets the password rules; the student must replace it
/// at their first login. Pops with `true` once accounts were created, so the
/// student list can reload.
class AdminCreateStudentsScreen extends StatefulWidget {
  /// `student` (default) or `academic_supervisor`.
  const AdminCreateStudentsScreen({super.key, this.role = 'student'});

  final String role;

  @override
  State<AdminCreateStudentsScreen> createState() => _AdminCreateStudentsScreenState();
}

class _AdminCreateStudentsScreenState extends State<AdminCreateStudentsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  bool _createdAny = false;

  bool get _supervisors => widget.role == 'academic_supervisor';

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _showResults(List<StudentAccountResult> results) async {
    if (results.any((r) => r.created)) _createdAny = true;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentCredentialsScreen(results: results, supervisors: _supervisors)));
    if (!mounted) return;
    // After the credentials were handed over, leave straight away so the list reloads.
    if (results.every((r) => r.created)) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _createdAny);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context, _createdAny)),
          title: Text(_supervisors ? AppLocalizations.of(context)!.acTitleSupervisors : AppLocalizations.of(context)!.acTitleStudents, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: kOnBannerSoft,
            tabs: [
              Tab(text: _supervisors ? AppLocalizations.of(context)!.acTabOneSupervisor : AppLocalizations.of(context)!.acTabOne),
              Tab(text: _supervisors ? AppLocalizations.of(context)!.acTabManySupervisor : AppLocalizations.of(context)!.acTabMany),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _SingleStudentTab(onResults: _showResults, role: widget.role),
            _BulkStudentsTab(onResults: _showResults, role: widget.role),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({this.supervisors = false});

  final bool supervisors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        supervisors ? AppLocalizations.of(context)!.acHowItWorksSupervisor : AppLocalizations.of(context)!.acHowItWorks,
        style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: AppColors.info),
      ),
    );
  }
}

// ------------------------------------------------------------------ one student

class _SingleStudentTab extends StatefulWidget {
  const _SingleStudentTab({required this.onResults, required this.role});
  final Future<void> Function(List<StudentAccountResult>) onResults;
  final String role;

  @override
  State<_SingleStudentTab> createState() => _SingleStudentTabState();
}

class _SingleStudentTabState extends State<_SingleStudentTab> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _regNo = TextEditingController();
  final _programme = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _regNo.dispose();
    _programme.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final supervisors = widget.role == 'academic_supervisor';
      final results = await AdminDataService.instance.createAccounts(widget.role, [
        {
          'email': _email.text.trim(),
          'full_name': _name.text.trim(),
          if (!supervisors && _regNo.text.trim().isNotEmpty) 'student_reg_no': _regNo.text.trim(),
          if (!supervisors && _programme.text.trim().isNotEmpty) 'programme': _programme.text.trim(),
        },
      ]);
      if (!mounted) return;
      setState(() => _busy = false);
      if (results.isNotEmpty && results.first.created) {
        _name.clear();
        _email.clear();
        _regNo.clear();
        _programme.clear();
      }
      await widget.onResults(results);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HowItWorks(supervisors: widget.role == 'academic_supervisor'),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.acFullName, style: AppTextStyles.label),
            const SizedBox(height: 6),
            ValidatedField(
              controller: _name,
              fieldValidator: (v) => Validators.fullName(v),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              hintText: widget.role == 'academic_supervisor' ? AppLocalizations.of(context)!.acFullNameHintSupervisor : AppLocalizations.of(context)!.acFullNameHint,
            ),
            const SizedBox(height: 14),
            Text(AppLocalizations.of(context)!.acEmail, style: AppTextStyles.label),
            const SizedBox(height: 6),
            ValidatedField(
              controller: _email,
              fieldValidator: Validators.emailFormat,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              hintText: widget.role == 'academic_supervisor' ? 'name@tarc.edu.my' : 'name@student.tarc.edu.my',
            ),
            if (widget.role != 'academic_supervisor') ...[
            const SizedBox(height: 14),
            Text(AppLocalizations.of(context)!.acRegNoOptional, style: AppTextStyles.label),
            const SizedBox(height: 6),
            ValidatedField(
              controller: _regNo,
              fieldValidator: (v) => Validators.studentRegNo(v),
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              hintText: '24WMR12345',
            ),
            const SizedBox(height: 14),
            Text(AppLocalizations.of(context)!.acProgrammeOptional, style: AppTextStyles.label),
            const SizedBox(height: 6),
            ValidatedField(
              controller: _programme,
              fieldValidator: (v) => Validators.text(v, field: 'Programme', required: false, max: 150),
              textCapitalization: TextCapitalization.words,
              hintText: AppLocalizations.of(context)!.acProgrammeHint,
            ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _create,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(AppLocalizations.of(context)!.acCreateAccount),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ many students

class _BulkStudentsTab extends StatefulWidget {
  const _BulkStudentsTab({required this.onResults, required this.role});
  final Future<void> Function(List<StudentAccountResult>) onResults;
  final String role;

  @override
  State<_BulkStudentsTab> createState() => _BulkStudentsTabState();
}

class _BulkStudentsTabState extends State<_BulkStudentsTab> {
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _fileName;

  bool get _supervisors => widget.role == 'academic_supervisor';

  List<StudentDraft> get _drafts => StudentImport.parse(_text.text, studentFields: !_supervisors);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'txt'], withData: true);
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _error = AppLocalizations.of(context)!.acFileCouldNotRead);
        return;
      }
      if (bytes.length > 512 * 1024) {
        setState(() => _error = AppLocalizations.of(context)!.acFileTooLarge);
        return;
      }
      setState(() {
        // Spreadsheets often save a byte-order mark at the start; drop it.
        _text.text = utf8.decode(bytes, allowMalformed: true).replaceFirst('﻿', '');
        _fileName = file.name;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    }
  }

  Future<void> _create(List<StudentDraft> ok) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final results = await AdminDataService.instance.createAccounts(widget.role, [for (final d in ok) d.toJson()]);
      if (!mounted) return;
      setState(() => _busy = false);
      if (results.any((r) => r.created)) _text.clear();
      await widget.onResults(results);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final drafts = _drafts;
    final ok = drafts.where((d) => d.ok).toList();
    final bad = drafts.where((d) => !d.ok).toList();
    final tooMany = ok.length > StudentImport.maxStudents;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HowItWorks(supervisors: _supervisors),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.acOnePerLine, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(_supervisors ? AppLocalizations.of(context)!.acLineFormatSupervisor : AppLocalizations.of(context)!.acLineFormat,
              style: AppTextStyles.caption),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickFile,
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(_fileName == null ? AppLocalizations.of(context)!.acChooseCsv : AppLocalizations.of(context)!.acFileName(_fileName!), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _text,
            minLines: 6,
            maxLines: 12,
            onChanged: (_) => setState(() {
              _error = null;
              _fileName = null;
            }),
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: _supervisors
                  ? 'dr.lim@tarc.edu.my, Dr Lim Wei\nsiti@tarc.edu.my, Siti Aminah'
                  : 'ali@student.tarc.edu.my, Ali bin Abu, 24WMR12345\nsiti@student.tarc.edu.my, Siti Aminah',
            ),
          ),
          const SizedBox(height: 14),
          if (drafts.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Pill(label: '${ok.length} ready', color: AppColors.success, background: AppColors.successBg),
                if (bad.isNotEmpty) _Pill(label: '${bad.length} to fix', color: AppColors.error, background: AppColors.errorBg),
              ],
            ),
            const SizedBox(height: 10),
            for (final d in drafts.take(60)) _DraftRow(draft: d),
            if (drafts.length > 60) Padding(padding: const EdgeInsets.only(top: 6), child: Text('…and ${drafts.length - 60} more.', style: AppTextStyles.caption)),
          ],
          if (tooMany)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Create at most ${StudentImport.maxStudents} accounts at a time. Split the list.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_busy || ok.isEmpty || tooMany) ? null : () => _create(ok),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(ok.isEmpty ? AppLocalizations.of(context)!.acCreateAccounts : AppLocalizations.of(context)!.acCreateN(ok.length)),
          ),
          if (bad.isNotEmpty && ok.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(AppLocalizations.of(context)!.acRowsSkipped, style: AppTextStyles.caption, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.background});
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({required this.draft});
  final StudentDraft draft;

  @override
  Widget build(BuildContext context) {
    final color = draft.ok ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: draft.ok ? AppColors.border : AppColors.error.withValues(alpha: 0.5))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(draft.ok ? Icons.check_circle_outline : Icons.error_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft.fullName.isEmpty ? '(no name)' : draft.fullName, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(draft.email.isEmpty ? '(no email)' : draft.email, style: AppTextStyles.caption),
                if (!draft.ok) Text('Line ${draft.line}: ${draft.problem}', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ credentials

/// Shows the new accounts and their temporary passwords. This is the ONLY time
/// the passwords exist in readable form: copy them or email them to the
/// students from here.
class StudentCredentialsScreen extends StatelessWidget {
  const StudentCredentialsScreen({super.key, required this.results, this.supervisors = false});

  final bool supervisors;

  final List<StudentAccountResult> results;

  List<StudentAccountResult> get _created => results.where((r) => r.created).toList();

  String _csv() {
    final b = StringBuffer('email,full_name,temporary_password\n');
    for (final r in _created) {
      String q(String v) => v.contains(',') || v.contains('"') ? '"${v.replaceAll('"', '""')}"' : v;
      b.writeln('${q(r.email)},${q(r.fullName)},${q(r.password!)}');
    }
    return b.toString();
  }

  Future<void> _copy(BuildContext context, String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.success));
  }

  static String messageFor(StudentAccountResult r) => 'Hello ${r.fullName},\n\n'
      'An account has been created for you on CIMS, the internship management app.\n\n'
      'Email: ${r.email}\n'
      'Temporary password: ${r.password}\n\n'
      'Log in with these details. You will be asked to choose your own password straight away.\n';

  Future<void> _email(BuildContext context, StudentAccountResult r) async {
    final uri = Uri.parse(
        'mailto:${r.email}?subject=${Uri.encodeComponent('Your CIMS account')}&body=${Uri.encodeComponent(messageFor(r))}');
    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {}
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.acNoEmailApp), backgroundColor: AppColors.error),
      );
    }
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    if (_created.isEmpty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.acLeaveTitle),
        content: Text(AppLocalizations.of(context)!.acLeaveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.acStay)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.acLeave, style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;
    final skipped = results.where((r) => !r.created).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave(context) && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: GradientAppBar(title: AppLocalizations.of(context)!.acNewAccounts),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Pill(label: '${created.length} created', color: AppColors.success, background: AppColors.successBg),
                if (skipped.isNotEmpty) _Pill(label: '${skipped.length} not created', color: AppColors.error, background: AppColors.errorBg),
              ],
            ),
            if (created.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  supervisors ? AppLocalizations.of(context)!.acSendNowSupervisor : AppLocalizations.of(context)!.acSendNow,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.4, color: AppColors.warning),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _copy(context, _csv(), AppLocalizations.of(context)!.acCopiedCsv(created.length)),
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: Text(AppLocalizations.of(context)!.acCopyAllCsv),
              ),
              const SizedBox(height: 8),
              for (final r in created) _CredentialCard(result: r, supervisors: supervisors, onCopy: () => _copy(context, messageFor(r), AppLocalizations.of(context)!.acLoginCopied), onEmail: () => _email(context, r)),
            ],
            if (skipped.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.acNotCreated, style: AppTextStyles.h3),
              const SizedBox(height: 8),
              for (final r in skipped)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.email.isEmpty ? '(no email)' : r.email, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
                      Text(r.message ?? 'The account could not be created.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (await _confirmLeave(context) && context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(AppLocalizations.of(context)!.acDone),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({required this.result, required this.onCopy, required this.onEmail, this.supervisors = false});

  final bool supervisors;
  final StudentAccountResult result;
  final VoidCallback onCopy;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    return AccentCard(
      accentColor: AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.fullName, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          SelectableText(result.email, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
            child: SelectableText(result.password!, style: TextStyle(fontFamily: 'monospace', fontSize: 16, letterSpacing: 1, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          if (result.message != null) ...[
            const SizedBox(height: 6),
            Text(result.message!, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.warning)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(onPressed: onCopy, icon: const Icon(Icons.copy, size: 16), label: Text(AppLocalizations.of(context)!.acCopyDetails)),
              OutlinedButton.icon(onPressed: onEmail, icon: const Icon(Icons.mail_outline, size: 16), label: Text(supervisors ? AppLocalizations.of(context)!.acEmailSupervisor : AppLocalizations.of(context)!.acEmailStudent)),
            ],
          ),
        ],
      ),
    );
  }
}
