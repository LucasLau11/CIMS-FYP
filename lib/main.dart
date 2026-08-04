import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/locale_controller.dart';
import 'services/theme_controller.dart';
import 'services/push_notification_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the last-used language immediately (from local storage) so the
  // correct locale shows on the very first frame, before any network call.
  await LocaleController.instance.loadSavedLocale();

  // Same idea for the last-used theme mode (Light/Dark/System).
  await ThemeController.instance.loadSavedThemeMode();

  // Initialize Supabase — anon/publishable key is safe to embed client-side,
  // access is restricted by Row Level Security policies on the database.
  //
  // Wrapped with a timeout: without this, a silent network issue (e.g. a
  // firewall dropping packets instead of refusing the connection) leaves
  // the app hanging forever on the splash screen with zero error output —
  // this makes that failure visible instead.
  try {
    await Supabase.initialize(
      url: 'https://lgosyvuwtkzrjvsbxyed.supabase.co',
      anonKey: 'sb_publishable_TP11aOfbEEX48NSNipqkUA_r2adm96C',
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    // Log clearly to the console so this shows up in Logcat/Run output
    // instead of the app just silently sitting on the splash screen.
    debugPrint('❌ Supabase.initialize() failed or timed out: $e');
  }

  PushNotificationService.instance.initialize();

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

class CimsApp extends StatefulWidget {
  const CimsApp({super.key});

  @override
  State<CimsApp> createState() => _CimsAppState();
}

class _CimsAppState extends State<CimsApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Only matters while following "System" — a user-picked Light/Dark
  // doesn't need the device's brightness at all, but rebuilding here is
  // harmless in that case since applyBrightness() just resolves to the
  // same fixed value again.
  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app instantly whenever the language or theme is
    // changed (see LocaleController/ThemeController + AuthService) — no
    // restart needed.
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.instance.currentLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.instance.themeMode,
          builder: (context, mode, _) {
            ThemeController.instance.applyBrightness(
              WidgetsBinding.instance.platformDispatcher.platformBrightness,
            );
            return MaterialApp(
              navigatorKey: PushNotificationService.instance.navigatorKey,
              title: 'CIMS',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.theme,
              home: const SplashScreen(),
              locale: locale,
              supportedLocales: const [
                Locale('en'),
                Locale('ms'),
                Locale('zh'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

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
              // Admin is a real Supabase account too (role='admin'), just
              // never offered on the sign-up screen — there's only meant
              // to be one, provisioned directly in the database.
            );
          },
        );
      },
    );
  }
}