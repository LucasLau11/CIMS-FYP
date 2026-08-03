import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../photo_crop_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _isLoadingProfile = true;
  bool _isEditingContactInfo = false;
  bool _isSavingContactInfo = false;

  String _email = '';
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _originalName = '';
  String _originalPhone = '';

  File? _localPreviewImage;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  static const List<String> _allowedImageExtensions = ['.jpg', '.jpeg', '.png'];

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
      setState(() {
        _email = profile?['email'] as String? ?? '';
        _nameController.text = profile?['full_name'] as String? ?? '';
        _phoneController.text = profile?['phone'] as String? ?? '';
        _originalName = _nameController.text;
        _originalPhone = _phoneController.text;
        _avatarUrl = profile?['avatar_url'] as String?;
        _isLoadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _saveContactInfo() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminFullNameCannotBeBlank), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isSavingContactInfo = true);
    try {
      await AuthService.instance.updateContactInfo(
        fullName: _nameController.text,
        phone: _phoneController.text,
      );
      if (!mounted) return;
      setState(() {
        _originalName = _nameController.text;
        _originalPhone = _phoneController.text;
        _isEditingContactInfo = false;
        _isSavingContactInfo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUpdated), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingContactInfo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminCouldNotSave(e.toString())), backgroundColor: AppColors.error),
      );
    }
  }

  void _cancelEditingContactInfo() {
    setState(() {
      _nameController.text = _originalName;
      _phoneController.text = _originalPhone;
      _isEditingContactInfo = false;
    });
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 800);
      if (picked == null) return;

      final lowerPath = picked.path.toLowerCase();
      if (!_allowedImageExtensions.any((ext) => lowerPath.endsWith(ext))) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminUnsupportedFileFormat), backgroundColor: AppColors.error),
        );
        return;
      }

      final file = File(picked.path);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      if (!exists || size == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exists ? l10n.adminPhotoEmptyError : l10n.adminPhotoNotFoundError), backgroundColor: AppColors.error),
        );
        return;
      }

      if (!mounted) return;
      final croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(builder: (_) => PhotoCropScreen(imageFile: file)),
      );
      if (croppedFile == null) return;

      setState(() {
        _localPreviewImage = croppedFile;
        _isUploadingAvatar = true;
      });

      try {
        final uploadedUrl = await AuthService.instance.uploadAvatar(croppedFile);
        if (!mounted) return;
        setState(() {
          _avatarUrl = uploadedUrl;
          _localPreviewImage = null;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profilePhotoUpdated), backgroundColor: AppColors.primary),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _localPreviewImage = null;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminUploadFailed(e.toString())), backgroundColor: AppColors.error));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminCouldNotAccessSource(source == ImageSource.camera ? l10n.adminSourceCamera : l10n.adminSourceGallery, e.toString()))));
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adminCouldNotRemovePhoto(e.toString())), backgroundColor: AppColors.error));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingProfile) {
      return Scaffold(backgroundColor: AppColors.background, body: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: l10n.profileMyProfile),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D6E78), Color(0xFF14B8C8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isUploadingAvatar ? null : _showPhotoOptions,
                  child: Stack(
                    children: [
                      ClipOval(
                        child: Container(
                          width: 48,
                          height: 48,
                          color: Colors.white24,
                          child: Builder(builder: (context) {
                            const fallback = Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 26);
                            if (_localPreviewImage != null) {
                              return Image.file(_localPreviewImage!, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
                            }
                            if (_avatarUrl != null) {
                              return Image.network(_avatarUrl!, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
                            }
                            return fallback;
                          }),
                        ),
                      ),
                      if (_isUploadingAvatar)
                        Positioned.fill(
                          child: ClipOval(
                            child: Container(
                              color: Colors.black38,
                              child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                            ),
                          ),
                        ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_nameController.text.isEmpty ? l10n.notSet : _nameController.text,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text(_email, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
          _isEditingContactInfo ? _buildEditForm() : _buildView(),
        ],
      ),
    );
  }

  Widget _buildView() {
    final l10n = AppLocalizations.of(context)!;
    return _AdminInfoSection(
      items: [
        _AdminInfoItem(icon: Icons.person_outline, label: l10n.fullName, value: _nameController.text.isEmpty ? l10n.notSet : _nameController.text),
        _AdminInfoItem(icon: Icons.email_outlined, label: l10n.email, value: _email),
        _AdminInfoItem(icon: Icons.phone_outlined, label: l10n.phone, value: _phoneController.text.isEmpty ? l10n.notSet : _phoneController.text),
      ],
    );
  }

  Widget _buildEditForm() {
    final l10n = AppLocalizations.of(context)!;
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _isSavingContactInfo ? null : _cancelEditingContactInfo, child: Text(l10n.cancel))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSavingContactInfo ? null : _saveContactInfo,
                  child: _isSavingContactInfo
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminInfoSection extends StatelessWidget {
  final List<_AdminInfoItem> items;
  const _AdminInfoSection({required this.items});

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

class _AdminInfoItem {
  final IconData icon;
  final String label;
  final String value;
  _AdminInfoItem({required this.icon, required this.label, required this.value});
}
