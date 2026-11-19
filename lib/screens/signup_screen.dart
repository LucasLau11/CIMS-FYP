import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../l10n/app_localizations.dart';
import '../utils/lang.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../utils/error_text.dart';
import '../utils/validators.dart';
import '../widgets/common/validated_field.dart';
import 'privacy_policy_screen.dart';
import 'student_shell.dart';
import 'supervisor_shell.dart';
import 'hr_shell.dart';
import 'company_supervisor_shell.dart';
import 'login_screen.dart';
import 'confirm_email_screen.dart';
import 'forgot_password_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptedPrivacy = false;
  final _formKey = GlobalKey<FormState>();
  String? _errorText;

  UserRole? _selectedManualRole;

  /// Supervisor accounts must be approved by an administrator before they can log in (migration
  /// 00023). A company HR account can log in straight away: its COMPANY is what gets verified
  /// (documents, migration 00044) and until then it cannot post internships.
  bool _isStaffRole(UserRole role) =>
      role == UserRole.academicSupervisor ||
      role == UserRole.companySupervisor;

  bool get _needsManualRole =>
      _emailController.text.trim().isNotEmpty &&
          AuthService.instance.needsManualRoleSelection(_emailController.text);

  bool get _needsName =>
      _selectedManualRole == UserRole.companyHr || _selectedManualRole == UserRole.companySupervisor;

  Future<void> _handleSignUp() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Every field's live rule runs at once and shows its message under the
    // field; the role choice and the privacy tick are reported together with
    // them so nothing is found one at a time.
    final fieldsOk = _formKey.currentState?.validate() ?? false;
    String? summary;
    if (_needsManualRole && _selectedManualRole == null) {
      summary = l10n.errorSelectRole;
    } else if (!_acceptedPrivacy) {
      summary = l10n.suPrivacyRequired;
    }
    if (!fieldsOk || summary != null) {
      setState(() => _errorText = summary);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final result = await AuthService.instance.signUp(
        email: email,
        password: password,
        manualRole: _selectedManualRole,
        fullName: _nameController.text,
      );

      // Staff accounts start "pending": whether or not there is a session,
      // they cannot use the app until an administrator approves them, so
      // never route them into a shell. Make sure no session is left behind.
      if (_isStaffRole(result.role) && !result.needsEmailConfirmation) {
        await AuthService.instance.signOut();
        if (!mounted) return;
        setState(() => _isLoading = false);
        _goToLogin();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 8),
            content: Text(AppLocalizations.of(context)!.suPendingApproval),
          ),
        );
        return;
      }

      // With Supabase Auth's "Confirm email" setting on, sign-up doesn't
      // produce an active session. The person types the code from the email
      // right here instead of opening a link, then carries on.
      if (result.needsEmailConfirmation) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        final confirmedRole = await Navigator.of(context).push<UserRole>(
          MaterialPageRoute(builder: (_) => ConfirmEmailScreen(email: email)),
        );
        if (!mounted) return;
        if (confirmedRole == null) {
          // Backed out before confirming the email: the sign-up is not finished, so there is no account to
          // log in to. Start again from this form.
          setState(() => _errorText = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 8),
              content: Text(tr('Sign-up was not completed, so no account was created. Fill in the form again to start over.',
                  ms: 'Pendaftaran tidak diselesaikan, jadi tiada akaun dicipta. Isi borang semula untuk bermula semula.',
                  zh: '注册未完成，因此没有创建账户。请重新填写表格再试一次。')),
            ),
          );
          return;
        }
        if (_isStaffRole(confirmedRole)) {
          _goToLogin();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 8),
              content: Text(AppLocalizations.of(context)!.suEmailConfirmedPending),
            ),
          );
          return;
        }
        _routeToShell(confirmedRole);
        return;
      }

      if (!mounted) return;
      _routeToShell(result.role);
    } on AccountAlreadyExistsException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _showAccountExistsDialog(e.email);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Auth errors (weak password, rate limit…) are written for users;
        // everything else goes through friendlyError.
        _errorText = e is AuthException ? e.message : friendlyError(e);
      });
    }
  }

  /// Supabase sends no email for an address that already has an account, so
  /// without this the person would wait for a code that never arrives.
  Future<void> _showAccountExistsDialog(String email) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.person_pin_outlined, size: 36, color: AppColors.primaryText),
        title: Text(AppLocalizations.of(context)!.suExistsTitle),
        content: Text(AppLocalizations.of(context)!.suExistsBody(email)),
        actionsOverflowAlignment: OverflowBarAlignment.end,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'close'), child: Text(AppLocalizations.of(context)!.close)),
          TextButton(onPressed: () => Navigator.pop(ctx, 'forgot'), child: Text(AppLocalizations.of(context)!.suForgotPassword)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'login'), child: Text(AppLocalizations.of(context)!.logIn)),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'login') {
      _goToLogin();
    } else if (choice == 'forgot') {
      await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: email)));
    }
  }

  /// Back to the log-in page. The sign-up page is opened on top of it, so
  /// going back just closes this page (the same as the back button or swipe);
  /// if there is nothing underneath, open a fresh log-in page instead.
  void _goToLogin() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    } else {
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _routeToShell(UserRole role) {
    Widget destination;
    switch (role) {
      case UserRole.student:
        destination = const StudentShell();
        break;
      case UserRole.academicSupervisor:
        destination = const SupervisorShell();
        break;
      case UserRole.companyHr:
        destination = const HrShell();
        break;
      case UserRole.companySupervisor:
        destination = const CompanySupervisorShell();
        break;
      case UserRole.admin:
        // Unreachable — sign-up never offers/assigns the admin role.
        throw StateError('Sign-up cannot produce an admin account.');
    }

    // Drop the log-in page underneath too, so back never returns to it.
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/cims_logo.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.createYourAccount,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.signupRoleNote,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Email — checked live, including the allowed domains
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.emailAddress, style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              ValidatedField(
                controller: _emailController,
                // Students do not sign themselves up: an administrator creates their account.
                fieldValidator: (v) =>
                    Validators.email(v) ??
                    (AuthService.instance.roleFromEmailDomain(v) == UserRole.student
                        ? AppLocalizations.of(context)!.suStudentsCreatedByAdmin
                        : null),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                hintText: l10n.enterYourEmail,
                prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
                onChanged: (_) => setState(() {
                  _errorText = null;
                  _selectedManualRole = null;
                }),
              ),
              const SizedBox(height: 14),

              // Password — rules tick off live below the field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.password, style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              ValidatedField(
                controller: _passwordController,
                fieldValidator: (v) => Validators.password(v),
                obscureText: _obscurePassword,
                showSuccess: false,
                textInputAction: TextInputAction.next,
                hintText: l10n.createAPassword,
                prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                  // The confirmation depends on this field.
                  if (_confirmPasswordController.text.isNotEmpty) _formKey.currentState?.validate();
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: PasswordChecklist(controller: _passwordController),
              ),
              const SizedBox(height: 14),

              // Confirm password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.confirmPassword, style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              ValidatedField(
                controller: _confirmPasswordController,
                fieldValidator: (v) => v.isEmpty
                    ? l10n.reEnterYourPassword
                    : (v != _passwordController.text ? l10n.errorPasswordsDoNotMatch : null),
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.next,
                hintText: l10n.reEnterYourPassword,
                prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
              ),

              // Manual role picker — only for non-institutional emails
              if (_needsManualRole) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(10),
                    border:
                    Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 15, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(l10n.selectYourRole,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.notInstitutionalEmailNote,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.warning),
                      ),
                      const SizedBox(height: 12),
                      _RoleTile(
                        label: l10n.hrPersonnel,
                        icon: Icons.badge_outlined,
                        selected: _selectedManualRole == UserRole.companyHr,
                        onTap: () => setState(
                                () => _selectedManualRole = UserRole.companyHr),
                      ),
                      _RoleTile(
                        label: l10n.companySupervisor,
                        icon: Icons.supervisor_account_outlined,
                        selected:
                        _selectedManualRole == UserRole.companySupervisor,
                        onTap: () => setState(() =>
                        _selectedManualRole = UserRole.companySupervisor),
                      ),
                    ],
                  ),
                ),
              ],

              if (_needsName) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(AppLocalizations.of(context)!.acFullName, style: AppTextStyles.label),
                ),
                const SizedBox(height: 6),
                ValidatedField(
                  controller: _nameController,
                  fieldValidator: (v) => Validators.fullName(v),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  hintText: AppLocalizations.of(context)!.suFullNameHint,
                  prefixIcon: Icon(Icons.person_outline, size: 20, color: AppColors.textMuted),
                  onChanged: (_) => setState(() => _errorText = null),
                ),
              ],

              if (_errorText != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorText!,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 16),

              // Privacy consent
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _acceptedPrivacy,
                      onChanged: _isLoading
                          ? null
                          : (v) => setState(() {
                                _acceptedPrivacy = v ?? false;
                                _errorText = null;
                              }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Wrap(
                        children: [
                          Text(AppLocalizations.of(context)!.suAgreePrefix,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                            ),
                            child: Text(AppLocalizations.of(context)!.suPrivacyNotice,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline)),
                          ),
                          Text('.',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : Text(l10n.signUp,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 16),

              // Back to login
              TextButton(
                onPressed: _isLoading
                    ? null
                    : _goToLogin,
                child: Text(
                  l10n.alreadyHaveAccountLogIn,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.infoBg : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primaryText : AppColors.borderStrong,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary)),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}