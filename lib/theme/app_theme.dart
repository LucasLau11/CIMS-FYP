import 'package:flutter/material.dart';

/// Colors used everywhere via direct static access (`AppColors.xxx`) rather
/// than `Theme.of(context)`, so dark-mode support is implemented by making
/// these fields brightness-aware getters instead of `const` values — see
/// `ThemeController.applyBrightness`, called from `main.dart` any time the
/// theme mode or platform brightness changes. Fields are still accessed the
/// exact same way (`AppColors.textPrimary` etc.); only their declaration
/// changed, so every call site keeps working — they just can no longer be
/// used in `const` expressions (the compiler flags every spot that needs
/// its `const` removed).
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.light;
  static bool get _dark => _brightness == Brightness.dark;

  /// The brightness every getter below currently resolves against.
  static Brightness get currentBrightness => _brightness;

  /// Called by `ThemeController` whenever the effective theme changes.
  static void setBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  // Primary teal-aquamarine palette — brand colors, used on saturated
  // gradient banners/accents rather than raw backgrounds, so they read fine
  // in both light and dark mode and don't need dark variants.
  static const Color primary = Color(0xFF0F7E8A);
  static const Color primaryLight = Color(0xFF14B8C8);
  static const Color primaryDark = Color(0xFF0A5F69);
  static const Color accent = Color(0xFFA8EDEA);
  static const Color accentDark = Color(0xFF5CD6D0);
  static const Color cardAccent = Color(0xFF14B8C8);

  // Backgrounds
  static Color get background => _dark ? _backgroundDark : _backgroundLight;
  static Color get surface => _dark ? _surfaceDark : _surfaceLight;
  static Color get surfaceVariant => _dark ? _surfaceVariantDark : _surfaceVariantLight;

  static const Color _backgroundLight = Color(0xFFF0FAFB);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _surfaceVariantLight = Color(0xFFE8F6F7);

  static const Color _backgroundDark = Color(0xFF0A1A1C);
  static const Color _surfaceDark = Color(0xFF10262A);
  static const Color _surfaceVariantDark = Color(0xFF163338);

  // Text
  static Color get textPrimary => _dark ? _textPrimaryDark : _textPrimaryLight;
  static Color get textSecondary => _dark ? _textSecondaryDark : _textSecondaryLight;
  static Color get textMuted => _dark ? _textMutedDark : _textMutedLight;

  static const Color _textPrimaryLight = Color(0xFF0D2B2E);
  static const Color _textSecondaryLight = Color(0xFF4A7C80);
  static const Color _textMutedLight = Color(0xFF8AACAF);

  static const Color _textPrimaryDark = Color(0xFFE8F6F7);
  static const Color _textSecondaryDark = Color(0xFFA9C8CB);
  static const Color _textMutedDark = Color(0xFF6E9296);

  // Status
  static Color get success => _dark ? _successDark : _successLight;
  static Color get successBg => _dark ? _successBgDark : _successBgLight;
  static Color get warning => _dark ? _warningDark : _warningLight;
  static Color get warningBg => _dark ? _warningBgDark : _warningBgLight;
  static Color get error => _dark ? _errorDark : _errorLight;
  static Color get errorBg => _dark ? _errorBgDark : _errorBgLight;
  static Color get info => _dark ? _infoDark : _infoLight;
  static Color get infoBg => _dark ? _infoBgDark : _infoBgLight;

  static const Color _successLight = Color(0xFF1A9E6E);
  static const Color _successBgLight = Color(0xFFE2F6EF);
  static const Color _warningLight = Color(0xFFD97706);
  static const Color _warningBgLight = Color(0xFFFEF3C7);
  static const Color _errorLight = Color(0xFFD94F4F);
  static const Color _errorBgLight = Color(0xFFFDEEEE);
  static const Color _infoLight = Color(0xFF0F7E8A);
  static const Color _infoBgLight = Color(0xFFE0F4F5);

  static const Color _successDark = Color(0xFF4ADE9A);
  static const Color _successBgDark = Color(0xFF163D2E);
  static const Color _warningDark = Color(0xFFF2B84B);
  static const Color _warningBgDark = Color(0xFF3D2E10);
  static const Color _errorDark = Color(0xFFF08787);
  static const Color _errorBgDark = Color(0xFF3D1F1F);
  static const Color _infoDark = Color(0xFF4DD8E0);
  static const Color _infoBgDark = Color(0xFF12363B);

  // Border
  static Color get border => _dark ? _borderDark : _borderLight;
  static Color get borderStrong => _dark ? _borderStrongDark : _borderStrongLight;

  static const Color _borderLight = Color(0xFFD0EAEC);
  static const Color _borderStrongLight = Color(0xFF9DCFD3);

  static const Color _borderDark = Color(0xFF20444A);
  static const Color _borderStrongDark = Color(0xFF2C5960);
}

class AppTheme {
  /// The single active `ThemeData`, matching whatever brightness
  /// `AppColors` currently resolves against. There's deliberately no
  /// separate `lightTheme`/`darkTheme` pair handed to `MaterialApp` — since
  /// `AppColors` is one mutable global flag (not two independent palettes),
  /// two static `ThemeData` getters would both end up reading whichever
  /// brightness happens to be active, making them identical rather than
  /// independent. Instead `main.dart` resolves the effective brightness
  /// itself (from `ThemeMode` + platform brightness), calls
  /// `ThemeController.applyBrightness()`, then reads this getter.
  static ThemeData get theme => _buildTheme(AppColors.currentBrightness);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Inter',
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: AppColors.primaryLight,
              secondary: AppColors.primaryLight,
              surface: AppColors.surface,
              error: AppColors.error,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: AppColors.textPrimary,
            )
          : ColorScheme.light(
              primary: AppColors.primary,
              secondary: AppColors.primaryLight,
              surface: AppColors.surface,
              error: AppColors.error,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.accent,
        labelStyle: const TextStyle(fontSize: 12, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: AppColors.border),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
    );
  }
}

// Shared text styles using Poppins for headings, Inter for body.
// Getters (not `const`) because color depends on the current AppColors
// brightness — see the comment atop AppColors.
class AppTextStyles {
  static TextStyle get h1 => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get h2 => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get h3 => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySecondary => TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static TextStyle get label => TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}
