import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
      // and role-based routing in LoginScreen._routeUser()
      //
      // Role routing summary:
      // @student.tarumt.edu.my  → StudentShell
      // @tarc.edu.my (admin list) → AdminShell
      // @tarc.edu.my (not in list) → SupervisorShell
      // Other + HR role       → HrShell
      // Other + CompSup role  → CompanySupervisorShell
      // Other + Parent role   → ParentShell
      //
      // TODO: Replace hardcoded admin email list in login_screen.dart
      // with a Firebase/REST API call against the admin table when
      // backend is connected.
    );
  }
}
