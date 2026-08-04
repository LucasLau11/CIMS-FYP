import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import '../student/student_messages_screen.dart' show StudentMessagesScreen;
import '../student/student_notifications_screen.dart' show StudentNotificationsScreen;
import 'admin_document_templates_screen.dart';
import 'admin_monitor_screen.dart';
import 'admin_profile_screen.dart';

class AdminMoreScreen extends StatefulWidget {
  const AdminMoreScreen({super.key});

  @override
  State<AdminMoreScreen> createState() => _AdminMoreScreenState();
}

class _AdminMoreScreenState extends State<AdminMoreScreen> {
  String _email = '';
  String _selectedThemeCode = 'system';
  String _selectedLanguage = 'English';
  bool _isChangingPassword = false;
  final Map<String, bool> _notificationPrefs = {
    'application_updates': true,
    'report_deadlines': true,
    'messages': true,
    'supervisor_feedback': false,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await AuthService.instance.getCurrentProfile();
      if (!mounted) return;

      final rawPrefs = profile?['notification_prefs'] as Map<String, dynamic>?;
      if (rawPrefs != null) {
        for (final key in _notificationPrefs.keys.toList()) {
          if (rawPrefs.containsKey(key)) _notificationPrefs[key] = rawPrefs[key] as bool;
        }
      }

      setState(() {
        _email = profile?['email'] as String? ?? '';
        _selectedThemeCode = profile?['theme_mode'] as String? ?? 'system';
        _selectedLanguage = profile?['language'] as String? ?? 'English';
      });
    } catch (_) {
      // Non-fatal — falls back to the known admin email.
    }
  }

  void _showChangePasswordDialog() {
    final l10n = AppLocalizations.of(context)!;
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.changePassword, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: currentController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: l10n.currentPassword,
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: l10n.newPassword,
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: l10n.confirmNewPassword,
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(errorText!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: _isChangingPassword ? null : () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
                ElevatedButton(
                  onPressed: _isChangingPassword
                      ? null
                      : () async {
                          if (currentController.text.isEmpty) {
                            setDialogState(() => errorText = l10n.adminEnterCurrentPassword);
                            return;
                          }
                          final strengthError = AuthService.instance.validatePassword(newController.text);
                          if (strengthError != null) {
                            setDialogState(() => errorText = strengthError);
                            return;
                          }
                          if (newController.text != confirmController.text) {
                            setDialogState(() => errorText = l10n.adminNewPasswordsDoNotMatch);
                            return;
                          }
                          setDialogState(() {
                            errorText = null;
                            _isChangingPassword = true;
                          });
                          try {
                            await AuthService.instance.changePassword(currentPassword: currentController.text, newPassword: newController.text);
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            setState(() => _isChangingPassword = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.adminPasswordChanged), backgroundColor: AppColors.primary),
                            );
                          } catch (e) {
                            setDialogState(() {
                              _isChangingPassword = false;
                              errorText = e.toString().replaceFirst('Exception: ', '');
                            });
                          }
                        },
                  child: _isChangingPassword
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.change),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLanguagePicker() {
    final l10n = AppLocalizations.of(context)!;
    const languages = ['English', 'Bahasa Malaysia', '中文'];
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.profileSelectLanguage, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(lang, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                value: lang,
                groupValue: _selectedLanguage,
                activeColor: AppColors.primary,
                onChanged: (val) async {
                  Navigator.pop(dialogContext);
                  setState(() => _selectedLanguage = val!);
                  try {
                    await AuthService.instance.updateLanguage(val!);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorCouldNotSaveLanguage(e.toString())), backgroundColor: AppColors.error));
                  }
                },
              );
            }).toList(),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel))],
        );
      },
    );
  }

  String get _themeLabel {
    final l10n = AppLocalizations.of(context)!;
    return switch (_selectedThemeCode) {
      'light' => l10n.themeLight,
      'dark' => l10n.themeDark,
      _ => l10n.themeSystem,
    };
  }

  void _showNotificationPreferences() {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      'application_updates': l10n.profileApplicationApplicantUpdates,
      'report_deadlines': l10n.profileReportDocumentReviews,
      'messages': l10n.profileMessages,
      'supervisor_feedback': l10n.profileEvaluationReminders,
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.notificationPreferences, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(l10n.profileChooseWhatToBeNotified, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ..._notificationPrefs.keys.map((key) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(labels[key]!, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                        value: _notificationPrefs[key]!,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setSheetState(() => _notificationPrefs[key] = val);
                          setState(() {});
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await AuthService.instance.updateNotificationPrefs(_notificationPrefs);
                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.profileNotificationPrefsUpdated), backgroundColor: AppColors.primary),
                            );
                          } catch (e) {
                            if (!sheetContext.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.adminCouldNotSave(e.toString())), backgroundColor: AppColors.error),
                            );
                          }
                        },
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showThemePicker() {
    final l10n = AppLocalizations.of(context)!;
    final options = {'light': l10n.themeLight, 'dark': l10n.themeDark, 'system': l10n.themeSystem};
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.selectTheme, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.entries.map((entry) {
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.value, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                value: entry.key,
                groupValue: _selectedThemeCode,
                activeColor: AppColors.primary,
                onChanged: (val) async {
                  Navigator.pop(dialogContext);
                  setState(() => _selectedThemeCode = val!);
                  try {
                    await AuthService.instance.updateThemeMode(val!);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.errorCouldNotSaveTheme(e.toString())), backgroundColor: AppColors.error),
                    );
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ],
        );
      },
    );
  }

  Future<void> _logOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logOutConfirmTitle, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(l10n.adminLogOutConfirmMessage, style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.logOut, style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.adminMoreTitle),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
              _load();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.adminSystemAdministrator, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text(_email, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
          SectionHeader(title: l10n.adminSectionOversight),
          _MenuTile(
            icon: Icons.monitor_heart_outlined,
            label: l10n.adminMonitorTitle,
            subtitle: l10n.adminMonitorSubtitle,
            color: AppColors.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMonitorScreen())),
          ),
          _MenuTile(
            icon: Icons.description_outlined,
            label: l10n.adminDocumentTemplatesTitle,
            subtitle: l10n.adminDocumentTemplatesSubtitle,
            color: AppColors.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDocumentTemplatesScreen())),
          ),
          SectionHeader(title: l10n.adminSectionCommunication),
          _MenuTile(
            icon: Icons.send_outlined,
            label: l10n.profileMessages,
            subtitle: l10n.adminMessagesSubtitle,
            color: AppColors.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentMessagesScreen())),
          ),
          _MenuTile(
            icon: Icons.notifications_outlined,
            label: l10n.adminNotifications,
            subtitle: l10n.adminNotificationsSubtitle,
            color: AppColors.warning,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentNotificationsScreen())),
          ),
          SectionHeader(title: l10n.adminSectionPreferences),
          _MenuTile(
            icon: Icons.lock_outline,
            label: l10n.changePassword,
            subtitle: null,
            color: AppColors.primary,
            onTap: _showChangePasswordDialog,
          ),
          _MenuTile(
            icon: Icons.notifications_active_outlined,
            label: l10n.notificationPreferences,
            subtitle: l10n.adminNotifPrefsSubtitle,
            color: AppColors.primary,
            onTap: _showNotificationPreferences,
          ),
          _MenuTile(
            icon: Icons.language_outlined,
            label: l10n.language,
            subtitle: _selectedLanguage,
            color: AppColors.primary,
            onTap: _showLanguagePicker,
          ),
          _MenuTile(
            icon: Icons.dark_mode_outlined,
            label: l10n.theme,
            subtitle: _themeLabel,
            color: AppColors.primary,
            onTap: _showThemePicker,
          ),
          SectionHeader(title: l10n.adminSectionSystem),
          _MenuTile(icon: Icons.logout, label: l10n.logOut, subtitle: null, color: AppColors.error, isDestructive: true, onTap: _logOut),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 19, color: color),
        ),
        title: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: isDestructive ? AppColors.error : AppColors.textPrimary)),
        subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.caption) : null,
        trailing: Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}
