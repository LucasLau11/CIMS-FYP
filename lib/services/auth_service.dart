import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'locale_controller.dart';
import 'push_notification_service.dart';
import 'theme_controller.dart';
import '../utils/lang.dart';
import '../utils/validators.dart';
import '../theme/role_theme.dart';

/// All the possible roles a signed-up user can end up with. 'admin' is a
/// real Supabase account like every other role (no client-side hardcoded
/// credential check) — it's just never offered on the sign-up screen since
/// there's only ever meant to be one, provisioned directly in the database.
enum UserRole {
  student,
  academicSupervisor,
  companyHr,
  companySupervisor,
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

      // A restored session for an account that is (no longer) approved must
      // not get into the app.
      final approval = await _client
          .from('profiles')
          .select('approval_status')
          .eq('profile_id', session.user.id)
          .single()
          .then((r) => r['approval_status'] as String? ?? 'approved');
      if (approval != 'approved') {
        await _client.auth.signOut();
        return null;
      }

      await PushNotificationService.instance.linkUser(session.user.id);

      final savedLanguage = profile['language'] as String?;
      if (savedLanguage != null) {
        await LocaleController.instance.setLanguageByDisplayName(savedLanguage);
      }

      final savedThemeMode = profile['theme_mode'] as String?;
      if (savedThemeMode != null) {
        await ThemeController.instance.setThemeModeByCode(savedThemeMode);
      }

