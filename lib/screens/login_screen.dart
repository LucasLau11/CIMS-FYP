import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'student_shell.dart';
import 'admin_shell.dart';
import 'supervisor_shell.dart';
import 'hr_shell.dart';
import 'company_supervisor_shell.dart';
import 'parent_shell.dart';

// Hardcoded admin email list
// TODO: Replace with actual database query against admin table
const List<String> _adminEmails = [
  'admin@tarc.edu.my',
  'registrar@tarc.edu.my',
  'itadmin@tarc.edu.my',
];

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
  String? _emailError;

  // Tracks whether this is a company-domain email needing role picker
  bool get _isCompanyEmail {
    final email = _emailController.text.trim().toLowerCase();
    return email.isNotEmpty &&
        !email.endsWith('@student.tarumt.edu.my') &&
        !email.endsWith('@tarc.edu.my');
  }

  String? _selectedCompanyRole;

  void _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      setState(() => _emailError = 'Please enter your email and password.');
      return;
    }

    // If company email but no role selected yet, show picker
    if (_isCompanyEmail && _selectedCompanyRole == null) {
      setState(() => _emailError = 'Please select your role to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() => _isLoading = false);

    // Route based on email domain + role logic
    _routeUser(email);
  }

  void _routeUser(String email) {
    Widget destination;

    if (email.endsWith('@student.tarumt.edu.my')) {
      // Student
      destination = const StudentShell();
    } else if (email.endsWith('@tarc.edu.my')) {
      // Check admin table (hardcoded for prototype)
      // TODO: Replace with actual DB query
      if (_adminEmails.contains(email)) {
        destination = const AdminShell();
      } else {
        destination = const SupervisorShell();
      }
    } else {
      // Company-side user — role was picked from the mini picker
      switch (_selectedCompanyRole) {
        case 'HR Personnel':
          destination = const HrShell();
          break;
        case 'Company Supervisor':
          destination = const CompanySupervisorShell();
          break;
        case 'Parent/Guardian':
          destination = const ParentShell();
          break;
        default:
          destination = const HrShell();
      }
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
              const Text(
                'Welcome to CIMS',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Centralised Internship Management System',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Email field
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Email address', style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {
                  _emailError = null;
                  _selectedCompanyRole = null;
                }),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined,
                      size: 20, color: AppColors.textMuted),
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 14),

              // Password field
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Password', style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
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
              const SizedBox(height: 8),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.primary)),
                ),
              ),

              // Company role picker — only shown for non-TARC/student emails
              if (_isCompanyEmail) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.4)),
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
                        'Your email is not a TARUMT address. Please select the role that applies to you.',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.warning),
                      ),
                      const SizedBox(height: 12),
                      ...['HR Personnel', 'Company Supervisor', 'Parent/Guardian']
                          .map((role) => _RoleTile(
                                label: role,
                                selected: _selectedCompanyRole == role,
                                onTap: () => setState(
                                    () => _selectedCompanyRole = role),
                              )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

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
                      : const Text('Log in',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 40),

              // Footer
              const Text('© 2026 TARUMT · CIMS v1.0',
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

class _RoleTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon {
    switch (label) {
      case 'HR Personnel': return Icons.badge_outlined;
      case 'Company Supervisor': return Icons.supervisor_account_outlined;
      default: return Icons.family_restroom_outlined;
    }
  }

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
            Icon(_icon,
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
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
