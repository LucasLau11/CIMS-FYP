import 'package:flutter/material.dart';

import '../screens/student/student_messages_screen.dart' show ChatScreen;
import '../services/admin_data_service.dart';
import '../services/student_data_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_text.dart';
import '../utils/lang.dart';

/// Opens the chat with [profileId], starting the conversation when it does not exist yet (the
/// database decides who may start one with whom). Shows the reason in a message when it cannot.
Future<void> openChatWith(BuildContext context, String profileId) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    final conversation = await StudentDataService.instance.getOrCreateConversation(profileId);
    final other = await StudentDataService.instance.getDirectoryProfile(profileId);
    await navigator.push(MaterialPageRoute(
      builder: (_) => ChatScreen(conversationId: conversation['id'] as String, otherProfile: other),
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('${tt('Could not open chat')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
  }
}

/// "Message" button for another person's profile.
class MessageButton extends StatelessWidget {
  const MessageButton({super.key, required this.profileId, this.expanded = true});

  final String profileId;

  /// Full-width (profile pages) or sized to its label (inside a list row).
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: () => openChatWith(context, profileId),
      icon: const Icon(Icons.chat_bubble_outline, size: 18),
      label: Text(tt('Message')),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// What an administrator can do to somebody else's account: suspend (and bring back) or remove it.
/// [status] is the account's `approval_status`; [onChanged] runs after something was done so the
/// screen can reload; [onRemoved] runs after the account was removed (the screen usually closes).
class AdminAccountButtons extends StatefulWidget {
  const AdminAccountButtons({
    super.key,
    required this.profileId,
    required this.name,
    required this.status,
    required this.onChanged,
    this.onRemoved,
    this.compact = false,
  });

  final String profileId;
  final String name;
  final String? status;
  final VoidCallback onChanged;
  final VoidCallback? onRemoved;

  /// Icon-only buttons, for rows in a list.
  final bool compact;

  @override
  State<AdminAccountButtons> createState() => _AdminAccountButtonsState();
}

class _AdminAccountButtonsState extends State<AdminAccountButtons> {
  bool _busy = false;

  bool get _suspended => widget.status == 'suspended';

  Future<void> _toggleSuspend() async {
    final suspend = !_suspended;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(suspend
            ? tr('Suspend this account?', ms: 'Gantung akaun ini?', zh: '暂停此账户？')
            : tr('Reactivate this account?', ms: 'Aktifkan semula akaun ini?', zh: '重新启用此账户？')),
        content: Text(suspend
            ? tr('${widget.name} will be signed out and cannot log in until you reactivate the account. Nothing is deleted.',
                ms: '${widget.name} akan dilog keluar dan tidak boleh log masuk sehingga anda mengaktifkan semula akaun. Tiada yang dipadam.',
                zh: '${widget.name}将被退出登录，在您重新启用账户之前无法登录。不会删除任何数据。')
            : tr('${widget.name} will be able to log in again.',
                ms: '${widget.name} boleh log masuk semula.', zh: '${widget.name}将可以再次登录。')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tt('Cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(suspend ? tr('Suspend', ms: 'Gantung', zh: '暂停') : tr('Reactivate', ms: 'Aktifkan semula', zh: '重新启用'),
                style: TextStyle(color: suspend ? AppColors.error : AppColors.primaryText)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => AdminDataService.instance.setAccountSuspended(widget.profileId, suspended: suspend), onDone: widget.onChanged);
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Remove this account?', ms: 'Buang akaun ini?', zh: '移除此账户？')),
        content: Text(tr(
            'The personal details of ${widget.name} are wiped and the account can no longer log in. Reports and messages others rely on stay, shown as "Deleted user". This cannot be undone.',
            ms: 'Butiran peribadi ${widget.name} dipadam dan akaun tidak boleh log masuk lagi. Laporan dan mesej yang diperlukan orang lain kekal, dipaparkan sebagai "Deleted user". Ini tidak boleh dibatalkan.',
            zh: '${widget.name}的个人信息将被清除，此账户将无法再登录。他人需要的报告和消息会保留，显示为“Deleted user”。此操作无法撤销。')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tt('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tt('Remove'), style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => AdminDataService.instance.removeAccount(widget.profileId), onDone: widget.onRemoved ?? widget.onChanged);
  }

  Future<void> _run(Future<void> Function() action, {required VoidCallback onDone}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() => _busy = false);
      onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSuspend = widget.status == 'approved' || _suspended;
    final suspendLabel = _suspended ? tr('Reactivate', ms: 'Aktifkan semula', zh: '重新启用') : tr('Suspend', ms: 'Gantung', zh: '暂停');
    final suspendIcon = _suspended ? Icons.lock_open_outlined : Icons.pause_circle_outline;

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canSuspend)
            IconButton(tooltip: suspendLabel, icon: Icon(suspendIcon, size: 20), onPressed: _busy ? null : _toggleSuspend),
          IconButton(
              tooltip: tt('Remove'),
              icon: Icon(Icons.person_remove_outlined, size: 20, color: AppColors.error),
              onPressed: _busy ? null : _remove),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_suspended)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
            child: Text(
              tr('This account is suspended and cannot log in.', ms: 'Akaun ini digantung dan tidak boleh log masuk.', zh: '此账户已被暂停，无法登录。'),
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.warning),
            ),
          ),
        if (canSuspend)
          OutlinedButton.icon(
            onPressed: _busy ? null : _toggleSuspend,
            icon: Icon(suspendIcon, size: 18),
            label: Text(suspendLabel),
          ),
        if (canSuspend) const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _remove,
          icon: Icon(Icons.person_remove_outlined, size: 18, color: AppColors.error),
          label: Text(tr('Remove account', ms: 'Buang akaun', zh: '移除账户'), style: TextStyle(color: AppColors.error)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error)),
        ),
      ],
    );
  }
}
