import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/company_supervisor_data_service.dart';
import '../../services/student_data_service.dart';
import '../../utils/format_utils.dart';
import '../document_preview_screen.dart';
import '../student/student_messages_screen.dart';
import 'company_supervisor_evaluate_screen.dart';

class CompanySupervisorStudentsScreen extends StatefulWidget {
  const CompanySupervisorStudentsScreen({super.key});

  @override
  State<CompanySupervisorStudentsScreen> createState() => _CompanySupervisorStudentsScreenState();
}

class _CompanySupervisorStudentsScreenState extends State<CompanySupervisorStudentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _interns = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final interns = await CompanySupervisorDataService.instance.getInterns();
      if (!mounted) return;
      setState(() {
        _interns = interns;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final atRisk = _interns.where((i) => (i['pending_review_count'] as int) > 2).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.csInterns),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Text(l10n.csCurrentInternsCount(_interns.length), style: AppTextStyles.caption),
                        const Spacer(),
                        if (atRisk > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(6)),
                            child: Text(l10n.csNeedsAttention(atRisk), style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _interns.isEmpty
                        ? EmptyState(icon: Icons.badge_outlined, title: l10n.csNoInternsTitle, description: l10n.csNoInternsDescription)
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: _interns.length,
                            itemBuilder: (_, i) => _InternCard(
                              data: _interns[i],
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => InternDetailScreen(data: _interns[i])));
                                _load();
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InternCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _InternCard({required this.data, required this.onTap});

  Color get _statusColor => (data['pending_review_count'] as int) > 2 ? AppColors.error : AppColors.success;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = data['full_name'] as String;
    final pending = data['pending_review_count'] as int;
    return AccentCard(
      accentColor: _statusColor,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.infoBg,
            child: Text(logoLetter(name), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('${data['programme'] ?? l10n.notSpecified} · ${data['role_title'] ?? ''}', style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(pending > 0 ? l10n.supPendingCount(pending) : l10n.supUpToDate, style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor)),
          ),
        ],
      ),
    );
  }
}

class InternDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const InternDetailScreen({super.key, required this.data});

  @override
  State<InternDetailScreen> createState() => _InternDetailScreenState();
}

class _InternDetailScreenState extends State<InternDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final studentId = widget.data['id'] as String;
      final reports = await CompanySupervisorDataService.instance.getReviewItems();
      final documents = await CompanySupervisorDataService.instance.getInternDocuments(studentId);
      if (!mounted) return;
      setState(() {
        _reports = reports.where((r) => r['student_id'] == studentId).toList();
        _documents = documents;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewDocument(Map<String, dynamic> document) async {
    try {
      final url = await StudentDataService.instance.getDocumentSignedUrl(document['storage_path'] as String);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => DocumentPreviewScreen(url: url, fileName: (document['file_name'] as String?) ?? 'document.pdf'),
      ));
    } catch (_) {
      // Non-fatal — just don't navigate.
    }
  }

  Future<void> _message() async {
    try {
      final conversation = await StudentDataService.instance.getOrCreateConversation(widget.data['id'] as String);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation['id'] as String,
            otherProfile: {'id': widget.data['id'], 'full_name': widget.data['full_name'], 'role': 'student'},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open chat: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.data;
    final name = data['full_name'] as String;
    final canEvaluate = data['can_evaluate'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.csInternDetails, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.infoBg,
                  child: Text(logoLetter(name), style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                const SizedBox(height: 10),
                Text(name, style: AppTextStyles.h2),
                Text((data['programme'] as String?) ?? l10n.notSpecified, style: AppTextStyles.bodySecondary),
                const SizedBox(height: 6),
                Text((data['role_title'] as String?) ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canEvaluate
                      ? () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => CompanySupervisorEvaluateScreen(intern: data)));
                          _load();
                        }
                      : null,
                  icon: const Icon(Icons.assessment_outlined, size: 16),
                  label: Text(l10n.supEvaluate),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _message,
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text(l10n.supMessage),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
          ),
          if (!canEvaluate) ...[
            const SizedBox(height: 8),
            Text(l10n.supEvaluateLockedNote, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 20),
          Text(l10n.csReportSubmissions, style: AppTextStyles.h3),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_reports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.csNoReportsSubmittedYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
            )
          else
            ..._reports.map((r) => AccentCard(
                  accentColor: r['status'] == 'approved' ? AppColors.success : (r['status'] == 'rejected' ? AppColors.error : AppColors.warning),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_outlined, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['title'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text(l10n.supSubmittedAgo(timeAgo(context, DateTime.parse(r['submitted_at'] as String))), style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      r['status'] == 'approved' ? StatusBadge.approved(context) : (r['status'] == 'rejected' ? StatusBadge.rejected(context) : StatusBadge.pending(context)),
                    ],
                  ),
                )),
          const SizedBox(height: 20),
          Text(l10n.csDocuments, style: AppTextStyles.h3),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_documents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.csNoDocumentsOnFile, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
            )
          else
            ..._documents.map((d) => GestureDetector(
                  onTap: () => _viewDocument(d),
                  child: AccentCard(
                    accentColor: AppColors.success,
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.success),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_documentCategoryLabel(l10n, d['category'] as String),
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Text(d['file_name'] as String, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

String _documentCategoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'offer_letter':
      return l10n.docTypeOfferLetter;
    case 'indemnity_letter':
      return l10n.docTypeIndemnityLetter;
    default:
      return l10n.docTypeCompanyAcceptanceLetter;
  }
}
