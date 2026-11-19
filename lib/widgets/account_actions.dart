import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/login_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_text.dart';
import '../utils/validators.dart';
import 'common/validated_field.dart';
import '../utils/lang.dart';

/// Opens the in-app privacy notice.
void openPrivacyPolicy(BuildContext context) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
}

/// "Change password" dialog shared by every role's profile screen. All three
/// fields are checked live: the new password ticks off the strength rules as
/// it is typed, must differ from the current one, and must match its
/// confirmation. Only the server can tell whether the current password is
/// right, so that message appears under the current-password field after
/// pressing Change.
Future<void> showChangePasswordDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final formKey = GlobalKey<FormState>();
  final current = TextEditingController();
  final fresh = TextEditingController();
  final confirm = TextEditingController();
  bool hideCurrent = true, hideFresh = true, hideConfirm = true, saving = false;
  String? currentError;
  String? generalError;

  Widget eye(bool hidden, VoidCallback toggle) => IconButton(
        icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20, color: AppColors.textMuted),
        onPressed: toggle,
      );

  final changed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(l10n.changePassword,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValidatedField(
                  controller: current,
                  fieldValidator: (v) => v.isEmpty ? tr('Enter your current password.', ms: 'Masukkan kata laluan semasa anda.', zh: '请输入当前密码。') : null,
                  obscureText: hideCurrent,
                  showSuccess: false,
                  labelText: l10n.currentPassword,
                  externalError: currentError,
                  suffix: eye(hideCurrent, () => setDialogState(() => hideCurrent = !hideCurrent)),
                  onChanged: (_) {
                    if (currentError != null || generalError != null) {
                      setDialogState(() {
                        currentError = null;
                        generalError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                ValidatedField(
                  controller: fresh,
                  fieldValidator: (v) {
                    final rule = Validators.password(v);
                    if (rule != null) return rule;
                    if (v == current.text) return tr('The new password must be different from the current one.', ms: 'Kata laluan baharu mesti berbeza daripada yang semasa.', zh: '新密码必须与当前密码不同。');
                    return null;
                  },
                  obscureText: hideFresh,
                  showSuccess: false,
                  labelText: l10n.newPassword,
                  suffix: eye(hideFresh, () => setDialogState(() => hideFresh = !hideFresh)),
                  onChanged: (_) {
                    if (generalError != null) setDialogState(() => generalError = null);
                    if (confirm.text.isNotEmpty) formKey.currentState?.validate();
                  },
                ),
                PasswordChecklist(controller: fresh),
                const SizedBox(height: 12),
                ValidatedField(
                  controller: confirm,
                  fieldValidator: (v) => Validators.confirmPassword(v, fresh.text),
                  obscureText: hideConfirm,
                  showSuccess: false,
                  labelText: l10n.confirmNewPassword,
                  suffix: eye(hideConfirm, () => setDialogState(() => hideConfirm = !hideConfirm)),
                ),
                if (generalError != null) ...[
                  const SizedBox(height: 10),
                  Text(generalError!,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: saving
                ? null
                : () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    setDialogState(() {
                      saving = true;
                      currentError = null;
                      generalError = null;
                    });
                    try {
                      await AuthService.instance
                          .changePassword(currentPassword: current.text, newPassword: fresh.text);
                      if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                    } on WrongCurrentPasswordException catch (e) {
                      setDialogState(() {
                        saving = false;
                        currentError = e.message;
                      });
                    } catch (e) {
                      setDialogState(() {
                        saving = false;
                        generalError = friendlyError(e);
                      });
                    }
                  },
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.change),
          ),
        ],
      ),
    ),
  );

  current.dispose();
  fresh.dispose();
  confirm.dispose();

  if (changed == true) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.profilePasswordChanged), backgroundColor: AppColors.primary),
    );
  }
}

/// "Delete my account" flow shared by every role's profile screen. The user
/// must type DELETE to confirm; on success they are signed out and returned
/// to the login screen. See [AuthService.deleteMyAccount] for what it does.
Future<void> showDeleteAccountFlow(BuildContext context) async {
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(tt('Delete my account'),
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                'This permanently removes your personal details (name, contact '
                    'details, resume, photo) and blocks this account from logging in. '
                    'Reports and evaluations that others rely on are kept, without '
                    'your details. This cannot be undone.',
                ms: 'Ini memadam butiran peribadi anda (nama, butiran hubungan, resume, gambar) secara kekal '
                    'dan menyekat akaun ini daripada log masuk. Laporan dan penilaian yang diperlukan oleh '
                    'orang lain disimpan, tanpa butiran anda. Ini tidak boleh dibatalkan.',
                zh: '这将永久删除您的个人信息（姓名、联系方式、简历、照片），并禁止此账户登录。'
                    '他人需要依赖的报告和评估会保留，但不含您的个人信息。此操作无法撤销。',
              ),
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.4, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setDialogState(() {}),
              decoration: InputDecoration(
                  labelText: tr('Type DELETE to confirm', ms: 'Taip DELETE untuk mengesahkan', zh: '输入 DELETE 以确认')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(tt('Cancel'))),
          TextButton(
            onPressed: controller.text.trim() == 'DELETE' ? () => Navigator.pop(dialogContext, true) : null,
            child: Text(tt('Delete'), style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (confirmed != true || !context.mounted) return;

  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );

  try {
    await AuthService.instance.deleteMyAccount();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    messenger.showSnackBar(SnackBar(content: Text(tr('Your account has been deleted.', ms: 'Akaun anda telah dipadam.', zh: '您的账户已被删除。'))));
  } catch (e) {
    navigator.pop(); // close the progress dialog
    messenger.showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
  }
}
