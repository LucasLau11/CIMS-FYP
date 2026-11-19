import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/theme/app_theme.dart';

double _lum(Color c) => c.computeLuminance();

/// WCAG contrast ratio between [fg] drawn over [bg] (an opaque colour).
double contrast(Color fg, Color bg) {
  // Blend a translucent foreground onto the background first.
  final a = fg.a;
  final blended = Color.from(
    alpha: 1,
    red: fg.r * a + bg.r * (1 - a),
    green: fg.g * a + bg.g * (1 - a),
    blue: fg.b * a + bg.b * (1 - a),
  );
  final l1 = _lum(blended);
  final l2 = _lum(bg);
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

const _roles = <String?>['student', 'academic_supervisor', 'company_hr', 'company_supervisor', 'admin'];

/// Every text-on-background pairing the screens use, for every role and for
/// light and dark mode. [min] is 4.5 (WCAG AA body text) unless the text is
/// large or bold, where 3.0 applies.
List<(String, Color Function(), Color Function(), double)> _pairs() => [
      ('textPrimary on background', () => AppColors.textPrimary, () => AppColors.background, 4.5),
      ('textPrimary on surface', () => AppColors.textPrimary, () => AppColors.surface, 4.5),
      ('textPrimary on surfaceVariant', () => AppColors.textPrimary, () => AppColors.surfaceVariant, 4.5),
      ('textSecondary on background', () => AppColors.textSecondary, () => AppColors.background, 4.5),
      ('textSecondary on surface', () => AppColors.textSecondary, () => AppColors.surface, 4.5),
      ('textSecondary on surfaceVariant', () => AppColors.textSecondary, () => AppColors.surfaceVariant, 4.5),
      ('textMuted on background', () => AppColors.textMuted, () => AppColors.background, 4.5),
      ('textMuted on surface', () => AppColors.textMuted, () => AppColors.surface, 4.5),
      ('textMuted on surfaceVariant', () => AppColors.textMuted, () => AppColors.surfaceVariant, 4.5),
      ('primaryText on background', () => AppColors.primaryText, () => AppColors.background, 4.5),
      ('primaryText on surface', () => AppColors.primaryText, () => AppColors.surface, 4.5),
      ('primaryText on surfaceVariant', () => AppColors.primaryText, () => AppColors.surfaceVariant, 4.5),
      ('primaryText on infoBg', () => AppColors.primaryText, () => AppColors.infoBg, 4.5),
      ('info on infoBg', () => AppColors.info, () => AppColors.infoBg, 4.5),
      ('info on surface', () => AppColors.info, () => AppColors.surface, 4.5),
      ('success on successBg', () => AppColors.success, () => AppColors.successBg, 4.5),
      ('success on surface', () => AppColors.success, () => AppColors.surface, 4.5),
      ('warning on warningBg', () => AppColors.warning, () => AppColors.warningBg, 4.5),
      ('warning on surface', () => AppColors.warning, () => AppColors.surface, 4.5),
      ('error on errorBg', () => AppColors.error, () => AppColors.errorBg, 4.5),
      ('error on surface', () => AppColors.error, () => AppColors.surface, 4.5),
      ('textPrimary on accent (selected chip)', () => AppColors.textPrimary, () => AppColors.accent, 4.5),
      ('primaryText on accent', () => AppColors.primaryText, () => AppColors.accent, 4.5),
      ('textPrimary on infoBg', () => AppColors.textPrimary, () => AppColors.infoBg, 4.5),
      ('textSecondary on infoBg', () => AppColors.textSecondary, () => AppColors.infoBg, 4.5),
      ('textSecondary on warningBg', () => AppColors.textSecondary, () => AppColors.warningBg, 4.5),
      ('white on primary (buttons)', () => Colors.white, () => AppColors.primary, 4.5),
      ('white on primaryDark (banner)', () => Colors.white, () => AppColors.primaryDark, 4.5),
      ('soft white on primary (banner caption)', () => kOnBannerSoft, () => AppColors.primary, 4.5),
      ('soft white on primaryDark (banner caption)', () => kOnBannerSoft, () => AppColors.primaryDark, 4.5),
      ('white on error (fills)', () => Colors.white, () => AppColors.error, 3.0),
      ('white on success (fills)', () => Colors.white, () => AppColors.success, 3.0),
      ('white on warning (fills)', () => Colors.white, () => AppColors.warning, 3.0),
    ];

void main() {
  tearDown(() {
    AppColors.setRole(null);
    AppColors.setBrightness(Brightness.light);
  });

  test('every text colour is readable on its background, in every role, light and dark', () {
    final failures = <String>[];
    for (final role in _roles) {
      for (final brightness in Brightness.values) {
        AppColors.setRole(role);
        AppColors.setBrightness(brightness);
        for (final (name, fg, bg, min) in _pairs()) {
          final ratio = contrast(fg(), bg());
          if (ratio < min) {
            failures.add('${role ?? 'brand'} ${brightness.name}: $name = ${ratio.toStringAsFixed(2)} (needs $min)');
          }
        }
      }
    }
    expect(failures, isEmpty, reason: '\n${failures.join('\n')}');
  });
}
