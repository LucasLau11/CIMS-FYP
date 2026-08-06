import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'locale_controller.dart';
import 'push_notification_service.dart';
import 'theme_controller.dart';

/// All the possible roles a signed-up user can end up with. 'admin' is a
/// real Supabase account like every other role (no client-side hardcoded
/// credential check) — it's just never offered on the sign-up screen since
/// there's only ever meant to be one, provisioned directly in the database.
enum UserRole {
  student,
  academicSupervisor,
  companyHr,
  companySupervisor,
  parent,
  admin,
}

/// Result of [AuthService.signUp] — the caller must check
/// [needsEmailConfirmation] before assuming there's an active session to
/// navigate into.
class SignUpResult {
  const SignUpResult({required this.role, required this.needsEmailConfirmation});

  final UserRole role;
  final bool needsEmailConfirmation;
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
      case UserRole.admin:
        return 'admin';
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
      case 'admin':
        return UserRole.admin;
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
  // Restoring a session on app start (problem 9). Admin is a real Supabase
  // account like every other role now, so this is the same path for
  // everyone — Supabase already persists sessions across app restarts.
  // ---------------------------------------------------------------------

  /// Checks for a restored Supabase session on app start. Returns null if
  /// there's nothing to restore (show the login screen).
  Future<UserRole?> checkForRestoredSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    try {
      final profile = await getCurrentProfile();
      if (profile == null) return null;

      await PushNotificationService.instance.linkUser(session.user.id);

      final savedLanguage = profile['language'] as String?;
      if (savedLanguage != null) {
        await LocaleController.instance.setLanguageByDisplayName(savedLanguage);
      }

      final savedThemeMode = profile['theme_mode'] as String?;
      if (savedThemeMode != null) {
        await ThemeController.instance.setThemeModeByCode(savedThemeMode);
      }

      return UserRoleX.fromDbValue(profile['role'] as String);
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

  /// Fetches the current user's full profile row (profile_id, email, role,
  /// avatar_url, plus role-specific fields). Students read from
  /// `v_student_profile` (base profile columns + students subtype columns
  /// already joined); every other role reads the base `profiles` row, with
  /// `company_id` merged in from the matching subtype table for company_hr/
  /// company_supervisor. The returned map's keys intentionally match the
  /// flat shape the old single-table schema used to return, since every
  /// screen that calls this was written against that shape.
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final role = await _client
        .from('profiles')
        .select('role')
        .eq('profile_id', userId)
        .single()
        .then((r) => r['role'] as String);

    Map<String, dynamic> row;
    if (role == 'student') {
      row = Map<String, dynamic>.from(
        await _client.from('v_student_profile').select().eq('profile_id', userId).single(),
      );
      row['role'] = role;

      // academic_supervisor_name isn't a real column anywhere — assignment
      // only sets academic_supervisor_id (see AdminDataService.
      // assignSupervisor). Resolve the name dynamically via
      // profile_directory instead, which every authenticated user can read.
      final supervisorId = row['academic_supervisor_id'] as String?;
      if (supervisorId != null) {
        try {
          final supervisor = await _client
              .from('profile_directory')
              .select('full_name')
              .eq('profile_id', supervisorId)
              .maybeSingle();
          row['academic_supervisor_name'] = supervisor?['full_name'] as String?;
        } catch (_) {
          // Non-fatal — falls back to whatever was in the (likely null) column.
        }
      }
    } else {
      row = Map<String, dynamic>.from(
        await _client
            .from('profiles')
            .select('profile_id, email, role, avatar_url, full_name, phone, date_of_birth, '
                'address_text, address_lat, address_lng, language, theme_mode, notification_prefs')
            .eq('profile_id', userId)
            .single(),
      );

      if (role == 'company_hr' || role == 'company_supervisor') {
        final subtypeTable = role == 'company_hr' ? 'company_hr' : 'company_supervisors';
        final subtype = await _client
            .from(subtypeTable)
            .select('company_id')
            .eq('profile_id', userId)
            .maybeSingle();
        row['company_id'] = subtype?['company_id'] as String?;
      }
    }

    return row;
  }

