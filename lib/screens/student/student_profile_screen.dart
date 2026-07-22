import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  File? _profileImage;
  String _selectedLanguage = 'English';

  // In-memory only for now — no backend persistence wired up yet.
  final Map<String, bool> _notificationPrefs = {
    'Application updates': true,
    'Report deadlines': true,
    'Messages': true,
    'Supervisor feedback': false,
  };

  static const List<String> _allowedImageExtensions = ['.jpg', '.jpeg', '.png'];

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return;

      final lowerPath = picked.path.toLowerCase();
      final hasAllowedExtension =
      _allowedImageExtensions.any((ext) => lowerPath.endsWith(ext));

      if (!hasAllowedExtension) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsupported file format. Please upload a JPG, JPEG, or PNG image.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final file = File(picked.path);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;

      if (!exists || size == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exists
                ? 'The selected photo is empty (0 bytes) — this can happen with broken sample images on some emulators. Try a different photo.'
                : 'The selected photo could not be found on disk (path: ${picked.path}).'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _profileImage = file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e')),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Update profile photo',
                    style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Take a photo'),
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
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Remove photo', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _profileImage = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showNotificationPreferences() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                    const Text('Notification preferences',
                        style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Choose what you want to be notified about.',
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ..._notificationPrefs.keys.map((key) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(key,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
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
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Notification preferences updated.'),
                                backgroundColor: AppColors.primary),
                          );
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

  void _showLanguagePicker() {
    const languages = ['English', 'Bahasa Malaysia', '中文'];
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select language',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(lang, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                value: lang,
                groupValue: _selectedLanguage,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _selectedLanguage = val!);
                  Navigator.pop(dialogContext);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('You will need to log in again to access your account.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      children: [
                        ClipOval(
                          child: Container(
                            width: 88,
                            height: 88,
                            color: Colors.white24,
                            child: _profileImage != null
                                ? Image.file(
                              _profileImage!,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Surface decode failures instead of
                                // silently showing a blank circle.
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Could not load the selected photo: ${error.toString().split('\n').first}'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                });
                                return const Center(
                                  child: Text('TK',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                );
                              },
                            )
                                : const Center(
                              child: Text('TK',
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _showPhotoOptions,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 14, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Tan Kai Ming',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const Text('22CSB12345 · Bachelor of Computer Science',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Status card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Currently on internship',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            Text('Tencent Malaysia · Jun – Aug 2026',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: Colors.white70)),
                          ],
                        ),
                      ),
                      StatusBadge.active(),
                    ],
                  ),
                ),

                // Personal info
                const SectionHeader(title: 'Personal information'),
                _InfoSection(
                  items: const [
                    _InfoItem(icon: Icons.person_outline, label: 'Full name', value: 'Tan Kai Ming'),
                    _InfoItem(icon: Icons.badge_outlined, label: 'Student ID', value: '22CSB12345'),
                    _InfoItem(icon: Icons.phone_outlined, label: 'Phone', value: '+60 12-345 6789'),
                    _InfoItem(icon: Icons.email_outlined, label: 'Email', value: 'tankai@student.tarumt.edu.my'),
                    _InfoItem(icon: Icons.cake_outlined, label: 'Date of birth', value: '15 Mar 2002'),
                    _InfoItem(icon: Icons.location_on_outlined, label: 'Address', value: 'Kuala Lumpur, Malaysia'),
                  ],
                ),

                // Academic info
                const SectionHeader(title: 'Academic information'),
                _InfoSection(
                  items: const [
                    _InfoItem(icon: Icons.school_outlined, label: 'Programme', value: 'Bachelor of Computer Science (Hons)'),
                    _InfoItem(icon: Icons.calendar_today_outlined, label: 'Semester', value: 'Semester 6'),
                    _InfoItem(icon: Icons.class_outlined, label: 'Faculty', value: 'Faculty of Computing and Information Technology'),
                    _InfoItem(icon: Icons.grade_outlined, label: 'CGPA', value: '3.62'),
                    _InfoItem(icon: Icons.person_pin_outlined, label: 'Academic Supervisor', value: 'Dr. Lim Wei Shan'),
                  ],
                ),

                // Resume
                const SectionHeader(title: 'Resume'),
                AccentCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.picture_as_pdf_outlined,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('tankai_resume_2026.pdf',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text('312 KB · Updated 30 May 2026',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Replace'),
                      ),
                    ],
                  ),
                ),

                // Settings
                const SectionHeader(title: 'Account'),
                _SettingsTile(
                    icon: Icons.lock_outline,
                    label: 'Change password',
                    onTap: () {}),
                _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notification preferences',
                    onTap: _showNotificationPreferences),
                _SettingsTile(
                    icon: Icons.language_outlined,
                    label: 'Language',
                    trailing: _selectedLanguage,
                    onTap: _showLanguagePicker),
                _SettingsTile(
                    icon: Icons.logout,
                    label: 'Log out',
                    isDestructive: true,
                    onTap: _handleLogout),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: AppTextStyles.caption),
                        const SizedBox(height: 2),
                        Text(item.value,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 44),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 20, color: isDestructive ? AppColors.error : AppColors.textSecondary),
        title: Text(label,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color)),
        trailing: trailing != null
            ? Text(trailing!,
            style: AppTextStyles.caption)
            : Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}