import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/common/validated_field.dart';
import 'forgot_password_screen.dart';
import 'confirm_email_screen.dart';
import 'force_password_change_screen.dart';
import 'student_shell.dart';
import 'admin_shell.dart';
import 'supervisor_shell.dart';
import 'hr_shell.dart';
import 'company_supervisor_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  // Answer from the server after pressing Log in. Supabase deliberately does
  // not say whether the email or the password was wrong, so it is shown under
  // the password field. (The email itself is checked live while typing.)
  String? _passwordError;
  String? _emailError;
  // General account-level issues that aren't tied to a specific field
  // (e.g. missing profile data) — shown as a banner above the button.
  String? _generalError;

  void _clearErrors() {
    _passwordError = null;
    _emailError = null;
    _generalError = null;
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(_clearErrors);

    // Shows the live rules' message on any field that is still empty or
    // invalid, so nothing is sent to the server until both look right.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final role = await AuthService.instance.logIn(
        email: email,
        password: password,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      _routeToShellByRole(role);
    } on AuthFieldException catch (e) {
      if (!mounted) return;
      if (e.target == AuthFieldTarget.unconfirmed) {
        setState(() => _isLoading = false);
        await _confirmEmail(email);
        return;
      }
      setState(() {
        _isLoading = false;
        if (e.target == AuthFieldTarget.email) {
          _emailError = e.message;
        } else if (e.target == AuthFieldTarget.password || e.target == AuthFieldTarget.credentials) {
          // `credentials` is only used when the database could not say which of
          // the two was wrong; it shows under the password field.
          _passwordError = e.message;
        } else {
          _generalError = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generalError = AppLocalizations.of(context)!.errorSomethingWrong;
      });
    }
  }

  /// The account exists but its email was never confirmed: send a fresh code
  /// and let the person type it in, then carry on into the app.
  Future<void> _confirmEmail(String email) async {
    final role = await Navigator.of(context).push<UserRole>(
      MaterialPageRoute(builder: (_) => ConfirmEmailScreen(email: email, sendCodeOnOpen: true)),
    );
    if (!mounted || role == null) return;
    final staff = role == UserRole.academicSupervisor || role == UserRole.companySupervisor;
    if (staff) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text(AppLocalizations.of(context)!.suEmailConfirmedPending),
        ),
      );
      return;
    }
    _routeToShellByRole(role);
  }

  Future<void> _handleForgotPassword() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loPasswordChanged),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _routeToShellByRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        _routeToShell(destination: const StudentShell());
        break;
      case UserRole.academicSupervisor:
        _routeToShell(destination: const SupervisorShell());
        break;
      case UserRole.companyHr:
        _routeToShell(destination: const HrShell());
        break;
      case UserRole.companySupervisor:
        _routeToShell(destination: const CompanySupervisorShell());
        break;
      case UserRole.admin:
        _routeToShell(destination: const AdminShell());
        break;
    }
  }

  void _routeToShell({required Widget destination}) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PasswordChangeGate(child: destination),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // Full CIMS logo lockup
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
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.welcomeToCims,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                l10n.cimsFullName,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // General (non-field) error banner
              if (_generalError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _generalError!,
                          style: TextStyle(
                              fontFamily: 'Inter', fontSize: 12, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email field — checked live while typing
                    Text(l10n.emailAddress, style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    ValidatedField(
                      controller: _emailController,
                      fieldValidator: (v) => v.trim().isEmpty ? l10n.errorEnterEmail : Validators.emailFormat(v),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      hintText: l10n.enterYourEmail,
                      externalError: _emailError,
                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
                      onChanged: (_) {
                        if (_passwordError != null || _emailError != null) {
                          setState(() {
                            _passwordError = null;
                            _emailError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password field — only the server can say if it is wrong
                    Text(l10n.password, style: AppTextStyles.label),
                    const SizedBox(height: 6),
                    ValidatedField(
                      controller: _passwordController,
                      fieldValidator: (v) => v.isEmpty ? l10n.errorEnterPassword : null,
                      obscureText: _obscurePassword,
                      showSuccess: false,
                      textInputAction: TextInputAction.done,
                      hintText: l10n.enterYourPassword,
                      externalError: _passwordError,
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
                        if (_passwordError != null) setState(() => _passwordError = null);
                      },
                      onSubmitted: (_) => _isLoading ? null : _handleLogin(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  child: Text(l10n.forgotPassword,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.primary)),
                ),
              ),

              const SizedBox(height: 16),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : Text(l10n.logIn,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 16),

              // Sign up link
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SignUpScreen()),
                ),
                child: Text(
                  l10n.noAccountSignUp,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 24),

              // Footer
              Text(l10n.footerCopyright,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textMuted)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}