import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'admin_shell.dart';
import 'student_shell.dart';
import 'supervisor_shell.dart';
import 'hr_shell.dart';
import 'company_supervisor_shell.dart';
import 'parent_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Check for a restored session (real Supabase session, or remembered
    // admin login) after the splash animation, then route accordingly —
    // this is what makes login persist across app restarts (problem 9).
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;
      debugPrint('🔵 Splash: checking for restored session...');

      Widget destination;
      try {
        final restored = await AuthService.instance
            .checkForRestoredSession()
            .timeout(const Duration(seconds: 8));
        debugPrint('🔵 Splash: session check returned: '
            '${restored == null ? 'null (go to Login)' : restored.isAdmin ? 'admin' : restored.role}');

        if (restored == null) {
          destination = const LoginScreen();
        } else if (restored.isAdmin) {
          destination = const AdminShell();
        } else {
          switch (restored.role!) {
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
        }
      } catch (e) {
        // Any unexpected error (including a timeout) checking the session —
        // fail safe to Login rather than getting stuck on the splash screen.
        debugPrint('🔴 Splash: session check failed or timed out: $e');
        destination = const LoginScreen();
      }

      debugPrint('🔵 Splash: navigating to $destination');

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // White card behind logo for contrast
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/cims_logo.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        AppLocalizations.of(context)!.tarumt,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context)!.splashTagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                        AlwaysStoppedAnimation(Colors.white.withOpacity(0.7)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppLocalizations.of(context)!.loading,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}