  /// Updates the current user's skills list (extracted from resume and/or
  /// entered manually). Skills live on the `students` subtype table.
  Future<void> updateSkills(List<String> skills) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be logged in to update your profile.');
    }
    await _client.from('students').update({'skills': skills}).eq('profile_id', userId);
  }

  // ---------------------------------------------------------------------
  // Avatar upload — stored in the PUBLIC 'avatars' Storage bucket (unlike
  // resumes, which are private). Public because avatars are meant to be
  // visible to other users across the app (e.g. in messaging, candidate
  // cards), not just the owner.
  // ---------------------------------------------------------------------
  Future<String> uploadAvatar(File file) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be logged in to upload a profile photo.');
    }

    final ext = file.path.split('.').last.toLowerCase();
    final storagePath = '$userId.$ext';

    await _client.storage.from('avatars').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    // Supabase returns the same public URL for the same storage path, so a
    // re-uploaded photo needs a cache-busting query param — otherwise both
    // Flutter's NetworkImage cache and any CDN in front of the public
    // bucket would keep serving the previous photo's bytes.
    final publicUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
    final cacheBustedUrl = '$publicUrl?updated=${DateTime.now().millisecondsSinceEpoch}';
    await _client.from('profiles').update({'avatar_url': cacheBustedUrl}).eq('profile_id', userId);

    return cacheBustedUrl;
  }

  /// Removes the current user's avatar from Storage and clears the DB column.
  Future<void> removeAvatar() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final files = await _client.storage.from('avatars').list();
      final userFiles = files.where((f) => f.name.startsWith('$userId.')).map((f) => f.name).toList();
      if (userFiles.isNotEmpty) {
        await _client.storage.from('avatars').remove(userFiles);
      }
    } catch (_) {
      // Non-fatal — proceed to clear the DB reference regardless.
    }

    await _client.from('profiles').update({'avatar_url': null}).eq('profile_id', userId);
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

    // Resume fields live on the `students` subtype table, not `profiles` —
    // resumes only make sense for the student role.
    await _client.from('students').update({
      'resume_path': storagePath,
      'resume_filename': originalFilename,
      'resume_size_bytes': sizeBytes,
      'resume_uploaded_at': DateTime.now().toIso8601String(),
    }).eq('profile_id', userId);
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

    await _client.from('students').update({
      'resume_path': null,
      'resume_filename': null,
      'resume_size_bytes': null,
      'resume_uploaded_at': null,
    }).eq('profile_id', userId);
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
    }).eq('profile_id', userId);
  }

  /// Updates just the display name — for roles (e.g. academic supervisor)
  /// whose profile screen doesn't collect phone/DOB/address the way the
  /// student one does.
  Future<void> updateFullName(String fullName) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be logged in to update your profile.');
    }
    await _client.from('profiles').update({'full_name': fullName.trim()}).eq('profile_id', userId);
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
    }).eq('profile_id', userId);
  }

  // ---------------------------------------------------------------------
  // Notification preferences + language (problem 8) — persisted to the
  // profile row so they survive navigating away or closing the app,
  // instead of living only in local widget state.
  // ---------------------------------------------------------------------
  Future<void> updateNotificationPrefs(Map<String, bool> prefs) async {
    final userId = currentUserId;
    if (userId == null) return;
    await _client.from('profiles').update({'notification_prefs': prefs}).eq('profile_id', userId);
  }

  Future<void> updateLanguage(String language) async {
    await LocaleController.instance.setLanguageByDisplayName(language);
    final userId = currentUserId;
    if (userId == null) return;
    await _client.from('profiles').update({'language': language}).eq('profile_id', userId);
  }

  Future<void> updateThemeMode(String themeMode) async {
    await ThemeController.instance.setThemeModeByCode(themeMode);
    final userId = currentUserId;
    if (userId == null) return;
    await _client.from('profiles').update({'theme_mode': themeMode}).eq('profile_id', userId);
  }

  // ---------------------------------------------------------------------
  // Academic information (problem 4).
  // ---------------------------------------------------------------------
  Future<void> updateAcademicInfo({
    required String programme,
    required int semester,
    required String faculty,
    required double cgpa,
    String? studentRegNo,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('You must be logged in to update your profile.');
    }

    // Academic fields live on the `students` subtype table, not `profiles`.
    await _client.from('students').update({
      'programme': programme,
      'semester': semester,
      'faculty': faculty,
      'cgpa': cgpa,
      if (studentRegNo != null) 'student_reg_no': studentRegNo.trim(),
    }).eq('profile_id', userId);
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
  // Sign up: creates the Supabase auth account. The `profiles` row and its
  // matching subtype row (students/academic_supervisors/parents/
  // company_hr/company_supervisors) are created automatically by a
  // database trigger on `auth.users` insert (`handle_new_auth_user`,
  // reading the `app_role` passed via `data` below) — NOT by a client-side
  // RPC call. This matters because when Supabase Auth's "Confirm email"
  // setting is enabled, signUp() returns a user with no active session
  // until the confirmation link is clicked, so any authenticated
  // client-side call made immediately after signUp() (like the RPC this
  // used to call) would fail with a permission error. A DB trigger fires
  // as part of GoTrue's own privileged insert regardless of session state,
  // so this works the same way whether email confirmation is on or off.
  // Admin accounts can never come out of this path — the trigger silently
  // skips profile creation for `app_role: 'admin'`.
  // ---------------------------------------------------------------------
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    UserRole? manualRole,
  }) async {
    final domainRole = roleFromEmailDomain(email);
    final role = domainRole ?? manualRole;

    if (role == null) {
      throw Exception('A role must be selected for this email.');
    }

    final trimmedEmail = email.trim();

    AuthResponse response;
    try {
      response = await _client.auth.signUp(
        email: trimmedEmail,
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

    if (response.user == null) {
      throw Exception('Sign-up failed — no user returned.');
    }

    // No session means Supabase Auth requires email confirmation before
    // this account can actually log in — the caller must not treat this
    // like an immediate, logged-in sign-up (e.g. must not navigate into an
    // authenticated shell), since there is no session to do anything with
    // yet.
    return SignUpResult(role: role, needsEmailConfirmation: response.session == null);
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

    await PushNotificationService.instance.linkUser(user.id);

    try {
      final row = await _client
          .from('profiles')
          .select('role')
          .eq('profile_id', user.id)
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
  // Log out — clears the current Supabase session.
  // ---------------------------------------------------------------------
  Future<void> signOut() async {
    await PushNotificationService.instance.unlinkUser();
    await _client.auth.signOut();
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