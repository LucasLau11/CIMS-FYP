import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WCAG contrast ratio of two opaque colours.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Moves [fg] lighter or darker (keeping its hue) until it has at least [min]
/// contrast against every colour in [bgs]. Colours that already pass are
/// returned unchanged.
Color ensureContrast(Color fg, List<Color> bgs, {required bool lighten, double min = 4.5}) {
  double worst(Color c) => bgs.map((b) => contrastRatio(c, b)).reduce(math.min);
  final hsl = HSLColor.fromColor(fg);
  var c = fg;
  var l = hsl.lightness;
  // A small margin so rounding can never leave a colour at 4.4999.
  for (var i = 0; i < 90 && worst(c) < min + 0.05; i++) {
    l = (lighten ? l + 0.01 : l - 0.01).clamp(0.0, 1.0);
    c = hsl.withLightness(l).toColor();
  }
  return c;
}

/// Same hue and saturation as [c], with the lightness that gives relative
/// luminance [target] (found by bisection).
Color colorAtLuminance(Color c, double target) {
  final hsl = HSLColor.fromColor(c);
  var lo = 0.0;
  var hi = 1.0;
  for (var i = 0; i < 24; i++) {
    final mid = (lo + hi) / 2;
    if (hsl.withLightness(mid).toColor().computeLuminance() < target) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return hsl.withLightness((lo + hi) / 2).toColor();
}

/// Soft white for secondary text on a coloured banner: 96% white, so it stays
/// readable on every role's banner colour (the old 70% white did not).
const Color kOnBannerSoft = Color(0xF5FFFFFF);

/// Every colour that changes with the signed-in role. HR (and the screens
/// before anyone has signed in) keep the original CIMS teal; each other role
/// gets its own brand colours, and the page, card, border and text neutrals
/// are tinted from that hue so a screen looks like it belongs to one family.
class RolePalette {
  const RolePalette._({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.accentDark,
    required this.backgroundLight,
    required this.surfaceVariantLight,
    required this.borderLight,
    required this.borderStrongLight,
    required this.textPrimaryLight,
    required this.textSecondaryLight,
    required this.textMutedLight,
    required this.infoLight,
    required this.infoBgLight,
    required this.backgroundDark,
    required this.surfaceDark,
    required this.surfaceVariantDark,
    required this.borderDark,
    required this.borderStrongDark,
    required this.textPrimaryDark,
    required this.textSecondaryDark,
    required this.textMutedDark,
    required this.infoDark,
    required this.infoBgDark,
  });

  final Color primary, primaryLight, primaryDark, accent, accentDark;
  final Color backgroundLight, surfaceVariantLight, borderLight, borderStrongLight;
  final Color textPrimaryLight, textSecondaryLight, textMutedLight, infoLight, infoBgLight;
  final Color backgroundDark, surfaceDark, surfaceVariantDark, borderDark, borderStrongDark;
  final Color textPrimaryDark, textSecondaryDark, textMutedDark, infoDark, infoBgDark;

  /// The original CIMS teal: company HR, and everything before sign-in.
  static final RolePalette brand = _brandRaw._readable(keepPrimary: true);

  static const RolePalette _brandRaw = RolePalette._(
    primary: Color(0xFF0F7E8A),
    primaryLight: Color(0xFF14B8C8),
    primaryDark: Color(0xFF0A5F69),
    accent: Color(0xFFA8EDEA),
    accentDark: Color(0xFF5CD6D0),
    backgroundLight: Color(0xFFF0FAFB),
    surfaceVariantLight: Color(0xFFE8F6F7),
    borderLight: Color(0xFFD0EAEC),
    borderStrongLight: Color(0xFF9DCFD3),
    textPrimaryLight: Color(0xFF0D2B2E),
    textSecondaryLight: Color(0xFF4A7C80),
    textMutedLight: Color(0xFF8AACAF),
    infoLight: Color(0xFF0F7E8A),
    infoBgLight: Color(0xFFE0F4F5),
    backgroundDark: Color(0xFF0A1A1C),
    surfaceDark: Color(0xFF10262A),
    surfaceVariantDark: Color(0xFF163338),
    borderDark: Color(0xFF20444A),
    borderStrongDark: Color(0xFF2C5960),
    textPrimaryDark: Color(0xFFE8F6F7),
    textSecondaryDark: Color(0xFFA9C8CB),
    textMutedDark: Color(0xFF6E9296),
    infoDark: Color(0xFF4DD8E0),
    infoBgDark: Color(0xFF12363B),
  );

  static Color _hsl(double hue, double saturation, double lightness) =>
      HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();

  /// A copy whose secondary text, muted text and info colour are pushed
  /// lighter/darker until they have at least 4.5:1 contrast against every
  /// background they are drawn on.
  RolePalette _readable({bool keepPrimary = false}) {
    final lightBgs = [backgroundLight, Colors.white, surfaceVariantLight];
    final darkBgs = [backgroundDark, surfaceDark, surfaceVariantDark];
    return RolePalette._(
      // White text sits on the brand colour (buttons, banners): darken it a touch if needed.
      primary: keepPrimary ? primary : ensureContrast(primary, const [Colors.white], lighten: false, min: 4.9),
      primaryLight: primaryLight,
      primaryDark: primaryDark,
      accent: accent,
      accentDark: accentDark,
      backgroundLight: backgroundLight,
      surfaceVariantLight: surfaceVariantLight,
      borderLight: borderLight,
      borderStrongLight: borderStrongLight,
      textPrimaryLight: ensureContrast(textPrimaryLight, lightBgs, lighten: false),
      textSecondaryLight: ensureContrast(textSecondaryLight, [infoBgLight, ...lightBgs], lighten: false),
      textMutedLight: ensureContrast(textMutedLight, [infoBgLight, ...lightBgs], lighten: false),
      infoLight: ensureContrast(infoLight, [infoBgLight, ...lightBgs], lighten: false),
      infoBgLight: infoBgLight,
      backgroundDark: backgroundDark,
      surfaceDark: surfaceDark,
      surfaceVariantDark: surfaceVariantDark,
      borderDark: borderDark,
      borderStrongDark: borderStrongDark,
      textPrimaryDark: ensureContrast(textPrimaryDark, darkBgs, lighten: true),
      textSecondaryDark: ensureContrast(textSecondaryDark, [infoBgDark, ...darkBgs], lighten: true),
      textMutedDark: ensureContrast(textMutedDark, [infoBgDark, ...darkBgs], lighten: true),
      infoDark: ensureContrast(infoDark, [infoBgDark, ...darkBgs], lighten: true),
      infoBgDark: infoBgDark,
    );
  }

  /// Builds a palette from five brand colours; the neutrals take the hue of
  /// [primary] so backgrounds, borders and text feel tinted towards it.
  factory RolePalette.fromBrand({
    required Color primary,
    required Color primaryLight,
    required Color primaryDark,
    required Color accent,
    required Color accentDark,
  }) {
    final h = HSLColor.fromColor(primary).hue;
    return RolePalette._(
      primary: primary,
      primaryLight: primaryLight,
      primaryDark: primaryDark,
      accent: accent,
      accentDark: accentDark,
      backgroundLight: _hsl(h, 0.50, 0.965),
      surfaceVariantLight: _hsl(h, 0.45, 0.93),
      borderLight: _hsl(h, 0.35, 0.87),
      borderStrongLight: _hsl(h, 0.30, 0.72),
      textPrimaryLight: _hsl(h, 0.45, 0.12),
      textSecondaryLight: _hsl(h, 0.25, 0.38),
      textMutedLight: _hsl(h, 0.15, 0.58),
      infoLight: primary,
      infoBgLight: _hsl(h, 0.55, 0.94),
      backgroundDark: _hsl(h, 0.40, 0.08),
      surfaceDark: _hsl(h, 0.35, 0.12),
      surfaceVariantDark: _hsl(h, 0.32, 0.17),
      borderDark: _hsl(h, 0.30, 0.23),
      borderStrongDark: _hsl(h, 0.28, 0.31),
      textPrimaryDark: _hsl(h, 0.40, 0.94),
      textSecondaryDark: _hsl(h, 0.20, 0.76),
      textMutedDark: _hsl(h, 0.12, 0.58),
      infoDark: _hsl(h, 0.60, 0.68),
      infoBgDark: _hsl(h, 0.35, 0.16),
    )._readable();
  }

  /// Student: royal blue of a school notebook, with a pencil-yellow accent.
  static final RolePalette student = RolePalette.fromBrand(
    primary: const Color(0xFF3B66DB),
    primaryLight: const Color(0xFF6C93F5),
    primaryDark: const Color(0xFF2848A8),
    accent: const Color(0xFFFFE08A),
    accentDark: const Color(0xFFF5C84A),
  );

  /// Academic supervisor: the plum of an academic gown.
  static final RolePalette academicSupervisor = RolePalette.fromBrand(
    primary: const Color(0xFF7C4BC4),
    primaryLight: const Color(0xFFA77DE8),
    primaryDark: const Color(0xFF5A3496),
    accent: const Color(0xFFE6D6FA),
    accentDark: const Color(0xFFC9A9F2),
  );

  /// Company supervisor: copper, the colour of the workplace and site.
  static final RolePalette companySupervisor = RolePalette.fromBrand(
    primary: const Color(0xFFC05F22),
    primaryLight: const Color(0xFFE88A4A),
    primaryDark: const Color(0xFF92440F),
    accent: const Color(0xFFFBD9BF),
    accentDark: const Color(0xFFF2B286),
  );

  /// Administrator: control-panel slate.
  static final RolePalette admin = RolePalette.fromBrand(
    primary: const Color(0xFF56688C),
    primaryLight: const Color(0xFF8499C2),
    primaryDark: const Color(0xFF3C4B69),
    accent: const Color(0xFFD3DCEE),
    accentDark: const Color(0xFFA8B7D6),
  );

  /// The palette for a `profiles.role` value; anything else (including
  /// `company_hr` and "nobody signed in") is the original teal.
  static RolePalette forRole(String? dbRole) {
    switch (dbRole) {
      case 'student':
        return student;
      case 'academic_supervisor':
        return academicSupervisor;
      case 'company_supervisor':
        return companySupervisor;
      case 'admin':
        return admin;
      default:
        return brand;
    }
  }
}

/// Colors used everywhere via direct static access (`AppColors.xxx`) rather
/// than `Theme.of(context)`, so dark-mode and role theming are implemented by
/// making these fields getters instead of `const` values — see
/// `ThemeController.applyBrightness` and `RoleController.setRole`, both called
/// from `main.dart`'s rebuild. Fields are accessed the exact same way
/// (`AppColors.textPrimary` etc.); they just can no longer be used in `const`
/// expressions.
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.light;
  static bool get _dark => _brightness == Brightness.dark;
  static RolePalette _palette = RolePalette.brand;

  /// The brightness every getter below currently resolves against.
  static Brightness get currentBrightness => _brightness;

  /// Called by `ThemeController` whenever the effective theme changes.
  static void setBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  /// The `profiles.role` the colours currently belong to (null before sign-in).
  static void setRole(String? dbRole) {
    _palette = RolePalette.forRole(dbRole);
  }

  // Brand colours — saturated, so they read fine in both light and dark mode.
  static Color get primary => _palette.primary;
  static Color get primaryLight => _palette.primaryLight;
  static Color get primaryDark => _palette.primaryDark;
  /// Fill for a selected chip. Light mode keeps the pastel accent; dark mode
  /// uses a deep tint of the brand hue, because a pastel under light text is
  /// unreadable.
  static Color get accent =>
      _dark ? RolePalette._hsl(HSLColor.fromColor(_palette.primary).hue, 0.45, 0.27) : _palette.accent;
  static Color get accentDark => _palette.accentDark;
  static Color get cardAccent => _palette.primaryLight;

  /// The banner colours behind white text: dark to mid, never the light shade,
  /// so white stays readable along the whole gradient.
  static List<Color> get headerGradient => [_palette.primaryDark, _palette.primary];

  static final Map<String, Color> _primaryTextCache = {};

  /// The brand colour for TEXT and icons drawn on page, card and tinted
  /// backgrounds: [primary] nudged lighter (dark mode) or darker (light mode)
  /// until it has 4.5:1 contrast on all of them.
  static Color get primaryText => _primaryTextCache.putIfAbsent(
        '${identityHashCode(_palette)}-$_dark',
        () => ensureContrast(_palette.primary, [background, surface, surfaceVariant, infoBg, accent], lighten: _dark),
      );

  // Backgrounds
  static Color get background => _dark ? _palette.backgroundDark : _palette.backgroundLight;
  static Color get surface => _dark ? _palette.surfaceDark : _surfaceLight;
  static Color get surfaceVariant => _dark ? _palette.surfaceVariantDark : _palette.surfaceVariantLight;

  static const Color _surfaceLight = Color(0xFFFFFFFF);

  // Text
  static Color get textPrimary => _dark ? _palette.textPrimaryDark : _palette.textPrimaryLight;
  static Color get textSecondary => _dark ? _palette.textSecondaryDark : _palette.textSecondaryLight;
  static Color get textMuted => _dark ? _palette.textMutedDark : _palette.textMutedLight;

  // Status (the same for every role: green is always "good", red "bad")
  static Color get success => _dark ? _successDark : _successLight;
  static Color get successBg => _dark ? _successBgDark : _successBgLight;
  static Color get warning => _dark ? _warningDark : _warningLight;
  static Color get warningBg => _dark ? _warningBgDark : _warningBgLight;
  static Color get error => _dark ? _errorDark : _errorLight;
  static Color get errorBg => _dark ? _errorBgDark : _errorBgLight;
  static Color get info => _dark ? _palette.infoDark : _palette.infoLight;
  static Color get infoBg => _dark ? _palette.infoBgDark : _palette.infoBgLight;

  // Light mode: darkened until the colour reads as text on its tinted
  // background, on white and on the pale page colours (and, as a bonus, until
  // white text on a fill of it is readable). Dark mode: a mid tone that keeps
  // 4.5:1 as text on the dark surfaces and still gives white text on a fill of
  // it at least 3:1 (luminance ~0.29 is the one value that does both).
  static const Color _successBgLight = Color(0xFFE2F6EF);
  static const Color _warningBgLight = Color(0xFFFEF3C7);
  static const Color _errorBgLight = Color(0xFFFDEEEE);
  static const List<Color> _lightGrounds = [Color(0xFFFFFFFF), Color(0xFFE8EEF0)];

  static final Color _successLight = ensureContrast(const Color(0xFF1A9E6E), [_successBgLight, ..._lightGrounds], lighten: false);
  static final Color _warningLight = ensureContrast(const Color(0xFFD97706), [_warningBgLight, ..._lightGrounds], lighten: false);
  static final Color _errorLight = ensureContrast(const Color(0xFFD94F4F), [_errorBgLight, ..._lightGrounds], lighten: false);

  static const Color _successBgDark = Color(0xFF0F2B21);
  static const Color _warningBgDark = Color(0xFF33260C);
  static const Color _errorBgDark = Color(0xFF331818);

  static final Color _successDark = colorAtLuminance(const Color(0xFF4ADE9A), 0.29);
  static final Color _warningDark = colorAtLuminance(const Color(0xFFF2B84B), 0.29);
  static final Color _errorDark = colorAtLuminance(const Color(0xFFF08787), 0.29);

  // Border
  static Color get border => _dark ? _palette.borderDark : _palette.borderLight;
  static Color get borderStrong => _dark ? _palette.borderStrongDark : _palette.borderStrongLight;
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
      appBarTheme: AppBarTheme(
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
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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
          foregroundColor: AppColors.primaryText,
          side: BorderSide(color: AppColors.primaryText),
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
        // The label colour must be set here: left out, it comes out as the default black, which is
        // unreadable on the dark theme's deep chip colours (the day / time pickers of the interview
        // screens use plain Filter/Choice/Input chips). textPrimary is audited against the
        // unselected and the selected chip colour in contrast_audit_test.
        labelStyle: TextStyle(fontSize: 12, fontFamily: 'Inter', color: AppColors.textPrimary),
        secondaryLabelStyle: TextStyle(fontSize: 12, fontFamily: 'Inter', color: AppColors.textPrimary),
        checkmarkColor: AppColors.textPrimary,
        deleteIconColor: AppColors.textSecondary,
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
