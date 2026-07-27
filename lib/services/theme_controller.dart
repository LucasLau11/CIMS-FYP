import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Mirrors `LocaleController` — instant app-wide theme switching, no
/// restart, persisted locally and (via AuthService.updateThemeMode) synced
/// to the user's profile.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const Map<String, ThemeMode> _codeToMode = {
    'light': ThemeMode.light,
    'dark': ThemeMode.dark,
    'system': ThemeMode.system,
  };
  static const Map<ThemeMode, String> _modeToCode = {
    ThemeMode.light: 'light',
    ThemeMode.dark: 'dark',
    ThemeMode.system: 'system',
  };

  static const String _prefsKey = 'cims_theme_mode';

  /// Notifies the whole app (via main.dart) to rebuild with a new theme.
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  /// Call once at app startup — reads the last-used theme mode from local
  /// storage so the correct theme is shown immediately, before the network
  /// profile fetch (if any) completes.
  Future<void> loadSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && _codeToMode.containsKey(code)) {
      themeMode.value = _codeToMode[code]!;
    }
  }

  /// Call whenever the user picks a theme — updates the app instantly and
  /// remembers the choice locally for next launch.
  Future<void> setThemeModeByCode(String code) async {
    final mode = _codeToMode[code] ?? ThemeMode.system;
    themeMode.value = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }

  String get currentCode => _modeToCode[themeMode.value] ?? 'system';

  /// Resolves `ThemeMode.system` against the current platform brightness so
  /// `AppColors` (read directly by hundreds of call sites, without
  /// `BuildContext`) always knows which palette to serve.
  void applyBrightness(Brightness platformBrightness) {
    final effective = switch (themeMode.value) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platformBrightness,
    };
    AppColors.setBrightness(effective);
  }
}
