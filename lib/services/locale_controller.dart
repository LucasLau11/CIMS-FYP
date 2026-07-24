import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maps the display names shown in the language picker to actual locale
/// codes used by Flutter's localization system.
class LocaleController {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const Map<String, String> displayNameToCode = {
    'English': 'en',
    'Bahasa Malaysia': 'ms',
    '中文': 'zh',
  };

  static const Map<String, String> codeToDisplayName = {
    'en': 'English',
    'ms': 'Bahasa Malaysia',
    'zh': '中文',
  };

  static const String _prefsKey = 'cims_language_code';

  /// Notifies the whole app (via main.dart) to rebuild with a new locale.
  final ValueNotifier<Locale> currentLocale = ValueNotifier(const Locale('en'));

  /// Call once at app startup — reads the last-used language from local
  /// storage so the correct locale is shown immediately, before the
  /// network profile fetch (if any) completes.
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null) {
      currentLocale.value = Locale(code);
    }
  }

  /// Call whenever the user picks a language — updates the app instantly
  /// and remembers the choice locally for next launch.
  Future<void> setLanguageByDisplayName(String displayName) async {
    final code = displayNameToCode[displayName] ?? 'en';
    currentLocale.value = Locale(code);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }

  String get currentDisplayName => codeToDisplayName[currentLocale.value.languageCode] ?? 'English';
}