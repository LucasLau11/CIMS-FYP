import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/student_data_service.dart';
import '../../utils/format_utils.dart';
import '../../l10n/app_localizations.dart';
import 'student_interview_screen.dart';
import '../../services/interview_service.dart';
import '../../utils/interview_format.dart';
import '../../utils/error_text.dart';
import '../../theme/role_theme.dart';
import '../../utils/lang.dart';
import '../document_preview_screen.dart';

class StudentApplicationsScreen extends StatefulWidget {
  const StudentApplicationsScreen({super.key});

  @override
  State<StudentApplicationsScreen> createState() => _StudentApplicationsScreenState();
}

class _StudentApplicationsScreenState extends State<StudentApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final applications = await StudentDataService.instance.getMyApplications();
      if (!mounted) return;
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _withdraw(Map<String, dynamic> application) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.withdrawApplicationTitle),
        content: Text(l10n.withdrawApplicationMessage((application['internships'] as Map)['title'] as String)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.withdraw, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await StudentDataService.instance.withdrawApplication(application['id'] as String);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorCouldNotWithdraw(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  Future<void> _viewOfferLetter(Map<String, dynamic> application) async {
    final path = application['offer_letter_path'] as String?;
    if (path == null) return;
    try {
      final url = await StudentDataService.instance.getOfferLetterUrl(path);
      if (!mounted) return;
      final name = (application['offer_letter_name'] as String?) ?? path.split('/').last;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentPreviewScreen(url: url, fileName: name)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('Could not open the offer letter', ms: 'Tidak dapat membuka surat tawaran', zh: '无法打开录取信')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _acceptOffer(Map<String, dynamic> application) async {
    final internship = application['internships'] as Map;
    final id = application['id'] as String;
    final otherOpen = _applications
        .where((a) => a['id'] != id && const ['pending', 'interview', 'offered'].contains(a['status']))
        .length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.offAcceptTitle),
        content: Text(
          '${AppLocalizations.of(context)!.offAcceptBody('${internship['title']}', '${internship['company_name']}')}'
          '${otherOpen == 0 ? '' : '\n\n${AppLocalizations.of(context)!.offAcceptCloses(otherOpen)}'}'
          '\n\n${AppLocalizations.of(context)!.offAcceptOne}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.offNotYet)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.offAcceptOffer)),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await StudentDataService.instance.acceptOffer(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.offAccepted('${internship['company_name']}')), backgroundColor: AppColors.success),
      );
      await _load();
      _tabController.animateTo(4); // Active tab
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.offCouldNotAccept(friendlyError(e))), backgroundColor: AppColors.error),
      );
    }
  }

  void _showDetails(Map<String, dynamic> application) {
    final l10n = AppLocalizations.of(context)!;
    final internship = application['internships'] as Map;
    final skills = (application['skills'] as List?)?.cast<String>() ?? [];
    final coverLetter = application['cover_letter'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Text(internship['title'] as String, style: AppTextStyles.h3),
            Text('${internship['company_name']} · ${internship['location']}', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 16),
            Text(l10n.coverLetterLabel, style: AppTextStyles.label),
            const SizedBox(height: 6),
            Text(
              coverLetter?.isNotEmpty == true ? coverLetter! : l10n.noCoverLetterProvided,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: coverLetter?.isNotEmpty == true ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.skillsLabel, style: AppTextStyles.label),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration:
                            BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(s,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryText)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(l10n.hrAppliedAgo(timeAgo(context, DateTime.parse(application['applied_at'] as String))),
                style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filtered(String tab) {
    if (tab == 'All') return _applications;
    final map = {'Pending': 'pending', 'Offers': 'offered', 'Active': 'active', 'Interview': 'interview', 'Rejected': 'rejected'};
    return _applications.where((a) => a['status'] == map[tab]).toList();
  }

  int _countByStatus(String status) => _applications.where((a) => a['status'] == status).length;

  /// One header for the whole page: the title and the tabs (each with its count) share a
  /// single banner instead of a title bar with a separate strip under it.
  Widget _buildHeader(AppLocalizations l10n) {
    return RoleHeaderBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                l10n.myApplications,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            // The internal filter keys ('All', 'Pending', ... used by _filtered())
            // are deliberately NOT localized: they are identifiers, not display
            // text. Only the visible Tab labels use l10n.
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.12)),
              labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85)),
              tabs: [
                Tab(text: '${l10n.tabAll} (${_applications.length})'),
                Tab(text: '${l10n.pending} (${_countByStatus('pending')})'),
                Tab(text: '${l10n.interview} (${_countByStatus('interview')})'),
                Tab(text: l10n.appTabOffers(_countByStatus('offered'))),
                Tab(text: '${l10n.active} (${_countByStatus('active')})'),
                Tab(text: '${l10n.rejected} (${_countByStatus('rejected')})'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(l10n),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: TabBarView(
                      controller: _tabController,
                      children: ['All', 'Pending', 'Interview', 'Offers', 'Active', 'Rejected'].map((tab) {
                        final items = _filtered(tab);
                        if (items.isEmpty) {
                          return EmptyState(
                            icon: Icons.work_outline,
                            title: l10n.noApplicationsHere,
                            description: l10n.applicationsAppearHere,
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _ApplicationCard(
                            data: items[i],
                            onViewDetails: () => _showDetails(items[i]),
                            onWithdraw: items[i]['status'] == 'pending' ? () => _withdraw(items[i]) : null,
                            onAcceptOffer: items[i]['status'] == 'offered' ? () => _acceptOffer(items[i]) : null,
                            onViewOfferLetter: items[i]['status'] == 'offered' && items[i]['offer_letter_path'] != null
                                ? () => _viewOfferLetter(items[i])
                                : null,
                            onViewInterview: items[i]['status'] == 'interview'
                                ? () async {
                                    final changed = await Navigator.push<bool>(
                                        context, MaterialPageRoute(builder: (_) => StudentInterviewScreen(application: items[i])));
                                    if (changed == true) _load();
                                  }
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onViewDetails;
  final VoidCallback? onWithdraw;
  final VoidCallback? onViewInterview;
  final VoidCallback? onAcceptOffer;
  final VoidCallback? onViewOfferLetter;

  const _ApplicationCard({
    required this.data,
    required this.onViewDetails,
    required this.onWithdraw,
    this.onViewInterview,
    this.onAcceptOffer,
    this.onViewOfferLetter,
  });

  Color get _accentColor {
    switch (data['status']) {
      case 'active':
        return AppColors.success;
      case 'interview':
        return AppColors.warning;
      case 'offered':
        return AppColors.info;
      case 'unavailable':
        return AppColors.textMuted;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.primaryLight;
    }
  }

  StatusBadge _badge(BuildContext context, AppLocalizations l10n) {
    switch (data['status']) {
      case 'active':
        return StatusBadge.active(context);
      case 'interview':
        return StatusBadge(
            label: l10n.interview, backgroundColor: const Color(0xFFFEF3C7), textColor: const Color(0xFFD97706));
      case 'offered':
        return StatusBadge.offered(context);
      case 'unavailable':
        return StatusBadge.unavailable(context);
      case 'rejected':
        return StatusBadge.rejected(context);
      default:
        return StatusBadge.pending(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final internship = data['internships'] as Map;
    final companyName = internship['company_name'] as String;
    final appliedAt = DateTime.parse(data['applied_at'] as String);
    final interview = data['interview'] as InterviewInfo?;
    final showInterview = interview != null && data['status'] == 'interview' && interview.status != 'completed';

    return AccentCard(
      onTap: onViewDetails,
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(color: nameColor(companyName).withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
                child: Center(
                  child: Text(logoLetter(companyName),
                      style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: nameTextColor(companyName))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(internship['title'] as String,
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(companyName, style: AppTextStyles.caption),
                  ],
                ),
              ),
              _badge(context, l10n),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _MetaItem(icon: Icons.location_on_outlined, label: internship['location'] as String),
              _MetaItem(icon: Icons.calendar_today_outlined, label: l10n.hrAppliedAgo(timeAgo(context, appliedAt))),
            ],
          ),
          if (showInterview) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onViewInterview,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: interview.isCancelled ? AppColors.errorBg : AppColors.warningBg, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(interview.isCancelled ? Icons.event_busy_outlined : Icons.videocam_outlined,
                        size: 15, color: interview.isCancelled ? AppColors.error : AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                          interview.isCancelled
                              ? l10n.appInterviewCancelledTap
                              : l10n.hrInterviewScheduledColon(formatInterviewDateTime(interview.start)),
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: interview.isCancelled ? AppColors.error : AppColors.warning)),
                    ),
                    if (onViewInterview != null)
                      Icon(Icons.chevron_right, size: 16, color: interview.isCancelled ? AppColors.error : AppColors.warning),
                  ],
                ),
              ),
            ),
          ],
          if (data['status'] == 'offered') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(8)),
              child: Text(
                l10n.appOfferedBody,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.info),
              ),
            ),
            if (onViewOfferLetter != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onViewOfferLetter,
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: Text(tr('View offer letter', ms: 'Lihat surat tawaran', zh: '查看录取信')),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
            if (onAcceptOffer != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAcceptOffer,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(l10n.offAcceptOffer),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
          ],
          if (data['status'] == 'rejected') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.appReasonFromCompany,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
                  const SizedBox(height: 2),
                  Text((data['rejection_reason'] as String?) ?? l10n.appNoReasonRecorded,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
                ],
              ),
            ),
          ],
          if (data['status'] == 'unavailable') ...[
            const SizedBox(height: 10),
            Text(l10n.appClosedAcceptedOther, style: AppTextStyles.caption),
          ],
          if (onWithdraw != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onWithdraw,
                    icon: Icon(Icons.cancel_outlined, size: 15, color: AppColors.error),
                    label: Text(l10n.withdraw, style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                      side: BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
