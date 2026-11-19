import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/admin_data_service.dart';
import '../../utils/error_text.dart';
import '../../utils/lang.dart';

/// Supervisors and company staff register themselves, but their accounts stay
/// "pending" — with no access to anything — until an administrator confirms
/// they are who they say they are. This screen lists those accounts.
class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pending = [];
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final rows = await AdminDataService.instance.getPendingApprovals();
      if (!mounted) return;
      setState(() {
        _pending = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error),
      );
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'academic_supervisor':
        return 'Academic supervisor';
      case 'company_hr':
        return 'Company HR';
      case 'company_supervisor':
        return 'Company supervisor';
      default:
        return role ?? 'Unknown role';
    }
  }

  Future<void> _decide(Map<String, dynamic> account, String status) async {
    final id = account['profile_id'] as String;
    final approve = status == 'approved';
    final name = (account['full_name'] as String?)?.trim().isNotEmpty == true
        ? account['full_name'] as String
        : (account['email'] as String? ?? 'this account');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve account?' : 'Reject account?',
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(approve
            ? '$name will be able to log in as ${_roleLabel(account['role'] as String?).toLowerCase()} straight away.'
            : '$name will not be able to log in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(tt('Cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy.add(id));
    try {
      await AdminDataService.instance.setApprovalStatus(id, status);
      if (!mounted) return;
      setState(() => _pending.removeWhere((a) => a['profile_id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Account approved.' : 'Account rejected.'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: tt('Pending approvals')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: _pending.isEmpty
                  ? ListView(
                      children: [
                        EmptyState(
                          icon: Icons.verified_user_outlined,
                          title: tt('Nothing waiting'),
                          description: 'New supervisor and company accounts appear here until you approve them.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _pending.length,
                      itemBuilder: (_, i) {
                        final account = _pending[i];
                        final id = account['profile_id'] as String;
                        final busy = _busy.contains(id);
                        final name = (account['full_name'] as String?)?.trim();
                        return AccentCard(
                          accentColor: AppColors.warning,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name == null || name.isEmpty ? 'Name not set' : name,
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(account['email'] as String? ?? '', style: AppTextStyles.caption),
                              const SizedBox(height: 4),
                              Text(_roleLabel(account['role'] as String?), style: AppTextStyles.caption),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: busy ? null : () => _decide(account, 'rejected'),
                                      child: Text(tt('Reject')),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: busy ? null : () => _decide(account, 'approved'),
                                      child: busy
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : Text(tt('Approve')),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
