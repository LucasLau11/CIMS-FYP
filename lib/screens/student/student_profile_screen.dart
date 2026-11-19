import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geocoding/geocoding.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/account_actions.dart';
import '../../widgets/common/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/student_data_service.dart';
import '../../services/resume_parser_service.dart';
import '../../utils/file_picker_utils.dart';
import '../../utils/format_utils.dart';
import '../../utils/validators.dart';
import '../../widgets/common/validated_field.dart';
import '../document_preview_screen.dart';
import '../login_screen.dart';
import '../photo_crop_screen.dart';
import 'address_picker_screen.dart';
import '../../utils/error_text.dart';
import '../../utils/responsive.dart';
import '../../utils/lang.dart';
import '../../widgets/profile_actions.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  // ---- Avatar state ----
  File? _localPreviewImage;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;

  // ---- Loading ----
  bool _isLoadingProfile = true;

  // ---- Personal info state ----
  bool _isEditingPersonalInfo = false;
  bool _isSavingPersonalInfo = false;
  String _email = '';
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _personalFormKey = GlobalKey<FormState>();
  final _academicFormKey = GlobalKey<FormState>();
  final _skillFieldKey = GlobalKey<FormFieldState<String>>();
  bool _personalAttempted = false;
  DateTime? _dateOfBirth;
  String? _addressText;
  double? _addressLat;
  double? _addressLng;

  // Snapshots to revert to if the user cancels editing.
  String _originalName = '';
  String _originalPhone = '';
  DateTime? _originalDob;
  String? _originalAddressText;
  double? _originalAddressLat;
  double? _originalAddressLng;

  // ---- Academic info state ----
  bool _isEditingAcademicInfo = false;
  bool _isSavingAcademicInfo = false;
  String? _programme;
  int? _semester;
  String? _faculty;
  final _cgpaController = TextEditingController();
  final _academicSupervisorController = TextEditingController();
  String? _academicSupervisorId;
  final _studentRegNoController = TextEditingController();
  // Optional, kept apart from the student record; letters (indemnity, company acceptance) fill it in from here.
  final _icController = TextEditingController();
  String _originalIc = '';

  String? _originalProgramme;
  int? _originalSemester;
  String? _originalFaculty;
  String _originalCgpaText = '';
  String _originalStudentRegNo = '';

  static const List<String> _programmeOptions = [
    'Bachelor of Computer Science (Hons)',
    'Bachelor of Information Technology (Hons)',
    'Bachelor of Software Engineering (Hons)',
    'Diploma in Computer Science',
    'Diploma in Information Technology',
  ];

  static const List<String> _facultyOptions = [
    'Faculty of Computing and Information Technology',
    'Faculty of Engineering and Technology',
    'Faculty of Business and Finance',
    'Faculty of Applied Sciences',
  ];

  // ---- Skills state ----
  bool _isEditingSkills = false;
  bool _isSavingSkills = false;
  List<String> _skills = [];
  List<String> _originalSkills = [];
  final _skillInputController = TextEditingController();

  // ---- Work experience state ----
  bool _isLoadingWorkExperience = true;
  List<Map<String, dynamic>> _workExperience = [];
  // Entries found in the most recent resume scan, awaiting per-entry
  // confirmation before they're written to the database (same "nothing
  // saved automatically" contract as every other extracted field).
  List<ParsedWorkExperience> _suggestedWorkExperience = [];

  // ---- Change password state ----

  // ---- Resume state ----
  String? _resumeFilename;
  int? _resumeSizeBytes;
  DateTime? _resumeUploadedAt;
  String? _resumePath;
  bool _isUploadingResume = false;

  // ---- Preferences state (persisted) ----
  String _selectedLanguage = 'English';
  String _selectedThemeCode = 'system';
  final Map<String, bool> _notificationPrefs = {
    'Application updates': true,
    'Report deadlines': true,
    'Messages': true,
    'Supervisor feedback': false,
  };

  static const Map<String, String> _prefDbKeys = {
    'Application updates': 'application_updates',
    'Report deadlines': 'report_deadlines',
    'Messages': 'messages',
    'Supervisor feedback': 'supervisor_feedback',
  };

  static const List<String> _allowedImageExtensions = ['.jpg', '.jpeg', '.png'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadWorkExperience();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cgpaController.dispose();
    _academicSupervisorController.dispose();
    _studentRegNoController.dispose();
    _icController.dispose();
    _skillInputController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkExperience() async {
    try {
      final rows = await StudentDataService.instance.getWorkExperience();
      if (!mounted) return;
      setState(() {
        _workExperience = rows;
        _isLoadingWorkExperience = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingWorkExperience = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.instance.getCurrentProfile();
      if (!mounted) return;

      final resolvedAvatarUrl = profile?['avatar_url'] as String?;
      if (!mounted) return;

      final dobRaw = profile?['date_of_birth'] as String?;
      final dob = dobRaw != null ? DateTime.tryParse(dobRaw) : null;

      final rawPrefs = profile?['notification_prefs'] as Map<String, dynamic>?;
      if (rawPrefs != null) {
        _prefDbKeys.forEach((label, dbKey) {
          if (rawPrefs.containsKey(dbKey)) {
            _notificationPrefs[label] = rawPrefs[dbKey] as bool;
          }
        });
      }

      String? ic;
      try {
        ic = await StudentDataService.instance.getMyIcNumber();
      } catch (_) {
        // Non-fatal: the IC number simply shows as not set.
      }
      if (!mounted) return;
      setState(() {
        _avatarUrl = resolvedAvatarUrl;
        _email = profile?['email'] as String? ?? '';
        _nameController.text = profile?['full_name'] as String? ?? '';
        _phoneController.text = profile?['phone'] as String? ?? '';
        _dateOfBirth = dob;
        _addressText = profile?['address_text'] as String?;
        _addressLat = (profile?['address_lat'] as num?)?.toDouble();
        _addressLng = (profile?['address_lng'] as num?)?.toDouble();
        _selectedLanguage = profile?['language'] as String? ?? 'English';
        _selectedThemeCode = profile?['theme_mode'] as String? ?? 'system';

        _resumeFilename = profile?['resume_filename'] as String?;
        _resumeSizeBytes = parseNum(profile?['resume_size_bytes'])?.toInt();
        final resumeUploadedRaw = profile?['resume_uploaded_at'] as String?;
        _resumeUploadedAt = resumeUploadedRaw != null ? DateTime.tryParse(resumeUploadedRaw) : null;
        _resumePath = profile?['resume_path'] as String?;

        _originalName = _nameController.text;
        _originalPhone = _phoneController.text;
        _originalDob = _dateOfBirth;
        _originalAddressText = _addressText;
        _originalAddressLat = _addressLat;
        _originalAddressLng = _addressLng;

        _programme = profile?['programme'] as String?;
        _semester = (profile?['semester'] as num?)?.toInt();
        _faculty = profile?['faculty'] as String?;
        final cgpaVal = parseNum(profile?['cgpa'])?.toDouble();
        _cgpaController.text = cgpaVal != null ? cgpaVal.toStringAsFixed(2) : '';
        _academicSupervisorController.text = profile?['academic_supervisor_name'] as String? ?? '';
        _academicSupervisorId = profile?['academic_supervisor_id'] as String?;
        _studentRegNoController.text = profile?['student_reg_no'] as String? ?? '';

        _originalProgramme = _programme;
        _originalSemester = _semester;
        _originalFaculty = _faculty;
        _originalCgpaText = _cgpaController.text;
        _originalStudentRegNo = _studentRegNoController.text;
        _icController.text = ic ?? '';
        _originalIc = _icController.text;

        _skills = List<String>.from(profile?['skills'] as List? ?? []);
        _originalSkills = List<String>.from(_skills);

        _isLoadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
    }
  }

  // =====================================================================
  // AVATAR
  // =====================================================================

  Future<void> _pickProfileImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 800);
      if (picked == null) return;

      final lowerPath = picked.path.toLowerCase();
      if (!_allowedImageExtensions.any((ext) => lowerPath.endsWith(ext))) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorUnsupportedImageFormat),
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
                ? l10n.errorPhotoEmpty
                : l10n.errorPhotoNotFound),
            backgroundColor: AppColors.error,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorUploadFailed(friendlyError(e))), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final sourceLabel = source == ImageSource.camera ? 'camera' : 'gallery';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorCouldNotAccessSource(sourceLabel, friendlyError(e)))),
      );
    }
  }

  Future<void> _removePhoto() async {
    final l10n = AppLocalizations.of(context)!;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorCouldNotRemovePhoto(friendlyError(e))), backgroundColor: AppColors.error),
      );
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.profileUpdatePhoto,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: AppColors.primaryText),
              title: Text(l10n.profileTakePhoto),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.primaryText),
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
  // PERSONAL INFO EDITING
  // =====================================================================

  Future<void> _pickDateOfBirth() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final maxDob = DateTime(now.year - 17, now.month, now.day); // must be 17+
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 100),
      lastDate: maxDob,
      helpText: l10n.selectDateOfBirthHelpText,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _pickAddress() async {
    final result = await Navigator.push<PickedAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressPickerScreen(initialLat: _addressLat, initialLng: _addressLng),
      ),
    );
    if (result != null) {
      setState(() {
        _addressText = result.addressText;
        _addressLat = result.lat;
        _addressLng = result.lng;
      });
    }
  }

  /// Runs every personal-info rule at once (the text fields show their own
  /// message under the field; the date of birth and address show theirs too).
  /// Returns a summary only when something needs fixing.
  String? _validatePersonalInfo() {
    setState(() => _personalAttempted = true);
    final fieldsOk = _personalFormKey.currentState?.validate() ?? false;
    final dobError = Validators.dateOfBirth(_dateOfBirth, minAge: 17);
    final addressMissing = _addressText == null || _addressText!.trim().isEmpty;
    if (!fieldsOk || dobError != null || addressMissing) {
      return tt('Please fix the highlighted fields.');
    }
    return null;
  }

  Future<void> _savePersonalInfo() async {
    final l10n = AppLocalizations.of(context)!;
    final error = _validatePersonalInfo();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSavingPersonalInfo = true);
    try {
      await AuthService.instance.updatePersonalInfo(
        fullName: _nameController.text,
        phone: _phoneController.text,
        dateOfBirth: _dateOfBirth!,
        addressText: _addressText!,
        addressLat: _addressLat!,
        addressLng: _addressLng!,
      );
      if (!mounted) return;
      setState(() {
        _originalName = _nameController.text;
        _originalPhone = _phoneController.text;
        _originalDob = _dateOfBirth;
        _originalAddressText = _addressText;
        _originalAddressLat = _addressLat;
        _originalAddressLng = _addressLng;
        _isEditingPersonalInfo = false;
        _isSavingPersonalInfo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.personalInfoUpdated), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingPersonalInfo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorCouldNotSave(friendlyError(e))), backgroundColor: AppColors.error),
      );
    }
  }

  void _cancelEditingPersonalInfo() {
    setState(() {
      _nameController.text = _originalName;
      _phoneController.text = _originalPhone;
      _dateOfBirth = _originalDob;
      _addressText = _originalAddressText;
      _addressLat = _originalAddressLat;
      _addressLng = _originalAddressLng;
      _isEditingPersonalInfo = false;
    });
  }

  // =====================================================================
  // ACADEMIC INFO EDITING
  // =====================================================================

  String? _validateAcademicInfo() {
    final ok = _academicFormKey.currentState?.validate() ?? false;
    return ok ? null : tt('Please fix the highlighted fields.');
  }

  Future<void> _saveAcademicInfo() async {
    final l10n = AppLocalizations.of(context)!;
    final error = _validateAcademicInfo();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSavingAcademicInfo = true);
    try {
      await AuthService.instance.updateAcademicInfo(
        programme: _programme!,
        semester: _semester!,
        faculty: _faculty!,
        cgpa: double.parse(_cgpaController.text.trim()),
        studentRegNo: _studentRegNoController.text,
      );
      final icNormalized = _icController.text.trim().isEmpty ? null : Validators.normalizeIc(_icController.text);
      await StudentDataService.instance.saveMyIcNumber(icNormalized);
      _icController.text = icNormalized ?? '';
      if (!mounted) return;
      setState(() {
        _originalProgramme = _programme;
        _originalSemester = _semester;
        _originalFaculty = _faculty;
        _originalCgpaText = _cgpaController.text;
        _originalStudentRegNo = _studentRegNoController.text;
        _originalIc = _icController.text;
        _isEditingAcademicInfo = false;
        _isSavingAcademicInfo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.academicInfoUpdated), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingAcademicInfo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorCouldNotSave(friendlyError(e))), backgroundColor: AppColors.error),
      );
    }
  }

  void _cancelEditingAcademicInfo() {
    setState(() {
      _programme = _originalProgramme;
      _semester = _originalSemester;
      _faculty = _originalFaculty;
      _cgpaController.text = _originalCgpaText;
      _studentRegNoController.text = _originalStudentRegNo;
      _icController.text = _originalIc;
      _isEditingAcademicInfo = false;
    });
  }

  // =====================================================================
  // SKILLS
  // =====================================================================

  void _addSkill(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    // The field shows the reason (too short, duplicate, odd characters, limit).
    if (Validators.skill(trimmed, existing: _skills) != null) {
      _skillFieldKey.currentState?.validate();
      return;
    }
    setState(() {
      _skills.add(trimmed);
      _skillInputController.clear();
    });
  }

  void _removeSkill(String skill) => setState(() => _skills.remove(skill));

  Future<void> _saveSkills() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSavingSkills = true);
    try {
      await AuthService.instance.updateSkills(_skills);
      if (!mounted) return;
      setState(() {
        _originalSkills = List<String>.from(_skills);
        _isEditingSkills = false;
        _isSavingSkills = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.skillsUpdated), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingSkills = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorCouldNotSave(friendlyError(e))), backgroundColor: AppColors.error),
      );
    }
  }

  void _cancelEditingSkills() {
    setState(() {
      _skills = List<String>.from(_originalSkills);
      _isEditingSkills = false;
    });
  }

  // =====================================================================
  // WORK EXPERIENCE
  // =====================================================================

  Future<void> _showWorkExperienceDialog({Map<String, dynamic>? existing}) async {
    final companyController = TextEditingController(text: existing?['company_name'] as String? ?? '');
    final positionController = TextEditingController(text: existing?['position'] as String? ?? '');
    final descriptionController = TextEditingController(text: existing?['description'] as String? ?? '');
    final startYearController = TextEditingController(text: existing?['start_year']?.toString() ?? '');
    final endYearController = TextEditingController(text: existing?['end_year']?.toString() ?? '');
    bool isCurrent = existing?['is_current'] as bool? ?? false;
    final formKey = GlobalKey<FormState>();
    String? error;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(existing == null ? l10n.addWorkExperience : l10n.editWorkExperience,
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValidatedField(
                      controller: positionController,
                      fieldValidator: (v) => Validators.text(v, field: 'Position', min: 2, max: 100),
                      labelText: l10n.positionJobTitleLabel,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    ValidatedField(
                      controller: companyController,
                      fieldValidator: (v) => Validators.text(v, field: 'Company name', min: 2, max: 100),
                      labelText: l10n.setupCompanyName,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ValidatedField(
                            controller: startYearController,
                            fieldValidator: (v) => Validators.year(v, field: 'Start year', today: DateTime.now()),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 4,
                            showSuccess: false,
                            labelText: l10n.startYearLabel,
                            hintText: l10n.startYearHint,
                            onChanged: (_) {
                              if (endYearController.text.isNotEmpty) formKey.currentState?.validate();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ValidatedField(
                            controller: endYearController,
                            enabled: !isCurrent,
                            fieldValidator: (v) {
                              if (isCurrent) return null;
                              final yearError = Validators.year(v, field: 'End year');
                              if (yearError != null) return yearError;
                              final start = int.tryParse(startYearController.text.trim());
                              if (start != null && int.parse(v.trim()) < start) {
                                return 'End year cannot be before the start year ($start).';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 4,
                            showSuccess: false,
                            labelText: l10n.endYearLabel,
                          ),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: isCurrent,
                      title: Text(l10n.iCurrentlyWorkHere, style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
                      activeColor: AppColors.primary,
                      onChanged: (v) {
                        setDialogState(() => isCurrent = v ?? false);
                        if (isCurrent) endYearController.clear();
                        formKey.currentState?.validate();
                      },
                    ),
                    ValidatedField(
                      controller: descriptionController,
                      fieldValidator: (v) => Validators.text(v, field: 'Description', required: false, max: 500),
                      maxLines: 3,
                      maxLength: 500,
                      showSuccess: false,
                      labelText: l10n.descriptionOptionalLabel,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(error!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
                    ],
                  ],
                ),
                ),
              ),
              actions: [
                TextButton(onPressed: isSaving ? null : () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          setDialogState(() {
                            error = null;
                            isSaving = true;
                          });
                          try {
                            final startYear = int.tryParse(startYearController.text.trim());
                            final endYear = int.tryParse(endYearController.text.trim());
                            if (existing == null) {
                              await StudentDataService.instance.addWorkExperience(
                                companyName: companyController.text,
                                position: positionController.text,
                                description: descriptionController.text,
                                startYear: startYear,
                                endYear: endYear,
                                isCurrent: isCurrent,
                              );
                            } else {
                              await StudentDataService.instance.updateWorkExperience(
                                id: existing['id'] as String,
                                companyName: companyController.text,
                                position: positionController.text,
                                description: descriptionController.text,
                                startYear: startYear,
                                endYear: endYear,
                                isCurrent: isCurrent,
                              );
                            }
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            _loadWorkExperience();
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              error = l10n.errorCouldNotSave(friendlyError(e));
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteWorkExperience(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.removeThisEntryTitle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.remove, style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await StudentDataService.instance.deleteWorkExperience(id);
      _loadWorkExperience();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorCouldNotRemove(friendlyError(e))), backgroundColor: AppColors.error));
    }
  }

  Future<void> _acceptSuggestedWorkExperience(ParsedWorkExperience entry) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await StudentDataService.instance.addWorkExperience(
        companyName: entry.companyName ?? l10n.unknownCompany,
        position: entry.position ?? l10n.unknownPosition,
        description: entry.description,
        startYear: entry.startYear,
        endYear: entry.endYear,
        isCurrent: entry.isCurrent,
      );
      if (!mounted) return;
      setState(() => _suggestedWorkExperience.remove(entry));
      _loadWorkExperience();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tt('Could not add')}: ${friendlyError(e)}'), backgroundColor: AppColors.error));
    }
  }

  // =====================================================================
  // CHANGE PASSWORD
  // =====================================================================

  void _showChangePasswordDialog() => showChangePasswordDialog(context);

  // =====================================================================
  // RESUME
  // =====================================================================

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickAndUploadResume() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final File file;
    try {
      file = await resolvePickedFile(picked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${friendlyError(e)}'), backgroundColor: AppColors.error),
      );
      return;
    }

    final ext = (picked.extension ?? '').toLowerCase();
    if (!AuthService.allowedResumeExtensions.contains(ext)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorInvalidResumeFormat),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (picked.size > AuthService.maxResumeSizeBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorFileTooLarge5mb),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isUploadingResume = true);
    try {
      await AuthService.instance.uploadResume(
        file: file,
        originalFilename: picked.name,
        sizeBytes: picked.size,
      );
      if (!mounted) return;
      setState(() {
        _resumeFilename = picked.name;
        _resumeSizeBytes = picked.size;
        _resumeUploadedAt = DateTime.now();
        _resumePath = '${AuthService.instance.currentUserId}/resume.$ext';
        _isUploadingResume = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resumeUploaded), backgroundColor: AppColors.primary),
      );

      // Offer to scan the resume for autofill (problem 6 — regex-based,
      // no AI/network calls). Uses the local file we already have in hand.
      _offerResumeScan(file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingResume = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorUploadFailed(friendlyError(e))), backgroundColor: AppColors.error),
      );
    }
  }

  String? _bestMatch(String extracted, List<String> options) {
    final lower = extracted.toLowerCase();
    for (final option in options) {
      if (option.toLowerCase().contains(lower) || lower.contains(option.toLowerCase())) {
        return option;
      }
    }
    // Try matching on individual significant words (e.g. "computer science").
    for (final option in options) {
      final optionWords = option.toLowerCase().split(RegExp(r'[\s()]+')).where((w) => w.length > 3);
      if (optionWords.any((w) => lower.contains(w))) return option;
    }
    return null;
  }

  /// Dev-only access point (long-press the "Resume" section header) for
  /// updating the NLP service's ngrok URL after a tunnel restart — no
  /// rebuild/reinstall needed, see ResumeParserService.setNlpServiceUrl.
  Future<void> _showNlpServiceUrlEditor() async {
    final controller = TextEditingController(text: await ResumeParserService.instance.getNlpServiceUrl());
    if (!mounted) return;
    final newUrl = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('NLP service URL', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update this after restarting the ngrok tunnel — the URL it prints changes every time.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(controller: controller, decoration: const InputDecoration(hintText: 'https://...ngrok-free.dev')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(tt('Cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: Text(tt('Save'))),
        ],
      ),
    );
    if (newUrl == null || newUrl.trim().isEmpty || !mounted) return;
    await ResumeParserService.instance.setNlpServiceUrl(newUrl);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('NLP service URL updated.'), backgroundColor: AppColors.primary));
  }

  Future<void> _offerResumeScan(File file) async {
    final l10n = AppLocalizations.of(context)!;
    ParsedResumeData data;
    try {
      final text = await ResumeParserService.instance.extractText(file);
      try {
        data = await ResumeParserService.instance.parseViaNlp(text);
      } catch (_) {
        // NLP service unreachable (offline, tunnel restarted, timed out,
        // etc.) — silently fall back to the local regex-only parser rather
        // than losing the autofill feature entirely.
        data = await ResumeParserService.instance.parseOnDevice(text);
      }
    } catch (e) {
      // Non-fatal — scanning is a bonus feature, upload already succeeded.
      return;
    }

    if (!data.foundAnything || !mounted) return;

    final foundLines = <String>[
      if (data.fullName != null) '• Name: ${data.fullName}',
      if (data.phone != null) '• Phone: ${data.phone}',
      if (data.address != null) '• Address: ${data.address}',
      if (data.dateOfBirth != null) '• Date of birth: ${_formatDate(data.dateOfBirth!)}',
      if (data.programme != null) '• Programme: ${data.programme}',
      if (data.faculty != null) '• Faculty: ${data.faculty}',
      if (data.semester != null) '• Semester: ${data.semester}',
      if (data.cgpa != null) '• CGPA: ${data.cgpa!.toStringAsFixed(2)}',
      if (data.skills.isNotEmpty) '• Skills: ${data.skills.join(', ')}',
      if (data.workExperience.isNotEmpty) '• Work experience: ${data.workExperience.length} entr${data.workExperience.length == 1 ? 'y' : 'ies'} found',
    ];

    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.autofillFromResumeTitle,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.resumeScanFoundDetailsNote,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Text(foundLines.join('\n'),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
              // Where the skills came from, so it is visible when the on-device model did the work.
              if (data.source == 'regex+model') ...[
                const SizedBox(height: 8),
                Text(
                  tr('The skills were found by the on-device AI model (TensorFlow Lite), because this resume has no skills list.',
                      ms: 'Kemahiran ditemui oleh model AI dalam peranti (TensorFlow Lite), kerana resume ini tiada senarai kemahiran.',
                      zh: '由于这份简历没有技能列表，技能由设备上的 AI 模型（TensorFlow Lite）找出。'),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                data.source == 'nlp' ? l10n.parsedWithAi : l10n.parsedOffline,
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.discard)),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.reviewAndApply)),
        ],
      ),
    );

    if (apply != true || !mounted) return;

    if (data.fullName != null) _nameController.text = data.fullName!;
    if (data.phone != null) _phoneController.text = data.phone!;
    if (data.dateOfBirth != null) _dateOfBirth = data.dateOfBirth;

    if (data.address != null) {
      // Best-effort forward geocoding so the extracted address text has
      // matching coordinates (required since address is stored as both
      // text + lat/lng). If this fails, the user can still pick the
      // address manually via the map before saving.
      try {
        final locations = await locationFromAddress(data.address!);
        if (locations.isNotEmpty) {
          _addressText = data.address;
          _addressLat = locations.first.latitude;
          _addressLng = locations.first.longitude;
        }
      } catch (_) {
        // Leave address unset — user can pick it manually via the map.
      }
    }

    if (data.programme != null) _programme = _bestMatch(data.programme!, _programmeOptions);
    if (data.faculty != null) _faculty = _bestMatch(data.faculty!, _facultyOptions);
    if (data.semester != null) _semester = data.semester;
    if (data.cgpa != null) _cgpaController.text = data.cgpa!.toStringAsFixed(2);

    if (data.skills.isNotEmpty) {
      for (final skill in data.skills) {
        if (!_skills.any((s) => s.toLowerCase() == skill.toLowerCase())) _skills.add(skill);
      }
    }

    setState(() {
      _isEditingPersonalInfo = true;
      _isEditingAcademicInfo = true;
      if (data.skills.isNotEmpty) _isEditingSkills = true;
      if (data.workExperience.isNotEmpty) _suggestedWorkExperience = List.of(data.workExperience);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.fieldsFilledReviewNote),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _viewResume() async {
    if (_resumePath == null) return;
    try {
      final url = await AuthService.instance.getResumeSignedUrl(_resumePath!);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => DocumentPreviewScreen(url: url, fileName: _resumeFilename ?? l10n.resume),
      ));
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorCouldNotOpenResumeColon(friendlyError(e))), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _removeResume() async {
    setState(() => _isUploadingResume = true);
    try {
      await AuthService.instance.removeResume();
      if (!mounted) return;
      setState(() {
        _resumeFilename = null;
        _resumeSizeBytes = null;
        _resumeUploadedAt = null;
        _resumePath = null;
        _isUploadingResume = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingResume = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorCouldNotRemoveResume(friendlyError(e))), backgroundColor: AppColors.error),
      );
    }
  }

  // =====================================================================
  // PREFERENCES (persisted)
  // =====================================================================

  String _prefLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'Application updates':
        return l10n.prefApplicationUpdates;
      case 'Report deadlines':
        return l10n.prefReportDeadlines;
      case 'Messages':
        return l10n.prefMessages;
      default:
        return l10n.prefSupervisorFeedback;
    }
  }

  void _showNotificationPreferences() {
    final l10n = AppLocalizations.of(context)!;
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
                    Text(l10n.notificationPreferences,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(l10n.profileChooseWhatToBeNotified,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ..._notificationPrefs.keys.map((key) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_prefLabel(l10n, key), style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
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
                          final dbPrefs = <String, bool>{};
                          _notificationPrefs.forEach((label, value) {
                            dbPrefs[_prefDbKeys[label]!] = value;
                          });
                          try {
                            await AuthService.instance.updateNotificationPrefs(dbPrefs);
                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(l10n.profileNotificationPrefsUpdated),
                                  backgroundColor: AppColors.primary),
                            );
                          } catch (e) {
                            if (!sheetContext.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.errorCouldNotSave(friendlyError(e))), backgroundColor: AppColors.error),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.errorCouldNotSaveLanguage(friendlyError(e))), backgroundColor: AppColors.error),
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
                      SnackBar(content: Text(l10n.errorCouldNotSaveTheme(friendlyError(e))), backgroundColor: AppColors.error),
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
        content: Text(l10n.logOutConfirmMessage,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.logOut, style: TextStyle(color: AppColors.error)),
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

  // =====================================================================
  // BUILD
  // =====================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: scaledExtent(context, 200, textShare: 0.3),
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.headerGradient,
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
                            child: Builder(builder: (context) {
                              const initials = Center(
                                child: Text('👤',
                                    style: TextStyle(fontSize: 32)),
                              );

                              if (_localPreviewImage != null) {
                                return Image.file(
                                  _localPreviewImage!,
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => initials,
                                );
                              }
                              if (_avatarUrl != null) {
                                return Image.network(
                                  _avatarUrl!,
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => initials,
                                );
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
                                child: const Center(
                                  child: SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                ),
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
                              child: Icon(Icons.camera_alt, size: 14, color: AppColors.primaryText),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(_nameController.text.isEmpty ? 'Your name' : _nameController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(_email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: kOnBannerSoft)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Builder(builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                children: [
                  SectionHeader(
                    title: l10n.personalInformation,
                    actionIcon: _isEditingPersonalInfo ? Icons.close : Icons.edit_outlined,
                    onAction: () {
                      if (_isEditingPersonalInfo) {
                        _cancelEditingPersonalInfo();
                      } else {
                        setState(() => _isEditingPersonalInfo = true);
                      }
                    },
                  ),
                  _isEditingPersonalInfo ? _buildPersonalInfoEditForm() : _buildPersonalInfoView(),

                  SectionHeader(
                    title: l10n.academicInformation,
                    actionIcon: _isEditingAcademicInfo ? Icons.close : Icons.edit_outlined,
                    onAction: () {
                      if (_isEditingAcademicInfo) {
                        _cancelEditingAcademicInfo();
                      } else {
                        setState(() => _isEditingAcademicInfo = true);
                      }
                    },
                  ),
                  _isEditingAcademicInfo ? _buildAcademicInfoEditForm() : _buildAcademicInfoView(),

                  SectionHeader(
                    title: l10n.hrSkills,
                    actionIcon: _isEditingSkills ? Icons.close : Icons.edit_outlined,
                    onAction: () {
                      if (_isEditingSkills) {
                        _cancelEditingSkills();
                      } else {
                        setState(() => _isEditingSkills = true);
                      }
                    },
                  ),
                  _isEditingSkills ? _buildSkillsEditForm() : _buildSkillsView(),

                  SectionHeader(title: l10n.workExperience),
                  _buildWorkExperienceSection(),

                  GestureDetector(
                    // Long-press the "Resume" heading to change the resume-scan service address (the
                    // ngrok URL changes every time the tunnel restarts). Works in installed builds too.
                    onLongPress: _showNlpServiceUrlEditor,
                    child: SectionHeader(title: l10n.resume),
                  ),
                  _buildResumeSection(),

                  SectionHeader(title: l10n.account),
                  _SettingsTile(icon: Icons.lock_outline, label: l10n.changePassword, onTap: _showChangePasswordDialog),
                  _SettingsTile(
                      icon: Icons.notifications_outlined,
                      label: l10n.notificationPreferences,
                      onTap: _showNotificationPreferences),
                  _SettingsTile(
                      icon: Icons.language_outlined,
                      label: l10n.language,
                      trailing: _selectedLanguage,
                      onTap: _showLanguagePicker),
                  _SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      label: l10n.theme,
                      trailing: _themeLabel(l10n),
                      onTap: _showThemePicker),
                  _SettingsTile(icon: Icons.privacy_tip_outlined, label: tt('Privacy notice'), onTap: () => openPrivacyPolicy(context)),
                  _SettingsTile(icon: Icons.logout, label: l10n.logOut, isDestructive: true, onTap: _handleLogout),
                  _SettingsTile(icon: Icons.delete_forever_outlined, label: tt('Delete my account'), isDestructive: true, onTap: () => showDeleteAccountFlow(context)),
                  const SizedBox(height: 32),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoView() {
    final l10n = AppLocalizations.of(context)!;
    return _InfoSection(
      items: [
        _InfoItem(icon: Icons.person_outline, label: l10n.fullName, value: _nameController.text.isEmpty ? l10n.notSet : _nameController.text),
        _InfoItem(icon: Icons.phone_outlined, label: l10n.phone, value: _phoneController.text.isEmpty ? l10n.notSet : _phoneController.text),
        _InfoItem(icon: Icons.email_outlined, label: l10n.email, value: _email),
        _InfoItem(
            icon: Icons.cake_outlined,
            label: l10n.dateOfBirth,
            value: _dateOfBirth != null ? _formatDate(_dateOfBirth!) : l10n.notSet),
        _InfoItem(icon: Icons.location_on_outlined, label: l10n.address, value: _addressText ?? l10n.notSet),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _buildPersonalInfoEditForm() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _personalFormKey,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.fullName, style: AppTextStyles.label),
          const SizedBox(height: 6),
          ValidatedField(
            controller: _nameController,
            fieldValidator: (v) => v.trim().isEmpty ? l10n.errorFullNameBlank : Validators.fullName(v),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),

          Text(l10n.phone, style: AppTextStyles.label),
          const SizedBox(height: 6),
          ValidatedField(
            controller: _phoneController,
            fieldValidator: (v) => v.trim().isEmpty ? l10n.errorPhoneBlank : Validators.phone(v),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            hintText: '012-345 6789',
          ),
          const SizedBox(height: 14),

          Text(l10n.email, style: AppTextStyles.label),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(_email, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textMuted)),
          ),
          const SizedBox(height: 14),

          Text(l10n.dateOfBirth, style: AppTextStyles.label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDateOfBirth,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.cake_outlined, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _dateOfBirth != null ? _formatDate(_dateOfBirth!) : l10n.tapToSelectDateOfBirth,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: _dateOfBirth != null ? AppColors.textPrimary : AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_personalAttempted || _dateOfBirth != null)
            _fieldError(Validators.dateOfBirth(_dateOfBirth, minAge: 17)),
          const SizedBox(height: 14),

          Text(l10n.address, style: AppTextStyles.label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickAddress,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _addressText ?? l10n.tapToSelectAddress,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: _addressText != null ? AppColors.textPrimary : AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_personalAttempted)
            _fieldError((_addressText == null || _addressText!.trim().isEmpty) ? l10n.errorSelectAddress : null),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSavingPersonalInfo ? null : _cancelEditingPersonalInfo,
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSavingPersonalInfo ? null : _savePersonalInfo,
                  child: _isSavingPersonalInfo
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _fieldError(String? message) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(message, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.error)),
    );
  }

  Widget _buildAcademicInfoView() {
    final l10n = AppLocalizations.of(context)!;
    final section = _InfoSection(
      items: [
        _InfoItem(icon: Icons.school_outlined, label: l10n.programme, value: _programme ?? l10n.notSet),
        _InfoItem(
            icon: Icons.badge_outlined,
            label: l10n.studentRegNo,
            value: _studentRegNoController.text.isEmpty ? l10n.notSet : _studentRegNoController.text),
        _InfoItem(
            icon: Icons.fingerprint,
            label: tr('IC number', ms: 'Nombor IC', zh: '身份证号码'),
            value: _icController.text.isEmpty ? l10n.notSet : _icController.text),
        _InfoItem(icon: Icons.calendar_today_outlined, label: l10n.semester, value: _semester != null ? '${l10n.semester} $_semester' : l10n.notSet),
        _InfoItem(icon: Icons.class_outlined, label: l10n.faculty, value: _faculty ?? l10n.notSet),
        _InfoItem(icon: Icons.grade_outlined, label: l10n.cgpa, value: _cgpaController.text.isEmpty ? l10n.notSet : _cgpaController.text),
        _InfoItem(
            icon: Icons.person_pin_outlined,
            label: l10n.academicSupervisor,
            value: _academicSupervisorController.text.isEmpty ? l10n.assignedBySystem : _academicSupervisorController.text),
      ],
    );
    if (_academicSupervisorId == null) return section;
    // A student may message their own academic supervisor straight from here.
    return Column(
      children: [
        section,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: MessageButton(profileId: _academicSupervisorId!),
        ),
      ],
    );
  }

  Widget _buildAcademicInfoEditForm() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _academicFormKey,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.programme, style: AppTextStyles.label),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _programme,
            isExpanded: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) => v == null ? l10n.errorSelectProgramme : null,
            decoration: InputDecoration(hintText: l10n.selectYourProgrammeHint),
            items: _programmeOptions
                .map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (val) => setState(() => _programme = val),
          ),
          const SizedBox(height: 14),

          Text(l10n.studentRegNo, style: AppTextStyles.label),
          const SizedBox(height: 6),
          ValidatedField(
            controller: _studentRegNoController,
            fieldValidator: (v) => Validators.studentRegNo(v),
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            maxLength: 10,
            hintText: l10n.studentRegNoHint,
          ),
          const SizedBox(height: 14),

          Text(tr('IC number (optional)', ms: 'Nombor IC (pilihan)', zh: '身份证号码（选填）'), style: AppTextStyles.label),
          const SizedBox(height: 6),
          ValidatedField(
            controller: _icController,
            fieldValidator: (v) => Validators.icNumber(v),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 14,
            showSuccess: false,
            hintText: '030514-10-1234',
          ),
          const SizedBox(height: 4),
          Text(
              tr('Only used to fill in your letters (such as the indemnity and company acceptance letters). Not shown to other students.',
                  ms: 'Hanya digunakan untuk mengisi surat anda (seperti surat indemniti dan surat penerimaan syarikat). Tidak dipaparkan kepada pelajar lain.',
                  zh: '仅用于填写您的信函（如赔偿保证书和公司接受信）。不会向其他学生显示。'),
              style: AppTextStyles.caption),
          const SizedBox(height: 14),

          Text(l10n.faculty, style: AppTextStyles.label),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _faculty,
            isExpanded: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) => v == null ? l10n.errorSelectFaculty : null,
            decoration: InputDecoration(hintText: l10n.selectYourFacultyHint),
            items: _facultyOptions
                .map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (val) => setState(() => _faculty = val),
          ),
          const SizedBox(height: 14),

          Text(l10n.semester, style: AppTextStyles.label),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: _semester,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) => v == null ? l10n.errorSelectSemester : null,
            decoration: InputDecoration(hintText: l10n.selectYourSemesterHint),
            items: List.generate(4, (i) => i + 1)
                .map((s) => DropdownMenuItem(value: s, child: Text(l10n.semesterNumber(s))))
                .toList(),
            onChanged: (val) => setState(() => _semester = val),
          ),
          const SizedBox(height: 14),

          Text(l10n.cgpa, style: AppTextStyles.label),
          const SizedBox(height: 6),
          ValidatedField(
            controller: _cgpaController,
            fieldValidator: (v) => v.trim().isEmpty ? l10n.errorCgpaBlank : Validators.cgpa(v),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            maxLength: 4,
            hintText: l10n.cgpaHint,
          ),
          const SizedBox(height: 14),

          Text(AppLocalizations.of(context)!.academicSupervisor, style: AppTextStyles.label),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.person_pin_outlined, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _academicSupervisorController.text.isEmpty
                        ? AppLocalizations.of(context)!.assignedBySystem
                        : _academicSupervisorController.text,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSavingAcademicInfo ? null : _cancelEditingAcademicInfo,
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSavingAcademicInfo ? null : _saveAcademicInfo,
                  child: _isSavingAcademicInfo
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(AppLocalizations.of(context)!.save),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  void _showResumeOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_resumeFilename ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              ListTile(
                leading: Icon(Icons.visibility_outlined, color: AppColors.primaryText),
                title: Text(l10n.view),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _viewResume();
                },
              ),
              ListTile(
                leading: Icon(Icons.swap_horiz, color: AppColors.primaryText),
                title: Text(l10n.replace),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadResume();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(l10n.remove, style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removeResume();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkillsView() {
    if (_skills.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(l10n.noSkillsAddedYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _skills
            .map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(s, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryText)),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSkillsEditForm() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ValidatedField(
                  key: _skillFieldKey,
                  controller: _skillInputController,
                  fieldValidator: (v) => Validators.skill(v, existing: _skills),
                  showSuccess: false,
                  maxLength: 40,
                  hintText: l10n.addSkillHint,
                  onSubmitted: _addSkill,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(icon: Icon(Icons.add_circle, color: AppColors.primaryText), onPressed: () => _addSkill(_skillInputController.text)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills
                .map((s) => Chip(
                      label: Text(s, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.primaryText)),
                      backgroundColor: AppColors.accent,
                      onDeleted: () => _removeSkill(s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _isSavingSkills ? null : _cancelEditingSkills, child: Text(l10n.cancel))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSavingSkills ? null : _saveSkills,
                  child: _isSavingSkills
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

  Widget _buildWorkExperienceSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_suggestedWorkExperience.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(l10n.suggestedFromResume, style: AppTextStyles.label),
          ),
          ..._suggestedWorkExperience.map((entry) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primaryLight.withOpacity(0.4))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.position ?? l10n.unknownPosition,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(
                      '${entry.companyName ?? l10n.unknownCompany}${entry.startYear != null ? ' · ${entry.startYear}–${entry.isCurrent ? l10n.present : entry.endYear ?? '?'}' : ''}',
                      style: AppTextStyles.caption,
                    ),
                    if (entry.description != null) ...[
                      const SizedBox(height: 4),
                      Text(entry.description!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _suggestedWorkExperience.remove(entry)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                            child: Text(l10n.dismiss, style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _acceptSuggestedWorkExperience(entry),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                            child: Text(l10n.add, style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
        if (_isLoadingWorkExperience)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else if (_workExperience.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(l10n.noWorkExperienceAddedYet, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
          )
        else
          ..._workExperience.map((entry) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry['position'] as String,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text(
                            '${entry['company_name']}${entry['start_year'] != null ? ' · ${entry['start_year']}–${entry['is_current'] == true ? l10n.present : entry['end_year'] ?? '?'}' : ''}',
                            style: AppTextStyles.caption,
                          ),
                          if ((entry['description'] as String?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(entry['description'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                      onSelected: (v) {
                        if (v == 'edit') _showWorkExperienceDialog(existing: entry);
                        if (v == 'delete') _deleteWorkExperience(entry['id'] as String);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.delete, style: TextStyle(color: AppColors.error))),
                      ],
                    ),
                  ],
                ),
              )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: OutlinedButton.icon(
            onPressed: () => _showWorkExperienceDialog(),
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.addWorkExperience),
          ),
        ),
      ],
    );
  }

  Widget _buildResumeSection() {
    final l10n = AppLocalizations.of(context)!;
    final hasResume = _resumeFilename != null && _resumeFilename!.trim().isNotEmpty;

    if (!hasResume) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
              child: Icon(Icons.upload_file_outlined, color: AppColors.primaryText, size: 26),
            ),
            const SizedBox(height: 12),
            Text(l10n.noResumeUploaded,
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(l10n.resumeFormatNote,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploadingResume ? null : _pickAndUploadResume,
                icon: _isUploadingResume
                    ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_outlined, size: 18),
                label: Text(_isUploadingResume ? l10n.uploading : l10n.uploadResume),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: AccentCard(
        onTap: _isUploadingResume ? null : _showResumeOptions,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(
                _resumeFilename!.toLowerCase().endsWith('.pdf')
                    ? Icons.picture_as_pdf_outlined
                    : Icons.description_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_resumeFilename!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(
                    '${_resumeSizeBytes != null ? _formatFileSize(_resumeSizeBytes!) : ''}'
                        '${_resumeUploadedAt != null ? ' ${l10n.updatedOnDate(_formatDate(_resumeUploadedAt!))}' : ''}',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (_isUploadingResume)
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
          ],
        ),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label, style: AppTextStyles.caption),
                          const SizedBox(height: 2),
                          Text(item.value,
                              style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1) const Divider(height: 1, indent: 44),
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
  const _InfoItem({required this.icon, required this.label, required this.value});
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
        title: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        trailing: trailing != null
            ? Text(trailing!, style: AppTextStyles.caption)
            : Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}