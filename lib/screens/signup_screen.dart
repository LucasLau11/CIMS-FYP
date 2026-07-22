import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'student_shell.dart';
import 'supervisor_shell.dart';
import 'hr_shell.dart';
import 'company_supervisor_shell.dart';
import 'parent_shell.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorText;

  UserRole? _selectedManualRole;

  bool get _needsManualRole =>
      _emailController.text.trim().isNotEmpty &&
          AuthService.instance.needsManualRoleSelection(_emailController.text);

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorText = 'Please fill in all fields.');
      return;
    }

    final emailError = AuthService.instance.validateEmail(email);
    if (emailError != null) {
      setState(() => _errorText = emailError);
      return;
    }

    final passwordError = AuthService.instance.validatePassword(password);
    if (passwordError != null) {
      setState(() => _errorText = passwordError);
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorText = 'Passwords do not match.');
      return;
    }

    if (_needsManualRole && _selectedManualRole == null) {
      setState(() => _errorText = 'Please select your role to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final role = await AuthService.instance.signUp(
        email: email,
        password: password,
        manualRole: _selectedManualRole,
      );

      if (!mounted) return;
      _routeToShell(role);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
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
      case UserRole.parent:
        destination = const ParentShell();
        break;
    }

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
              const Text(
                'Create your CIMS account',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Student/staff emails are assigned a role automatically.\n'
                    'Gmail, Outlook, or Hotmail addresses will be asked to pick a role below.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Email address', style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {
                  _errorText = null;
                  _selectedManualRole = null;
                }),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined,
                      size: 20, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 14),

              // Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Password', style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Create a password',
                  prefixIcon: const Icon(Icons.lock_outline,
                      size: 20, color: AppColors.textMuted),
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
              const SizedBox(height: 14),

              // Confirm password
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Confirm password', style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_outline,
                      size: 20, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
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
                      const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 15, color: AppColors.warning),
                          SizedBox(width: 6),
                          Text('Select your role',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your email is not a TARC institutional address. Please select the role that applies to you.',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.warning),
                      ),
                      const SizedBox(height: 12),
                      _RoleTile(
                        label: 'Parent/Guardian',
                        icon: Icons.family_restroom_outlined,
                        selected: _selectedManualRole == UserRole.parent,
                        onTap: () =>
                            setState(() => _selectedManualRole = UserRole.parent),
                      ),
                      _RoleTile(
                        label: 'HR Personnel',
                        icon: Icons.badge_outlined,
                        selected: _selectedManualRole == UserRole.companyHr,
                        onTap: () => setState(
                                () => _selectedManualRole = UserRole.companyHr),
                      ),
                      _RoleTile(
                        label: 'Company Supervisor',
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

              if (_errorText != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorText!,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

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
                      : const Text('Sign up',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 16),

              // Back to login
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                ),
                child: const Text(
                  'Already have an account? Log in',
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
          color: selected ? AppColors.infoBg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
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