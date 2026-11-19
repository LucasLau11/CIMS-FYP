import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/admin_data_service.dart';
import '../../utils/format_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/error_text.dart';
import 'admin_create_students_screen.dart';
import '../../widgets/profile_actions.dart';
import '../supervisor/supervisor_students_screen.dart' show StudentDetailScreen;

class AdminSupervisorsScreen extends StatefulWidget {
  const AdminSupervisorsScreen({super.key});

  @override
  State<AdminSupervisorsScreen> createState() => _AdminSupervisorsScreenState();
}

class _AdminSupervisorsScreenState extends State<AdminSupervisorsScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _supervisors = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final supervisors = await AdminDataService.instance.getSupervisors();
      if (!mounted) return;
      setState(() {
        _supervisors = supervisors;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchController.text.isEmpty) return _supervisors;
    final q = _searchController.text.toLowerCase();
    return _supervisors.where((s) => ((s['full_name'] as String?) ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.adminSupervisorsTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (_) => const AdminCreateStudentsScreen(role: 'academic_supervisor')));
          if (created == true) _load();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
        label: Text(l10n.adminAddSupervisors, style: const TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(hintText: l10n.adminSearchSupervisorsHint, prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(children: [Flexible(child: Text(l10n.adminAcademicSupervisorsCount(results.length), style: AppTextStyles.caption, overflow: TextOverflow.ellipsis))]),
                  ),
                  Expanded(
                    child: results.isEmpty
                        ? EmptyState(icon: Icons.supervisor_account_outlined, title: l10n.adminNoSupervisorsFoundTitle, description: l10n.adminNoSupervisorsFoundDescription)
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 6, bottom: 24),
                            itemCount: results.length,
                            itemBuilder: (_, i) => _SupervisorCard(
                              data: results[i],
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => _SupervisorDetailScreen(data: results[i])));
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

class _SupervisorCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _SupervisorCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = (data['email'] as String?) ?? '';
    final name = (data['full_name'] as String?)?.isNotEmpty == true
        ? data['full_name'] as String
        : (email.isNotEmpty ? email : l10n.adminUnnamed);
    final approval = data['approval_status'] as String?;
    final badge = approval == 'pending'
        ? l10n.adminAwaitingApprovalBadge
        : approval == 'rejected'
            ? l10n.adminNotApprovedBadge
            : (data['has_logged_in'] == false ? l10n.adminNeverLoggedIn : null);
    return AccentCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.infoBg,
            child: Text(logoLetter(name), style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text((data['email'] as String?) ?? '', style: AppTextStyles.caption),
                Text((data['faculty'] as String?) ?? l10n.adminFacultyNotSet, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                if (badge != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(badge, style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning)),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
            child: Text(l10n.supStudentsCount(data['student_count'] as int),
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
          ),
        ],
      ),
    );
  }
}

class _SupervisorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const _SupervisorDetailScreen({required this.data});

  @override
  State<_SupervisorDetailScreen> createState() => _SupervisorDetailScreenState();
}

class _SupervisorDetailScreenState extends State<_SupervisorDetailScreen> {
  bool _isLoading = true;
  bool _isPromoting = false;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final students = await AdminDataService.instance.getStudentsForSupervisor(widget.data['id'] as String);
      if (!mounted) return;
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _promoteToAdmin() async {
    final l10n = AppLocalizations.of(context)!;
    final name = (widget.data['full_name'] as String?)?.isNotEmpty == true ? widget.data['full_name'] as String : l10n.adminThisSupervisorFallback;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.adminPromoteToAdminTitle, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          l10n.adminPromoteToAdminMessage(name),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.adminPromote, style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isPromoting = true);
    try {
      await AdminDataService.instance.promoteToAdmin(widget.data['id'] as String);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPromoting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminCouldNotPromote(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.data;
    final name = (data['full_name'] as String?)?.isNotEmpty == true ? data['full_name'] as String : l10n.adminUnnamed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.adminSupervisorDetailsTitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.infoBg,
                          child: Text(logoLetter(name), style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                        ),
                        const SizedBox(height: 10),
                        Text(name, style: AppTextStyles.h2),
                        const SizedBox(height: 2),
                        Text((data['faculty'] as String?) ?? l10n.adminFacultyNotSet, style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: _DetailLine(icon: Icons.email_outlined, label: l10n.email, value: (data['email'] as String?) ?? l10n.notSet),
                  ),
                  const SizedBox(height: 12),
                  MessageButton(profileId: data['id'] as String),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isPromoting ? null : _promoteToAdmin,
                      icon: _isPromoting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.admin_panel_settings_outlined, size: 16),
                      label: Text(l10n.adminPromoteToAdminButton),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AdminAccountButtons(
                    profileId: data['id'] as String,
                    name: name,
                    status: data['approval_status'] as String?,
                    onChanged: () => Navigator.pop(context),
                    onRemoved: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.supAssignedStudents, style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  if (_students.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(l10n.adminNoStudentsAssignedYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
                    )
                  else
                    ..._students.map((s) => InkWell(
                        borderRadius: BorderRadius.circular(10),
                        // Opens the student's page: profile, reports, evaluations and the account actions.
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s['id'] as String, adminMode: true)));
                          _load();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.surfaceVariant,
                                child: Text(logoLetter((s['full_name'] as String?) ?? '?'),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text((s['full_name'] as String?) ?? l10n.adminUnnamed, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text((s['programme'] as String?) ?? l10n.adminProgrammeNotSet, style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                            ],
                          ),
                        ))),
                ],
              ),
            ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailLine({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
