import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'student_shell.dart';
import 'admin_shell.dart';
import 'supervisor_shell.dart';
import 'hr_shell.dart';
import 'company_supervisor_shell.dart';
import 'parent_shell.dart';
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

  // Per-field errors, shown directly under their respective inputs.
  String? _emailError;
  String? _passwordError;
  // General account-level issues that aren't tied to a specific field
  // (e.g. missing profile data) — shown as a banner above the button.
  String? _generalError;

  void _clearErrors() {
    _emailError = null;
    _passwordError = null;
    _generalError = null;
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(_clearErrors);

    bool hasError = false;
    if (email.isEmpty) {
      setState(() => _emailError = l10n.errorEnterEmail);
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = l10n.errorEnterPassword);
      hasError = true;
    }
    if (hasError) return;

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
      setState(() {
        _isLoading = false;
        if (e.target == AuthFieldTarget.credentials) {
          // Supabase doesn't tell us whether the email or the password was
          // wrong (security by design), so this shows under the password
          // field — the natural "final" field before submitting.
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

  Future<void> _handleForgotPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _emailController.text.trim());
    bool isSending = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.resetYourPassword,
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.resetPasswordInstructions,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: l10n.enterYourEmail,
                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                    final email = controller.text.trim();
                    if (email.isEmpty) return;

                    setDialogState(() => isSending = true);
                    await AuthService.instance.sendPasswordResetEmail(email);
                    if (!dialogContext.mounted) return;

                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.resetLinkSentMessage),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: isSending
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(l10n.sendResetLink),
                ),
              ],
            );
          },
        );
      },
    );
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
      case UserRole.parent:
        _routeToShell(destination: const ParentShell());
        break;
      case UserRole.admin:
        _routeToShell(destination: const AdminShell());
        break;
    }
  }

  void _routeToShell({required Widget destination}) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
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

              // Email field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.emailAddress, style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() => _emailError = null),
                decoration: InputDecoration(
                  hintText: l10n.enterYourEmail,
                  prefixIcon: Icon(Icons.email_outlined,
                      size: 20, color: AppColors.textMuted),
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 14),

              // Password field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.password, style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() => _passwordError = null),
                decoration: InputDecoration(
                  hintText: l10n.enterYourPassword,
                  prefixIcon: Icon(Icons.lock_outline,
                      size: 20, color: AppColors.textMuted),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  child: Text(l10n.forgotPassword,
                      style: const TextStyle(
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
                    : () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => const SignUpScreen()),
                ),
                child: Text(
                  l10n.noAccountSignUp,
                  style: const TextStyle(
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