      final restoredRole = profile['role'] as String;
      RoleController.instance.setRole(restoredRole);
      return UserRoleX.fromDbValue(restoredRole);
    } catch (_) {
      // Session token present but invalid/expired/profile missing —
      // treat as no session, fall back to login screen.
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Email / password rules live in lib/utils/validators.dart (one source of
  // truth, shared with the live field checks). These wrappers keep the
  // existing call sites working.
  // ---------------------------------------------------------------------
  static List<String> get allowedEmailDomains => Validators.allowedEmailDomains;

  /// Validates email format + domain allowlist.
  /// Returns an error message, or null if the email is valid.
  String? validateEmail(String email) => Validators.email(email);

  /// Validates password strength: 8+ chars, upper, lower, digit, symbol.
  /// Returns an error message, or null if the password is valid.
  String? validatePassword(String password) => Validators.password(password);


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
      throw const WrongCurrentPasswordException();
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('different from the old password')) {
        throw Exception('Choose a new password that is different from your current one.');
      }
      throw Exception('Could not update your password. Please try again.');
    }
  }

  // ---------------------------------------------------------------------
  // Role assignment at sign-up time, based on email domain.
  // Returns null if the email needs the user to pick a role manually
  // (HR Personnel or Company Supervisor).
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
  // matching subtype row (students/academic_supervisors/
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
    String? fullName,
  }) async {
    final domainRole = roleFromEmailDomain(email);
    final role = domainRole ?? manualRole;

    if (role == null) {
      throw Exception('A role must be selected for this email.');
    }
    if (role == UserRole.student) {
      throw Exception('Student accounts are created by your administrator. Log in with the email and password you were given.');
    }

    final trimmedEmail = email.trim();

    AuthResponse response;
    try {
      response = await _client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {
          'app_role': role.dbValue,
          // Stored on the profile by the sign-up trigger so administrators
          // can see who they are approving.
          if (fullName != null && fullName.trim().isNotEmpty) 'full_name': fullName.trim(),
        },
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already exists') ||
          msg.contains('user already')) {
        throw AccountAlreadyExistsException(trimmedEmail);
      }
      rethrow;
    }

    if (response.user == null) {
      throw Exception('Sign-up failed — no user returned.');
    }

    // Signing up with an email that already has a confirmed account is not an
    // error to Supabase (it answers the same as for a new account, so nobody
    // can probe which emails are registered), and it sends NO email. The only
    // sign is an empty identities list. Without this check the person waits
    // for a code that will never come.
    if (response.user!.identities?.isEmpty ?? false) {
      throw AccountAlreadyExistsException(trimmedEmail);
    }

    // No session means Supabase Auth requires email confirmation before
    // this account can actually log in — the caller must not treat this
    // like an immediate, logged-in sign-up (e.g. must not navigate into an
    // authenticated shell), since there is no session to do anything with
    // yet.
    final signedIn = response.session != null;
    // Staff accounts are pending approval and are signed out by the caller,
    // so only an immediately usable session takes on the role's colours.
    if (signedIn && !(role == UserRole.academicSupervisor || role == UserRole.companySupervisor)) {
      RoleController.instance.setRole(role.dbValue);
    }
    return SignUpResult(role: role, needsEmailConfirmation: !signedIn);
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
        // Say WHICH one is wrong. (Supabase itself answers the same for both,
        // so the app asks the database whether the email has an account. That
        // lets someone check whether an email is registered, a trade-off the
        // project owner chose for clearer messages.)
        bool? known;
        try {
          known = await _client.rpc('email_has_account', params: {'p_email': email.trim()}) as bool?;
        } catch (_) {
          known = null;
        }
        if (known == false) {
          throw AuthFieldException(
              tr('No account uses this email. Check it for typing mistakes.',
                  ms: 'Tiada akaun menggunakan e-mel ini. Semak kesilapan menaip.',
                  zh: '没有使用此邮箱的账户，请检查是否输错。'),
              AuthFieldTarget.email);
        }
        if (known == true) {
          throw AuthFieldException(
              tr('Incorrect password. Please try again.',
                  ms: 'Kata laluan salah. Sila cuba lagi.',
                  zh: '密码不正确，请重试。'),
              AuthFieldTarget.password);
        }
        throw AuthFieldException.credentials(tr('Incorrect email or password. Please try again.',
            ms: 'E-mel atau kata laluan salah. Sila cuba lagi.', zh: '邮箱或密码不正确，请重试。'));
      }
      if (msg.contains('banned') || msg.contains('user is suspended')) {
        throw AuthFieldException.account(_suspendedMessage());
      }
      if (msg.contains('email not confirmed')) {
        // The sign-up was never finished (the email code was not entered), so there is no account: the
        // person signs up again. (Nothing can be done with such a sign-up, and a new one replaces it.)
        throw AuthFieldException.account(tr('This sign-up was never completed, so there is no account yet. Please sign up again.',
            ms: 'Pendaftaran ini tidak pernah diselesaikan, jadi belum ada akaun. Sila daftar semula.',
            zh: '此注册从未完成，因此还没有账户。请重新注册。'));
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
          .select('role, approval_status')
          .eq('profile_id', user.id)
          .single();

      // Staff accounts (supervisors, HR) must be approved by an administrator
      // before they can use the app. An unapproved account is signed straight
      // back out — the database also gives it no privileges (see 00023).
      final approval = row['approval_status'] as String? ?? 'approved';
      if (approval != 'approved') {
        await _client.auth.signOut();
        throw AuthFieldException.account(approval == 'rejected'
            ? tr('Your registration was not approved. Please contact the internship office.',
                ms: 'Pendaftaran anda tidak diluluskan. Sila hubungi pejabat latihan industri.',
                zh: '您的注册未获批准。请联系实习办公室。')
            : approval == 'suspended'
                ? _suspendedMessage()
                : tr('Your account is awaiting administrator approval. You can log in once it has been approved.',
                    ms: 'Akaun anda menunggu kelulusan pentadbir. Anda boleh log masuk selepas ia diluluskan.',
                    zh: '您的账户正在等待管理员批准，批准后即可登录。'));
      }

      await PushNotificationService.instance.linkUser(user.id);
      await _applySavedPreferences(user.id);
      final signedInRole = row['role'] as String;
      RoleController.instance.setRole(signedInRole);
      return UserRoleX.fromDbValue(signedInRole);
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
  // Confirming a new account with the code emailed at sign-up (no link to open,
  // so it works on any phone). The "Confirm signup" email template in the
  // Supabase dashboard must contain {{ .Token }} for the code to appear.
  // ---------------------------------------------------------------------

  /// Verifies the sign-up code. On success the person is signed in; staff
  /// accounts that still await administrator approval are signed straight back
  /// out. Returns the account's role either way.
  Future<UserRole> confirmSignupCode({required String email, required String code}) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: OtpType.signup,
      );
      final user = response.user;
      if (response.session == null || user == null) {
        throw const ResetCodeException('That code is not valid. Please request a new one.');
      }
      final row = await _client.from('profiles').select('role, approval_status').eq('profile_id', user.id).single();
      final role = row['role'] as String;
      if ((row['approval_status'] as String? ?? 'approved') != 'approved') {
        await _client.auth.signOut();
        return UserRoleX.fromDbValue(role);
      }
      await PushNotificationService.instance.linkUser(user.id);
      await _applySavedPreferences(user.id);
      RoleController.instance.setRole(role);
      return UserRoleX.fromDbValue(role);
    } on AuthException {
      throw const ResetCodeException('That code is incorrect or has expired. Check the email, or request a new code.');
    }
  }

  String _suspendedMessage() => tr('Your account has been suspended. Please contact the internship office.',
      ms: 'Akaun anda telah digantung. Sila hubungi pejabat latihan industri.',
      zh: '您的账户已被暂停。请联系实习办公室。');

  /// Language and theme are stored on the account, but the device only remembers
  /// the LAST choice made on it. Without this, logging in as somebody else kept
  /// the previous person's language while that person's own Settings page (which
  /// reads the account) showed another one, and a choice made by user B silently
  /// replaced user A's language the next time A logged in.
  Future<void> _applySavedPreferences(String userId) async {
    try {
      final row = await _client.from('profiles').select('language, theme_mode').eq('profile_id', userId).maybeSingle();
      final language = row?['language'] as String?;
      if (language != null && LocaleController.displayNameToCode.containsKey(language)) {
        await LocaleController.instance.setLanguageByDisplayName(language);
      }
      final themeMode = row?['theme_mode'] as String?;
      if (themeMode != null) {
        await ThemeController.instance.setThemeModeByCode(themeMode);
      }
    } catch (_) {
      // Cosmetic: never block a login because the preferences could not be read.
    }
  }

  /// True when this account still has the temporary password an administrator
  /// gave it, so the person must choose their own before using the app.
  Future<bool> mustChangePassword() async {
    final id = currentUserId;
    if (id == null) return false;
    try {
      final row = await _client.from('profiles').select('must_change_password').eq('profile_id', id).maybeSingle();
      return row?['must_change_password'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Saves the new password chosen at the first login and clears the flag.
  Future<void> completeFirstPasswordChange(String newPassword) async {
    final rule = Validators.password(newPassword);
    if (rule != null) throw ResetCodeException(rule);
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('different from the old password')) {
        throw const ResetCodeException('Choose a password that is different from the temporary one.');
      }
      throw const ResetCodeException('Could not save the new password. Please try again.');
    }
    await _client.rpc('clear_must_change_password');
  }

  Future<void> resendSignupCode(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email.trim());
    } on AuthException catch (e) {
      final text = '${e.code ?? ''} ${e.message}'.toLowerCase();
      if (e.statusCode == '429' || text.contains('rate') || text.contains('seconds')) {
        throw const ResetCodeException('Please wait a minute before asking for another code.');
      }
      if (text.contains('sending') || text.contains('smtp')) {
        throw const ResetCodeException('We could not send the email right now. Please try again later.');
      }
      throw const ResetCodeException('Could not send a new code. Please try again.');
    }
  }

  // ---------------------------------------------------------------------
  // Forgot password, in three steps typed into the app (no email link, so it
  // works on any phone):
  //   1. requestPasswordResetCode  -> Supabase emails a numeric code
  //   2. verifyPasswordResetCode   -> the code is exchanged for a short session
  //   3. completePasswordReset     -> new password saved, session ended
  //
  // Step 1 never says whether the email has an account (Supabase answers the
  // same either way), so the screen words its confirmation neutrally. The
  // "Reset Password" email template in the Supabase dashboard must contain
  // {{ .Token }} for the code to appear in the email.
  // ---------------------------------------------------------------------
  Future<void> requestPasswordResetCode(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      final text = '${e.code ?? ''} ${e.message}'.toLowerCase();
      if (e.statusCode == '429' || text.contains('rate') || text.contains('seconds')) {
        throw const ResetCodeException('Please wait a minute before asking for another code.');
      }
      if (text.contains('sending') || text.contains('smtp') || text.contains('not authorized')) {
        throw const ResetCodeException(
            'We could not send the email right now. Please try again later or contact the internship office.');
      }
      throw const ResetCodeException('Could not request a code. Please try again.');
    }
  }

  Future<void> verifyPasswordResetCode({required String email, required String code}) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: OtpType.recovery,
      );
      if (response.session == null) {
        throw const ResetCodeException('That code is not valid. Please request a new one.');
      }
    } on AuthException {
      throw const ResetCodeException(
          'That code is incorrect or has expired. Check the email, or request a new code.');
    }
  }

  /// Saves the new password and ends the temporary session, so the person
  /// logs in normally afterwards.
  Future<void> completePasswordReset(String newPassword) async {
    final rule = Validators.password(newPassword);
    if (rule != null) throw ResetCodeException(rule);
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('different from the old password')) {
        throw const ResetCodeException('Choose a password you have not used before.');
      }
      throw const ResetCodeException('Could not save the new password. Please try again.');
    }
    await _client.auth.signOut();
  }

  /// Leaves the reset flow without finishing: drops the temporary session.
  Future<void> cancelPasswordReset() async {
    if (_client.auth.currentSession != null) {
      await _client.auth.signOut();
    }
  }

  // ---------------------------------------------------------------------
  // Log out — clears the current Supabase session.
  // ---------------------------------------------------------------------
  Future<void> signOut() async {
    await PushNotificationService.instance.unlinkUser();
    await _client.auth.signOut();
    RoleController.instance.setRole(null);
  }

  // ---------------------------------------------------------------------
  // Delete my account. Reports, evaluations and messages from other people
  // depend on this profile, so the account is anonymised rather than hard
  // deleted (see anonymise_my_account in migration 00024): personal details
  // are wiped, login is blocked and sessions end. The resume file and avatar
  // are removed from Storage first, since the database function cannot
  // delete storage objects.
  // ---------------------------------------------------------------------
  Future<void> deleteMyAccount() async {
    if (currentUserId == null) {
      throw Exception('You must be logged in.');
    }
    try {
      await removeResume();
    } catch (_) {
      // Nothing to remove, or already gone — keep going.
    }
    try {
      await removeAvatar();
    } catch (_) {}

    await _client.rpc('anonymise_my_account');

    try {
      await PushNotificationService.instance.unlinkUser();
    } catch (_) {}
    // The database function has already deleted every session of this account,
    // so the server answers the sign-out with "session not found" (403) and the
    // client throws. The device's own session is removed before that call is
    // made, so the error carries no information: the account IS deleted. Showing
    // it as a red failure message was wrong.
    try {
      await _client.auth.signOut();
    } catch (_) {}
    RoleController.instance.setRole(null);
  }
}

/// Sign-up was attempted with an email that already has an account. A type of
/// its own so the sign-up screen can show a dialog offering to log in or reset
/// the password, instead of a plain error line.
class AccountAlreadyExistsException implements Exception {
  final String email;
  const AccountAlreadyExistsException(this.email);

  @override
  String toString() => 'An account with $email already exists.';
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

enum AuthFieldTarget { credentials, email, password, account, unconfirmed }

/// The current password typed in "Change password" was wrong. A type of its
/// own so the dialog can show it under that exact field.
class WrongCurrentPasswordException implements Exception {
  const WrongCurrentPasswordException();

  String get message => 'Your current password is incorrect.';

  @override
  String toString() => message;
}

/// A problem in the forgot-password flow, with a message that is already
/// written for the person (shown as-is).
class ResetCodeException implements Exception {
  final String message;
  const ResetCodeException(this.message);

  @override
  String toString() => message;
}