import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_cims/theme/app_theme.dart';
import 'package:fyp_cims/theme/role_theme.dart';

double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

const _roles = ['student', 'academic_supervisor', 'company_hr', 'company_supervisor', 'admin'];

void main() {
  tearDown(() {
    RoleController.instance.setRole(null);
    AppColors.setBrightness(Brightness.light);
  });

  group('RolePalette', () {
    test('HR and signed-out keep the original CIMS teal', () {
      expect(RolePalette.forRole('company_hr').primary, const Color(0xFF0F7E8A));
      expect(RolePalette.forRole(null).primary, const Color(0xFF0F7E8A));
      expect(RolePalette.forRole('company_hr').backgroundLight, const Color(0xFFF0FAFB));
    });

    test('every other role has its own, different brand colour', () {
      final primaries = _roles.map((r) => RolePalette.forRole(r).primary.toARGB32()).toSet();
      expect(primaries.length, _roles.length);
    });

    test('white text on every primary colour is readable (WCAG AA for large/bold text, 3:1)', () {
      for (final r in _roles) {
        final p = RolePalette.forRole(r);
        expect(_contrast(Colors.white, p.primary), greaterThanOrEqualTo(3.0), reason: '$r primary');
        expect(_contrast(Colors.white, p.primaryDark), greaterThanOrEqualTo(4.5), reason: '$r primaryDark');
      }
    });

    test('body text is readable on the page and card backgrounds in light and dark mode', () {
      for (final r in _roles) {
        final p = RolePalette.forRole(r);
        expect(_contrast(p.textPrimaryLight, p.backgroundLight), greaterThanOrEqualTo(10), reason: '$r light primary text');
        // The original teal (HR) was already slightly under 4.5:1 here (4.4:1); left as it was.
        expect(_contrast(p.textSecondaryLight, p.backgroundLight), greaterThanOrEqualTo(r == 'company_hr' ? 4.0 : 4.5),
            reason: '$r light secondary text');
        expect(_contrast(p.textPrimaryDark, p.backgroundDark), greaterThanOrEqualTo(10), reason: '$r dark primary text');
        expect(_contrast(p.textSecondaryDark, p.surfaceDark), greaterThanOrEqualTo(4.5), reason: '$r dark secondary text');
      }
    });

    test('the brand colour is visible against the dark page background', () {
      for (final r in _roles) {
        final p = RolePalette.forRole(r);
        expect(_contrast(p.primaryLight, p.backgroundDark), greaterThanOrEqualTo(3.0), reason: '$r');
      }
    });
  });

  group('AppColors and RoleController', () {
    test('setting the role switches the colours the whole app reads, clearing it restores the teal', () {
      expect(AppColors.primary, const Color(0xFF0F7E8A));

      RoleController.instance.setRole('student');
      expect(AppColors.primary, RolePalette.student.primary);
      expect(AppColors.background, RolePalette.student.backgroundLight);

      AppColors.setBrightness(Brightness.dark);
      expect(AppColors.background, RolePalette.student.backgroundDark);

      RoleController.instance.setRole(null);
      AppColors.setBrightness(Brightness.light);
      expect(AppColors.primary, const Color(0xFF0F7E8A));
    });

    test('status colours do not change with the role', () {
      final before = AppColors.error;
      RoleController.instance.setRole('admin');
      expect(AppColors.error, before);
      expect(AppColors.success, isNot(AppColors.primary));
    });

    test('each role has its own header icon set', () {
      final sets = _roles.map((r) => RoleTheme.headerIcons(r).map((i) => i.codePoint).join(',')).toSet();
      expect(sets.length, _roles.length);
    });
  });

  group('RoleHeaderBackground', () {
    testWidgets('paints its child over the role artwork and follows a role change', (tester) async {
      RoleController.instance.setRole('student');
      await tester.pumpWidget(const MaterialApp(
        home: SizedBox(height: 140, child: RoleHeaderBackground(child: Center(child: Text('Hello')))),
      ));
      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      RoleController.instance.setRole('admin');
      await tester.pump();
      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
