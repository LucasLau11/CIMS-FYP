import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../login_screen.dart';
import '../student/student_messages_screen.dart' show StudentMessagesScreen;
import '../student/student_notifications_screen.dart' show StudentNotificationsScreen;
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
  File? _localPreviewImage;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  bool _isChangingPassword = false;
  static const List<String> _allowedImageExtensions = ['.jpg', '.jpeg', '.png'];
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
        _avatarUrl = profile?['avatar_url'] as String?;
      });
    } catch (_) {
      // Non-fatal — falls back to the known admin email.
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 800);
      if (picked == null) return;

      final lowerPath = picked.path.toLowerCase();
      if (!_allowedImageExtensions.any((ext) => lowerPath.endsWith(ext))) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Unsupported file format. Please upload a JPG, JPEG, or PNG image.'), backgroundColor: AppColors.error),
        );
        return;
      }

      final file = File(picked.path);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      if (!exists || size == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exists ? 'The selected photo is empty (0 bytes). Try a different photo.' : 'The selected photo could not be found on disk.'), backgroundColor: AppColors.error),
        );
        return;
      }

      setState(() {
        _localPreviewImage = file;
        _isUploadingAvatar = true;
      });

      try {
        final uploadedUrl = await AuthService.instance.uploadAvatar(file);
        if (!mounted) return;
        setState(() {
          _avatarUrl = uploadedUrl;
          _localPreviewImage = null;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated'), backgroundColor: AppColors.primary),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _localPreviewImage = null;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e')));
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _isUploadingAvatar = true);
    try {
      await AuthService.instance.removeAvatar();
      if (!mounted) return;
      setState(() {
        _avatarUrl = null;
        _localPreviewImage = null;
        _isUploadingAvatar = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not remove photo: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('Update photo', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700))),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            if (_avatarUrl != null || _localPreviewImage != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Remove photo', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removePhoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
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
              title: const Text('Change password', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: currentController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current password',
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
                        labelText: 'New password',
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
                        labelText: 'Confirm new password',
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
                TextButton(onPressed: _isChangingPassword ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: _isChangingPassword
                      ? null
                      : () async {
                          if (currentController.text.isEmpty) {
                            setDialogState(() => errorText = 'Enter your current password.');
                            return;
                          }
                          final strengthError = AuthService.instance.validatePassword(newController.text);
                          if (strengthError != null) {
                            setDialogState(() => errorText = strengthError);
                            return;
                          }
                          if (newController.text != confirmController.text) {
                            setDialogState(() => errorText = 'New passwords do not match.');
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
                              const SnackBar(content: Text('Password changed'), backgroundColor: AppColors.primary),
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
                      : const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLanguagePicker() {
    const languages = ['English', 'Bahasa Malaysia', '中文'];
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select language', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save language: $e'), backgroundColor: AppColors.error));
                  }
                },
              );
            }).toList(),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel'))],
        );
      },
    );
  }

  String get _themeLabel => switch (_selectedThemeCode) {
        'light' => 'Light',
        'dark' => 'Dark',
        _ => 'System',
      };

  void _showNotificationPreferences() {
    const labels = {
      'application_updates': 'Application & applicant updates',
      'report_deadlines': 'Report & document reviews',
      'messages': 'Messages',
      'supervisor_feedback': 'Evaluation reminders',
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
                    const Text('Notification preferences', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Choose what you want to be notified about', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
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
                              const SnackBar(content: Text('Notification preferences updated'), backgroundColor: AppColors.primary),
                            );
                          } catch (e) {
                            if (!sheetContext.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        },
                        child: const Text('Save'),
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
    const options = {'light': 'Light', 'dark': 'Dark', 'system': 'System'};
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select theme', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
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
                      SnackBar(content: Text('Could not save theme: $e'), backgroundColor: AppColors.error),
                    );
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('You will need to log in again to access the admin console.', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('Log out', style: TextStyle(color: AppColors.error))),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'More'),
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
                        const Text('System Administrator', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text(_email, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Oversight'),
          _MenuTile(
            icon: Icons.monitor_heart_outlined,
            label: 'Monitor',
            subtitle: 'Student progress, reports & documents',
            color: AppColors.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMonitorScreen())),
          ),
          const SectionHeader(title: 'Communication'),
          _MenuTile(
            icon: Icons.send_outlined,
            label: 'Messages',
            subtitle: 'Message students, supervisors, or companies',
            color: AppColors.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentMessagesScreen())),
          ),
          _MenuTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            subtitle: 'View system alerts and updates',
            color: AppColors.warning,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentNotificationsScreen())),
          ),
          const SectionHeader(title: 'Preferences'),
          _MenuTile(
            icon: Icons.camera_alt_outlined,
            label: 'Profile photo',
            subtitle: 'Update or remove your profile photo',
            color: AppColors.primary,
            onTap: _isUploadingAvatar ? () {} : _showPhotoOptions,
          ),
          _MenuTile(
            icon: Icons.lock_outline,
            label: 'Change password',
            subtitle: null,
            color: AppColors.primary,
            onTap: _showChangePasswordDialog,
          ),
          _MenuTile(
            icon: Icons.notifications_active_outlined,
            label: 'Notification preferences',
            subtitle: 'Choose what you get notified about',
            color: AppColors.primary,
            onTap: _showNotificationPreferences,
          ),
          _MenuTile(
            icon: Icons.language_outlined,
            label: 'Language',
            subtitle: _selectedLanguage,
            color: AppColors.primary,
            onTap: _showLanguagePicker,
          ),
          _MenuTile(
            icon: Icons.dark_mode_outlined,
            label: 'Theme',
            subtitle: _themeLabel,
            color: AppColors.primary,
            onTap: _showThemePicker,
          ),
          const SectionHeader(title: 'System'),
          _MenuTile(icon: Icons.logout, label: 'Log out', subtitle: null, color: AppColors.error, isDestructive: true, onTap: _logOut),
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
