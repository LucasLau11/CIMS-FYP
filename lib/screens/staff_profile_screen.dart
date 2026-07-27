import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/common/shared_widgets.dart';
import '../services/auth_service.dart';
import 'student/address_picker_screen.dart';
import 'login_screen.dart';

/// Full profile screen shared by HR, Company Supervisor, and Academic
/// Supervisor — mirrors the student profile's personal-info/security/
/// preferences sections, minus the academic-specific fields (programme,
/// resume, etc.) that don't apply to staff roles.
class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  bool _isLoadingProfile = true;

  // Avatar
  File? _localPreviewImage;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  static const List<String> _allowedImageExtensions = ['.jpg', '.jpeg', '.png'];

  // Contact info
  bool _isEditingContactInfo = false;
  bool _isSavingContactInfo = false;
  String _email = '';
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _addressText;
  double? _addressLat;
  double? _addressLng;

  String _originalName = '';
  String _originalPhone = '';
  String? _originalAddressText;
  double? _originalAddressLat;
  double? _originalAddressLng;

  bool _isChangingPassword = false;

  String _selectedLanguage = 'English';
  String _selectedThemeCode = 'system';
  final Map<String, bool> _notificationPrefs = {
    'application_updates': true,
    'report_deadlines': true,
    'messages': true,
    'supervisor_feedback': false,
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.instance.getCurrentProfile();
      if (!mounted) return;
      final resolvedAvatarUrl = await AuthService.instance.resolveAvatarPath(profile?['avatar_url'] as String?);
      if (!mounted) return;

      final rawPrefs = profile?['notification_prefs'] as Map<String, dynamic>?;
      if (rawPrefs != null) {
        for (final dbKey in _notificationPrefs.keys.toList()) {
          if (rawPrefs.containsKey(dbKey)) _notificationPrefs[dbKey] = rawPrefs[dbKey] as bool;
        }
      }

      setState(() {
        _avatarUrl = resolvedAvatarUrl;
        _email = profile?['email'] as String? ?? '';
        _nameController.text = profile?['full_name'] as String? ?? '';
        _phoneController.text = profile?['phone'] as String? ?? '';
        _addressText = profile?['address_text'] as String?;
        _addressLat = (profile?['address_lat'] as num?)?.toDouble();
        _addressLng = (profile?['address_lng'] as num?)?.toDouble();
        _selectedLanguage = profile?['language'] as String? ?? 'English';
        _selectedThemeCode = profile?['theme_mode'] as String? ?? 'system';

        _originalName = _nameController.text;
        _originalPhone = _phoneController.text;
        _originalAddressText = _addressText;
        _originalAddressLat = _addressLat;
        _originalAddressLng = _addressLng;

        _isLoadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
    }
  }

  // =====================================================================
  // AVATAR
  // =====================================================================

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
        await FileImage(File(uploadedUrl)).evict();
        if (!mounted) return;
        setState(() {
          _avatarUrl = uploadedUrl;
          _localPreviewImage = null;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.profilePhotoUpdated), backgroundColor: AppColors.primary));
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
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(alignment: Alignment.centerLeft, child: Text(l10n.profileUpdatePhoto, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700))),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: Text(l10n.profileTakePhoto),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text(l10n.profileChooseFromGallery),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            if (_avatarUrl != null || _localPreviewImage != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(l10n.profileRemovePhoto, style: TextStyle(color: AppColors.error)),
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

  // =====================================================================
  // CONTACT INFO
  // =====================================================================

  Future<void> _pickAddress() async {
    final result = await Navigator.push<PickedAddress>(
      context,
      MaterialPageRoute(builder: (_) => AddressPickerScreen(initialLat: _addressLat, initialLng: _addressLng)),
    );
    if (result != null) {
      setState(() {
        _addressText = result.addressText;
        _addressLat = result.lat;
        _addressLng = result.lng;
      });
    }
  }

  Future<void> _saveContactInfo() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Full name cannot be blank.'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _isSavingContactInfo = true);
    try {
      await AuthService.instance.updateContactInfo(
        fullName: _nameController.text,
        phone: _phoneController.text,
        addressText: _addressText,
        addressLat: _addressLat,
        addressLng: _addressLng,
      );
      if (!mounted) return;
      setState(() {
        _originalName = _nameController.text;
        _originalPhone = _phoneController.text;
        _originalAddressText = _addressText;
        _originalAddressLat = _addressLat;
        _originalAddressLng = _addressLng;
        _isEditingContactInfo = false;
        _isSavingContactInfo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated), backgroundColor: AppColors.primary));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingContactInfo = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error));
    }
  }

  void _cancelEditingContactInfo() {
    setState(() {
      _nameController.text = _originalName;
      _phoneController.text = _originalPhone;
      _addressText = _originalAddressText;
      _addressLat = _originalAddressLat;
      _addressLng = _originalAddressLng;
      _isEditingContactInfo = false;
    });
  }

  // =====================================================================
  // CHANGE PASSWORD
  // =====================================================================

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
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profilePasswordChanged), backgroundColor: AppColors.primary));
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

  // =====================================================================
  // PREFERENCES
  // =====================================================================

  void _showNotificationPreferences() {
    final l10n = AppLocalizations.of(context)!;
    final labels = <String, String>{
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
                    Text(l10n.profileNotificationPreferencesTitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
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
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileNotificationPrefsUpdated), backgroundColor: AppColors.primary));
                          } catch (e) {
                            if (!sheetContext.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error));
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save language: $e'), backgroundColor: AppColors.error));
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

  void _showThemePicker() {
    final l10n = AppLocalizations.of(context)!;
    final options = <String, String>{
      'light': l10n.themeLight,
      'dark': l10n.themeDark,
      'system': l10n.themeSystem,
    };
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
                      SnackBar(content: Text('Could not save theme: $e'), backgroundColor: AppColors.error),
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

  String _themeLabel(AppLocalizations l10n) {
    switch (_selectedThemeCode) {
      case 'light':
        return l10n.themeLight;
      case 'dark':
        return l10n.themeDark;
      default:
        return l10n.themeSystem;
    }
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logOutConfirmTitle, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(l10n.logOutConfirmMessage, style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
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

  // =====================================================================
  // BUILD
  // =====================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(backgroundColor: AppColors.background, body: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight)),
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
                            child: Builder(builder: (context) {
                              const initials = Center(child: Text('👤', style: TextStyle(fontSize: 32)));
                              if (_localPreviewImage != null) {
                                return Image.file(_localPreviewImage!, width: 88, height: 88, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => initials);
                              }
                              if (_avatarUrl != null) {
                                return Image.file(File(_avatarUrl!), width: 88, height: 88, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => initials);
                              }
                              return initials;
                            }),
                          ),
                        ),
                        if (_isUploadingAvatar)
                          Positioned.fill(
                            child: ClipOval(
                              child: Container(
                                color: Colors.black38,
                                child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _isUploadingAvatar ? null : _showPhotoOptions,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 14, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(_nameController.text.isEmpty ? l10n.notSet : _nameController.text,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(_email, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SectionHeader(
                  title: l10n.personalInformation,
                  actionIcon: _isEditingContactInfo ? Icons.close : Icons.edit_outlined,
                  onAction: () {
                    if (_isEditingContactInfo) {
                      _cancelEditingContactInfo();
                    } else {
                      setState(() => _isEditingContactInfo = true);
                    }
                  },
                ),
                _isEditingContactInfo ? _buildContactInfoEditForm(l10n) : _buildContactInfoView(l10n),

                SectionHeader(title: l10n.account),
                _SettingsTile(icon: Icons.lock_outline, label: l10n.changePassword, onTap: _showChangePasswordDialog),
                _SettingsTile(icon: Icons.notifications_outlined, label: l10n.notificationPreferences, onTap: _showNotificationPreferences),
                _SettingsTile(icon: Icons.language_outlined, label: l10n.language, trailing: _selectedLanguage, onTap: _showLanguagePicker),
                _SettingsTile(icon: Icons.dark_mode_outlined, label: l10n.theme, trailing: _themeLabel(l10n), onTap: _showThemePicker),
                _SettingsTile(icon: Icons.logout, label: l10n.logOut, isDestructive: true, onTap: _handleLogout),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoView(AppLocalizations l10n) {
    return _InfoSection(
      items: [
        _InfoItem(icon: Icons.person_outline, label: l10n.fullName, value: _nameController.text.isEmpty ? l10n.notSet : _nameController.text),
        _InfoItem(icon: Icons.email_outlined, label: l10n.email, value: _email),
        _InfoItem(icon: Icons.phone_outlined, label: l10n.phone, value: _phoneController.text.isEmpty ? l10n.notSet : _phoneController.text),
        _InfoItem(icon: Icons.location_on_outlined, label: l10n.address, value: _addressText ?? l10n.notSet),
      ],
    );
  }

  Widget _buildContactInfoEditForm(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.fullName, style: AppTextStyles.label),
          const SizedBox(height: 6),
          TextField(controller: _nameController, decoration: const InputDecoration()),
          const SizedBox(height: 14),
          Text(l10n.email, style: AppTextStyles.label),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: Text(_email, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textMuted)),
          ),
          const SizedBox(height: 14),
          Text(l10n.phone, style: AppTextStyles.label),
          const SizedBox(height: 6),
          TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: l10n.profilePhoneHint)),
          const SizedBox(height: 14),
          Text(l10n.address, style: AppTextStyles.label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickAddress,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_addressText ?? l10n.profileTapToSelectOnMap, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: _addressText != null ? AppColors.textPrimary : AppColors.textMuted)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _isSavingContactInfo ? null : _cancelEditingContactInfo, child: Text(l10n.cancel))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSavingContactInfo ? null : _saveContactInfo,
                  child: _isSavingContactInfo ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(l10n.save),
                ),
              ),
            ],
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
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        children: List.generate(items.length, (i) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(items[i].icon, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].label, style: AppTextStyles.caption),
                          const SizedBox(height: 2),
                          Text(items[i].value, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1) const Divider(height: 1, indent: 44),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({required this.icon, required this.label, required this.value});
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, this.trailing, this.isDestructive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 20, color: isDestructive ? AppColors.error : AppColors.textMuted),
        title: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: isDestructive ? AppColors.error : AppColors.textPrimary)),
        trailing: trailing != null
            ? Text(trailing!, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textMuted))
            : (isDestructive ? null : Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted)),
      ),
    );
  }
}
