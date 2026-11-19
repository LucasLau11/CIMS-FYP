import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/admin_data_service.dart';
import '../../utils/format_utils.dart';
import '../supervisor/supervisor_students_screen.dart' show StudentDetailScreen;
import '../../utils/error_text.dart';
import 'admin_create_students_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _searchController = TextEditingController();
  String _filter = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _supervisors = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final students = await AdminDataService.instance.getStudents();
      final supervisors = await AdminDataService.instance.getSupervisors(approvedOnly: true);
      if (!mounted) return;
      setState(() {
        _students = students;
        _supervisors = supervisors;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _students;
    if (_filter == 'Assigned') list = list.where((s) => s['supervisor_name'] != null).toList();
    if (_filter == 'Unassigned') list = list.where((s) => s['supervisor_name'] == null).toList();
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      list = list.where((s) => ((s['full_name'] as String?) ?? '').toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> _assign(Map<String, dynamic> student) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(alignment: Alignment.centerLeft, child: Text(l10n.adminAssignSupervisor, style: AppTextStyles.h3)),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ..._supervisors.map((sup) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: nameColor(sup['full_name'] as String? ?? '').withOpacity(0.15),
                          child: Text(logoLetter(sup['full_name'] as String? ?? '?'),
                              style: TextStyle(fontWeight: FontWeight.w700, color: nameTextColor(sup['full_name'] as String? ?? ''))),
                        ),
                        title: Text((sup['full_name'] as String?)?.isNotEmpty == true ? sup['full_name'] as String : l10n.adminUnnamed),
                        subtitle: Text(l10n.supStudentsCount(sup['student_count'] as int)),
                        onTap: () => Navigator.pop(context, sup),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (selected == null) return;
    try {
      await AdminDataService.instance.assignSupervisor(
        studentId: student['id'] as String,
        supervisorId: selected.isEmpty ? null : selected['id'] as String,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminCouldNotAssign(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filterLabels = {'All': l10n.adminFilterAll, 'Assigned': l10n.adminFilterAssigned, 'Unassigned': l10n.adminFilterUnassigned};
    final results = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.adminStudentsTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AdminCreateStudentsScreen()));
          if (created == true) _load();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
        label: Text(l10n.adminAddStudents, style: const TextStyle(color: Colors.white)),
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
                      decoration: InputDecoration(hintText: l10n.adminSearchByNameHint, prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted)),
                    ),
                  ),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: ['All', 'Assigned', 'Unassigned']
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(filterLabels[s]!),
                                  selected: _filter == s,
                                  onSelected: (_) => setState(() => _filter = s),
                                  labelStyle: TextStyle(
                                      fontSize: 12,
                                      color: _filter == s ? AppColors.primary : AppColors.textSecondary,
                                      fontWeight: _filter == s ? FontWeight.w600 : FontWeight.w400),
                                  selectedColor: AppColors.accent,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(children: [Flexible(child: Text(l10n.supStudentsCount(results.length), style: AppTextStyles.caption, overflow: TextOverflow.ellipsis))]),
                  ),
                  Expanded(
                    child: results.isEmpty
                        ? EmptyState(icon: Icons.school_outlined, title: l10n.adminNoStudentsFoundTitle, description: l10n.adminNoStudentsFoundDescription)
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: results.length,
                            itemBuilder: (_, i) => _StudentCard(
                              data: results[i],
                              onAssign: () => _assign(results[i]),
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: results[i]['id'] as String, adminMode: true)));
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

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAssign;
  final VoidCallback onTap;

  const _StudentCard({required this.data, required this.onAssign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = (data['email'] as String?) ?? '';
    final name = (data['full_name'] as String?)?.isNotEmpty == true
        ? data['full_name'] as String
        : (email.isNotEmpty ? email : l10n.adminUnnamedStudent);
    final neverLoggedIn = data['has_logged_in'] == false;
    final supervisorName = data['supervisor_name'] as String?;
    final isUnassigned = supervisorName == null;

    return AccentCard(
      accentColor: isUnassigned ? AppColors.error : AppColors.success,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceVariant,
            child: Text(logoLetter(name), style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text((data['programme'] as String?) ?? l10n.adminProgrammeNotSet, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                if (neverLoggedIn)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(l10n.adminNeverLoggedIn,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning)),
                    ),
                  ),
                Text(
                  supervisorName != null ? l10n.adminSupervisorColonName(supervisorName) : l10n.adminNoSupervisorAssigned,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: isUnassigned ? AppColors.error : AppColors.primary),
                ),
              ],
            ),
          ),
          // A student who already has an academic supervisor is shown as assigned and cannot be given
          // another one from here (to change it, remove the assignment on the student's page first).
          if (isUnassigned)
            TextButton(onPressed: onAssign, child: Text(l10n.adminAssign))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
              child: Text(l10n.adminFilterAssigned,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
            ),
        ],
      ),
    );
  }
}
