import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase — anon/publishable key is safe to embed client-side,
  // access is restricted by Row Level Security policies on the database.
  await Supabase.initialize(
    url: 'https://aoyumcvaxrhkicapsxdi.supabase.co',
    anonKey: 'sb_publishable_mCsTo_Ja_zzlX6Z5WsQbZg_EjJLMYfQ',
  );

  // Lock to portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style — light icons on dark teal background
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const CimsApp());
}

class CimsApp extends StatelessWidget {
  const CimsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CIMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),

      // Named routes for potential deep-linking later
      // Currently all navigation is handled imperatively via Navigator.push
      //
      // Role assignment now happens ONCE at sign-up (see SignUpScreen +
      // AuthService), not at login. Login just authenticates via Supabase
      // and looks up the stored role from the `profiles` table.
      //
      // Sign-up role assignment summary:
      // @student.tarc.edu.my → Student        (automatic, by domain)
      // @tarc.edu.my         → AcademicSupervisor (automatic, by domain)
      // Any other email      → user manually picks: Parent/Guardian,
      //                         HR Personnel, or Company Supervisor
      //
      // Admin is a hardcoded demo account (see AuthService.isAdminLogin) —
      // it never goes through sign-up or Supabase at all.
    );
  }
}
