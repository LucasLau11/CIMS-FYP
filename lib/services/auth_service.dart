import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'locale_controller.dart';
import 'theme_controller.dart';

/// All the possible roles a signed-up user can end up with.
/// 'admin' is intentionally excluded — the admin account is a hardcoded
/// demo login and never goes through Supabase (see AuthService.isAdminLogin).
enum UserRole {
  student,
  academicSupervisor,
  companyHr,
  companySupervisor,
  parent,
}

extension UserRoleX on UserRole {
  String get dbValue {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.academicSupervisor:
        return 'academic_supervisor';
      case UserRole.companyHr:
        return 'company_hr';
      case UserRole.companySupervisor:
        return 'company_supervisor';
      case UserRole.parent:
        return 'parent';
    }
  }

  static UserRole fromDbValue(String value) {
    switch (value) {
      case 'student':
        return UserRole.student;
      case 'academic_supervisor':
        return UserRole.academicSupervisor;
      case 'company_hr':
        return UserRole.companyHr;
      case 'company_supervisor':
        return UserRole.companySupervisor;
      case 'parent':
        return UserRole.parent;
      default:
        throw ArgumentError('Unknown role value: $value');
    }
  }
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ---------------------------------------------------------------------
  // Admin — hardcoded demo credential, deliberately NOT stored in Supabase.
  // NOTE: this is a temporary demo shortcut for FYP purposes only. Do not
  // replace with real institutional admin accounts without moving this to
  // proper backend-verified auth.
  // ---------------------------------------------------------------------
  static const String adminEmail = 'lucas@tar.edu.my';
  static const String adminPassword = 'ABCxyz#123';

  bool isAdminLogin(String email, String password) {
    return email.trim().toLowerCase() == adminEmail && password == adminPassword;
  }

  /// The admin login itself stays a hardcoded client-side check (by
  /// design — see the class doc), but every admin screen reads/writes
  /// real Supabase data behind RLS, which requires a real authenticated
  /// session (the anon key alone has none). A matching real Supabase
  /// account was created out-of-band with these same credentials and
  /// role='admin', so this establishes that session silently right after
  /// the hardcoded check passes — the login UX is unchanged, but the app
  /// now has a genuine JWT for RLS to key off. Non-fatal if it fails
  /// (e.g. offline): admin screens will just show empty/error states
  /// rather than blocking login entirely.
  Future<void> establishAdminSupabaseSession() async {
    try {
      await _client.auth.signInWithPassword(email: adminEmail, password: adminPassword);
    } catch (_) {
      // Non-fatal — see doc comment above.
    }
  }

  // ---------------------------------------------------------------------
  // Persistent login (problem 9). Supabase already persists real user
  // sessions across app restarts automatically. The hardcoded admin
  // account never creates a Supabase session though, so it needs its own
  // locally-stored "remembered" flag to get the same stay-logged-in
  // behaviour.
  // ---------------------------------------------------------------------
  static const String _adminRememberedKey = 'cims_admin_remembered';

  Future<void> setAdminRemembered(bool remembered) async {
    final prefs = await SharedPreferences.getInstance();
    if (remembered) {
      await prefs.setBool(_adminRememberedKey, true);
    } else {
      await prefs.remove(_adminRememberedKey);
    }
  }

  Future<bool> isAdminRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adminRememberedKey) ?? false;
  }

  /// Checks for either a real Supabase session or a remembered admin login.
  /// Returns null if there's nothing to restore (show the login screen).
  /// Returns UserRole for a normal restored session, or throws
  /// [AdminSessionRestored] as a signal value for the admin case.
  Future<RestoredSession?> checkForRestoredSession() async {
    if (await isAdminRemembered()) {
      return RestoredSession.admin();
    }

    final session = _client.auth.currentSession;
    if (session == null) return null;

    try {
      final profile = await getCurrentProfile();
      if (profile == null) return null;

      final savedLanguage = profile['language'] as String?;
      if (savedLanguage != null) {
        await LocaleController.instance.setLanguageByDisplayName(savedLanguage);
      }

      final savedThemeMode = profile['theme_mode'] as String?;
      if (savedThemeMode != null) {
        await ThemeController.instance.setThemeModeByCode(savedThemeMode);
      }

      return RestoredSession.role(UserRoleX.fromDbValue(profile['role'] as String));
    } catch (_) {
      // Session token present but invalid/expired/profile missing —
      // treat as no session, fall back to login screen.
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Allowed email domains for sign-up. Anything outside this list is
  // rejected — keeps accounts limited to institutional emails plus the
  // common personal providers used by parents/company staff.
  // ---------------------------------------------------------------------
  static const List<String> allowedEmailDomains = [
    'outlook.com',
    'gmail.com',
    'hotmail.com',
    'student.tarc.edu.my',
    'tarc.edu.my',
  ];

  static final RegExp _emailFormatRegex =
  RegExp(r'^[\w\.\-\+]+@[\w\-]+(\.[\w\-]+)+$');

  /// Validates email format + domain allowlist.
  /// Returns an error message, or null if the email is valid.
  String? validateEmail(String email) {
    final trimmed = email.trim();

    if (trimmed.isEmpty) {
      return 'Email is required.';
    }

    if (!_emailFormatRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }

    final lower = trimmed.toLowerCase();
    final domainAllowed =
    allowedEmailDomains.any((domain) => lower.endsWith('@$domain'));

    if (!domainAllowed) {
      return 'Email must be from @gmail.com, @outlook.com, @hotmail.com, '
          '@student.tarc.edu.my, or @tarc.edu.my.';
    }

    return null;
  }

  /// Validates password strength: 8+ chars, upper, lower, digit, symbol.
  /// Returns an error message, or null if the password is valid.
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must include at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must include at least one lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must include at least one number.';
    }
    if (!RegExp(r'[!@#\$%\^&\*(),.?":{}|<>_\-+=~`\[\];/\\]')
        .hasMatch(password)) {
      return 'Password must include at least one symbol (e.g. ! @ # \$ %).';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Current user / profile helpers
  // ---------------------------------------------------------------------
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Fetches the current user's full profile row (id, email, role, avatar_url).
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final row = await _client
        .from('profiles')
        .select('id, email, role, avatar_url, full_name, phone, date_of_birth, '
        'address_text, address_lat, address_lng, language, theme_mode, notification_prefs, '
        'resume_path, resume_filename, resume_size_bytes, resume_uploaded_at, '
        'programme, semester, faculty, cgpa, skills, academic_supervisor_id, academic_supervisor_name')
        .eq('id', userId)
        .single();

    // academic_supervisor_name is a legacy column that's never written to —
    // assignment only sets academic_supervisor_id (see AdminDataService.
    // assignSupervisor). Resolve the name dynamically via profile_directory
    // instead, which every authenticated user can read.
    final supervisorId = row['academic_supervisor_id'] as String?;
    if (supervisorId != null) {
      try {
        final supervisor = await _client
            .from('profile_directory')
            .select('full_name')
            .eq('id', supervisorId)
            .maybeSingle();
        row['academic_supervisor_name'] = supervisor?['full_name'] as String?;
      } catch (_) {
        // Non-fatal — falls back to whatever was in the (likely null) column.
      }
    }

    return row;
  }

  /// Updates the current user's skills list (extracted from resume and/or
  /// entered manually).
  Future<void> updateSkills(List<String> skills) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be logged in to update your profile.');
    }
    await _client.from('profiles').update({'skills': skills}).eq('id', userId);
  }

  // ---------------------------------------------------------------------
  // Avatar — stored LOCALLY on-device (not Supabase Storage).
  //
  // Why: Supabase Storage uploads kept failing with a row-level-security
  // error even after confirming the policies were correct and even after
  // testing with a maximally permissive "is authenticated" check — meaning
  // auth.uid() wasn't reaching Postgres for storage calls specifically.
  // Rather than fight that further, the photo is saved to the app's local
  // documents folder, and the *local file path* is saved in the profiles
  // table's avatar_url column (same column, different meaning now).
  //
  // Tradeoff to be aware of: this means the photo only exists on the
  // device it was set on — it won't appear if the student logs in on a
  // different device, and it's lost if the app is uninstalled/data is
  // cleared. The `profiles.avatar_url` value still travels with the
  // account, but there's no file behind it on another device.
  // ---------------------------------------------------------------------
  /// Verifies the locally-stored avatar file still exists on this install.
  /// It won't after a fresh install/reinstall — the app's documents folder
  /// (and the file in it) is wiped, but `profiles.avatar_url` is remote and
  /// survives. Self-heals by clearing the stale DB reference so the UI
  /// doesn't keep failing to load a dead path or offer to remove/replace a
  /// photo that's already gone.
  Future<String?> resolveAvatarPath(String? storedPath) async {
    if (storedPath == null) return null;
    if (await File(storedPath).exists()) return storedPath;

    final userId = currentUserId;
    if (userId != null) {
      try {
        await _client.from('profiles').update({'avatar_url': null}).eq('id', userId);
      } catch (_) {
        // Non-fatal — worst case it re-checks and retries next load.
      }
    }
    return null;
  }

  Future<String> uploadAvatar(File file) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be logged in to upload a profile photo.');
    }

    final ext = file.path.split('.').last.toLowerCase();
    final docsDir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory('${docsDir.path}/avatars');
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }

    final localPath = '${avatarsDir.path}/$userId.$ext';
    await file.copy(localPath);

    await _client.from('profiles').update({'avatar_url': localPath}).eq('id', userId);

    return localPath;
  }

  /// Removes the current user's locally-stored avatar and clears the DB column.
  Future<void> removeAvatar() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory('${docsDir.path}/avatars');
      if (await avatarsDir.exists()) {
        final files = avatarsDir.listSync().where((f) => f.path.contains('/$userId.'));
        for (final f in files) {
          await f.delete();
        }
      }
    } catch (_) {
      // Non-fatal — proceed to clear the DB reference regardless.
    }

    await _client.from('profiles').update({'avatar_url': null}).eq('id', userId);
  }

  // ---------------------------------------------------------------------
  // Resume upload — stored in a PRIVATE bucket (unlike avatars) since
  // resumes contain personal info. Access is via short-lived signed URLs
  // only, never a public link.
  // ---------------------------------------------------------------------
  static const int maxResumeSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedResumeExtensions = ['pdf', 'docx'];

  Future<void> uploadResume({
    required File file,
    required String originalFilename,
    required int sizeBytes,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be logged in to upload a resume.');
    }

    final ext = originalFilename.split('.').last.toLowerCase();
    if (!allowedResumeExtensions.contains(ext)) {
      throw Exception('Only PDF or DOCX files are accepted.');
    }
    if (sizeBytes > maxResumeSizeBytes) {
      throw Exception('File is too large — max size is 5MB.');
    }
    if (sizeBytes == 0) {
      throw Exception('The selected file is empty.');
    }

    final storagePath = '$userId/resume.$ext';

    await _client.storage.from('resumes').upload(
      storagePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    await _client.from('profiles').update({
      'resume_path': storagePath,
      'resume_filename': originalFilename,
      'resume_size_bytes': sizeBytes,
      'resume_uploaded_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> removeResume() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final files = await _client.storage.from('resumes').list(path: userId);
      if (files.isNotEmpty) {
        await _client.storage
            .from('resumes')
            .remove(files.map((f) => '$userId/${f.name}').toList());
      }
    } catch (_) {
      // Non-fatal — proceed to clear the DB reference regardless.
    }

    await _client.from('profiles').update({
      'resume_path': null,
      'resume_filename': null,
      'resume_size_bytes': null,
      'resume_uploaded_at': null,
    }).eq('id', userId);
  }

  /// Generates a short-lived signed URL to view/download the resume,
  /// since the bucket is private.
  Future<String> getResumeSignedUrl(String storagePath) async {
    return await _client.storage.from('resumes').createSignedUrl(storagePath, 300);
  }

  // ---------------------------------------------------------------------
  // Personal information (problem 3) — full name, phone, date of birth,
  // and address (chosen via map, stored as text + lat/lng).
  // ---------------------------------------------------------------------
  Future<void> updatePersonalInfo({
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
    required String addressText,
    required double addressLat,
    required double addressLng,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be logged in to update your profile.');
    }

    final dobString =
        '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';

    await _client.from('profiles').update({
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'date_of_birth': dobString,
      'address_text': addressText.trim(),
      'address_lat': addressLat,
      'address_lng': addressLng,
    }).eq('id', userId);
  }

  /// Updates just the display name — for roles (e.g. academic supervisor)
  /// whose profile screen doesn't collect phone/DOB/address the way the
  /// student one does.
  Future<void> updateFullName(String fullName) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be logged in to update your profile.');
    }
    await _client.from('profiles').update({'full_name': fullName.trim()}).eq('id', userId);
  }

  /// Same fields as [updatePersonalInfo] minus date of birth — for staff
  /// roles (HR, company supervisor, academic supervisor) whose profile
  /// screen doesn't collect a DOB the way the student one does.
  Future<void> updateContactInfo({
    required String fullName,
    required String phone,
    String? addressText,
    double? addressLat,
    double? addressLng,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be logged in to update your profile.');
    }
    await _client.from('profiles').update({
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      if (addressText != null) 'address_text': addressText.trim(),
      if (addressLat != null) 'address_lat': addressLat,
      if (addressLng != null) 'address_lng': addressLng,
    }).eq('id', userId);
  }

  // ---------------------------------------------------------------------
  // Notification preferences + language (problem 8) — persisted to the
  // profile row so they survive navigating away or closing the app,
  // instead of living only in local widget state.
  // ---------------------------------------------------------------------
  Future<void> updateNotificationPrefs(Map<String, bool> prefs) async {
    final userId = currentUserId;
    if (userId == null) return;
    await _client.from('profiles').update({'notification_prefs': prefs}).eq('id', userId);
  }

  Future<void> updateLanguage(String language) async {
    await LocaleController.instance.setLanguageByDisplayName(language);
    final userId = currentUserId;
    if (userId == null) return;
    await _client.from('profiles').update({'language': language}).eq('id', userId);
  }

  Future<void> updateThemeMode(String themeMode) async {
    await ThemeController.instance.setThemeModeByCode(themeMode);
    final userId = currentUserId;
    if (userId == null) return;
    await _client.from('profiles').update({'theme_mode': themeMode}).eq('id', userId);
  }

  // ---------------------------------------------------------------------
  // Academic information (problem 4).
  // ---------------------------------------------------------------------
  Future<void> updateAcademicInfo({
    required String programme,
    required int semester,
    required String faculty,
    required double cgpa,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be logged in to update your profile.');
    }

    await _client.from('profiles').update({
      'programme': programme,
      'semester': semester,
      'faculty': faculty,
      'cgpa': cgpa,
    }).eq('id', userId);
  }

  // ---------------------------------------------------------------------
  // Change password (problem 7). Re-verifies the current password via a
  // sign-in attempt before applying the change — Supabase's updateUser()
  // doesn't require this on its own since the session is already
  // authenticated, but requiring it here stops someone from changing the
  // password if they got hold of an active session without knowing the
  // actual password (e.g. an unlocked, unattended phone).
  // ---------------------------------------------------------------------
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) {
      throw Exception('You must be logged in to change your password.');
    }

    try {
      await _client.auth.signInWithPassword(email: email, password: currentPassword);
    } on AuthException {
      throw Exception('Current password is incorrect.');
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw Exception('Could not update password: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------
  // Role assignment at sign-up time, based on email domain.
  // Returns null if the email needs the user to pick a role manually
  // (Parent/Guardian, HR Personnel, or Company Supervisor).
  // ---------------------------------------------------------------------
  UserRole? roleFromEmailDomain(String email) {
    final lower = email.trim().toLowerCase();
    if (lower.endsWith('@student.tarc.edu.my')) {
      return UserRole.student;
    } else if (lower.endsWith('@tarc.edu.my')) {
      return UserRole.academicSupervisor;
    }
    return null; // needs manual role selection during sign-up
  }

  static const List<String> personalEmailDomains = [
    'outlook.com',
    'gmail.com',
    'hotmail.com',
  ];

  bool isPersonalEmailDomain(String email) {
    final lower = email.trim().toLowerCase();
    return personalEmailDomains.any((domain) => lower.endsWith('@$domain'));
  }

  bool needsManualRoleSelection(String email) =>
      roleFromEmailDomain(email) == null && isPersonalEmailDomain(email);

  // ---------------------------------------------------------------------
  // Sign up: creates the Supabase auth account. The `profiles` row is
  // created automatically by a database trigger (see migration
  // auto_create_profile_trigger) using the role passed here as metadata —
  // this guarantees every auth user always has a matching profile, even if
  // the app is closed/interrupted right after sign-up.
  // ---------------------------------------------------------------------
  Future<UserRole> signUp({
    required String email,
    required String password,
    UserRole? manualRole,
  }) async {
    final domainRole = roleFromEmailDomain(email);
    final role = domainRole ?? manualRole;

    if (role == null) {
      throw Exception('A role must be selected for this email.');
    }

    AuthResponse response;
    try {
      response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'app_role': role.dbValue},
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already exists') ||
          msg.contains('user already')) {
        throw Exception(
            'An account with this email already exists. Please log in instead.');
      }
      rethrow;
    }

    final user = response.user;
    if (user == null) {
      throw Exception('Sign-up failed — no user returned.');
    }

    return role;
  }

  // ---------------------------------------------------------------------
  // Login: authenticates then looks up the stored role.
  // ---------------------------------------------------------------------
  Future<UserRole> logIn({
    required String email,
    required String password,
  }) async {
    AuthResponse response;
    try {
      response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      // Supabase deliberately does not distinguish "no such email" from
      // "wrong password" — revealing which one it is would let an attacker
      // enumerate which emails have accounts. We can only show a combined
      // message here; this is intentional, not a limitation we can fix.
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid email or password')) {
        throw AuthFieldException.credentials(
            'Incorrect email or password. Please try again.');
      }
      if (msg.contains('email not confirmed')) {
        throw AuthFieldException.credentials(
            'Please confirm your email before logging in.');
      }
      throw AuthFieldException.credentials('Login failed: ${e.message}');
    }

    final user = response.user;
    if (user == null) {
      throw AuthFieldException.credentials(
          'Incorrect email or password. Please try again.');
    }

    try {
      final row = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      return UserRoleX.fromDbValue(row['role'] as String);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No profile row found for this authenticated user — should not
        // happen now that profile creation is a DB trigger, but handled
        // defensively in case of pre-trigger legacy accounts.
        throw AuthFieldException.account(
            'Your account is missing role information. Please contact support or sign up again.');
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Forgot password: sends a reset email via Supabase. Always shows the
  // same confirmation regardless of whether the email exists, to avoid
  // revealing which emails are registered.
  // ---------------------------------------------------------------------
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException {
      // Intentionally swallow errors here too — don't leak whether the
      // email exists via a different error path.
    }
  }

  // ---------------------------------------------------------------------
  // Log out — clears the current Supabase session AND the admin
  // remembered flag, so logout works no matter which login path was used.
  // ---------------------------------------------------------------------
  Future<void> signOut() async {
    await _client.auth.signOut();
    await setAdminRemembered(false);
  }
}

/// Distinguishes WHICH part of the login form an auth error relates to,
/// so the UI can decide where to show it (field-level vs a general banner).
class AuthFieldException implements Exception {
  final String message;
  final AuthFieldTarget target;

  AuthFieldException(this.message, this.target);
  AuthFieldException.credentials(this.message) : target = AuthFieldTarget.credentials;
  AuthFieldException.account(this.message) : target = AuthFieldTarget.account;

  @override
  String toString() => message;
}

enum AuthFieldTarget { credentials, account }

/// Result of checking for a restored session on app start — either the
/// hardcoded admin was remembered, or a real Supabase session restored to
/// a specific role.
class RestoredSession {
  final bool isAdmin;
  final UserRole? role;

  RestoredSession.admin()
      : isAdmin = true,
        role = null;

  RestoredSession.role(UserRole role)
      : isAdmin = false,
        role = role;
}