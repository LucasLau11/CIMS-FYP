import 'package:supabase_flutter/supabase_flutter.dart';

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
  // Log out — clears the current Supabase session.
  // ---------------------------------------------------------------------
  Future<void> signOut() async {
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