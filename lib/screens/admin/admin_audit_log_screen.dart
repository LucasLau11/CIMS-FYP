import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/admin_data_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_text.dart';
import '../../utils/interview_format.dart';
import '../../widgets/common/shared_widgets.dart';

/// Who did what: approvals, role changes, company and intake changes,
/// supervisor assignments and account creation. Read-only; the rows are
/// written by the database itself, so nothing can be left out or edited here.
class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  static const _pageSize = 100;

  // filter key -> action prefixes it covers (null = everything)
  static const Map<String, List<String>?> _filters = {
    'all': null,
    'accounts': ['account_', 'role_changed', 'students_created', 'supervisors_created'],
    'companies': ['company_'],
    'students': ['supervisor_assigned', 'intake_assigned'],
    'setup': ['intake_', 'template_'],
  };

  String _filter = 'all';
  int _limit = _pageSize;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await AdminDataService.instance.getAuditLog(actionPrefixes: _filters[_filter], limit: _limit);
      if (!mounted) return;
      setState(() {
        _entries = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  String _label(AppLocalizations l10n, String key) {
    switch (key) {
      case 'accounts':
        return l10n.auditFilterAccounts;
      case 'companies':
        return l10n.auditFilterCompanies;
      case 'students':
        return l10n.auditFilterStudents;
      case 'setup':
        return l10n.auditFilterSetup;
      default:
        return l10n.auditFilterAll;
    }
  }

  IconData _icon(String action) {
    if (action.startsWith('account_')) return Icons.manage_accounts_outlined;
    if (action == 'role_changed') return Icons.swap_horiz;
    if (action == 'students_created' || action == 'supervisors_created') return Icons.person_add_alt_1_outlined;
    if (action.startsWith('company_')) return Icons.business_outlined;
    if (action == 'supervisor_assigned') return Icons.supervisor_account_outlined;
    if (action.startsWith('intake_')) return Icons.groups_outlined;
    if (action.startsWith('template_')) return Icons.description_outlined;
    return Icons.history;
  }

  Color _color(String action) {
    if (action.endsWith('_rejected') || action.endsWith('_deleted') || action.endsWith('deactivated')) return AppColors.error;
    if (action.endsWith('_approved') || action.endsWith('_created') || action.endsWith('activated')) return AppColors.success;
    return AppColors.primaryText;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.adminAuditLogTitle),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final key in _filters.keys)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_label(l10n, key)),
                      selected: _filter == key,
                      labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textPrimary),
                      onSelected: (_) {
                        setState(() {
                          _filter = key;
                          _limit = _pageSize;
                        });
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _entries.isEmpty
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? EmptyState(icon: Icons.error_outline, title: _error!, description: '')
                    : _entries.isEmpty
                        ? EmptyState(icon: Icons.history, title: l10n.auditEmpty, description: '')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: _entries.length + (_entries.length >= _limit ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i == _entries.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() => _limit += _pageSize);
                                        _load();
                                      },
                                      child: Text(l10n.auditLoadMore),
                                    ),
                                  );
                                }
                                return _AuditTile(
                                  entry: _entries[i],
                                  icon: _icon(_entries[i]['action'] as String),
                                  color: _color(_entries[i]['action'] as String),
                                  systemLabel: l10n.auditSystem,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final IconData icon;
  final Color color;
  final String systemLabel;

  const _AuditTile({required this.entry, required this.icon, required this.color, required this.systemLabel});

  @override
  Widget build(BuildContext context) {
    final actor = entry['actor'] as Map?;
    final actorName = (actor?['full_name'] as String?)?.trim().isNotEmpty == true
        ? actor!['full_name'] as String
        : (actor?['email'] as String?) ?? systemLabel;
    final role = (entry['actor_role'] as String?)?.replaceAll('_', ' ');
    final when = DateTime.parse(entry['created_at'] as String).toLocal();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry['summary'] as String,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('$actorName${role == null ? '' : ' ($role)'} · ${formatInterviewDateTime(when)}', style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
