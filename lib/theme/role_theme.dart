import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Which role's look the whole app currently wears. `main.dart` rebuilds the
/// app whenever this changes; `AuthService` sets it on sign-in / session
/// restore and clears it on sign-out, so the login screen always shows the
/// neutral CIMS teal.
class RoleController {
  RoleController._();
  static final RoleController instance = RoleController._();

  /// The `profiles.role` value of the signed-in person, or null.
  final ValueNotifier<String?> role = ValueNotifier<String?>(null);

  void setRole(String? dbRole) {
    AppColors.setRole(dbRole);
    role.value = dbRole;
  }
}

/// Role-specific pieces of the look beyond colour: the icons drawn faintly in
/// header banners and the icons used for the bottom navigation.
class RoleTheme {
  RoleTheme._();

  /// Icons scattered across header artwork. Each set tells you who you are:
  /// books and pencils for a student, a clipboard and gown for the academic
  /// supervisor, people and badges for HR, hard hats and tools for the
  /// workplace, a control panel for the administrator.
  static List<IconData> headerIcons(String? dbRole) {
    switch (dbRole) {
      case 'student':
        return const [
          Icons.menu_book_outlined,
          Icons.school_outlined,
          Icons.edit_outlined,
          Icons.calculate_outlined,
          Icons.lightbulb_outline,
          Icons.auto_stories_outlined,
          Icons.science_outlined,
          Icons.backpack_outlined,
        ];
      case 'academic_supervisor':
        return const [
          Icons.fact_check_outlined,
          Icons.rate_review_outlined,
          Icons.account_balance_outlined,
          Icons.grading_outlined,
          Icons.history_edu_outlined,
          Icons.workspace_premium_outlined,
        ];
      case 'company_supervisor':
        return const [
          Icons.engineering_outlined,
          Icons.construction_outlined,
          Icons.assignment_turned_in_outlined,
          Icons.trending_up,
          Icons.apartment_outlined,
          Icons.handyman_outlined,
        ];
      case 'admin':
        return const [
          Icons.admin_panel_settings_outlined,
          Icons.settings_outlined,
          Icons.dashboard_customize_outlined,
          Icons.security_outlined,
          Icons.analytics_outlined,
          Icons.tune,
        ];
      default: // company_hr and signed-out
        return const [
          Icons.badge_outlined,
          Icons.groups_outlined,
          Icons.business_center_outlined,
          Icons.event_available_outlined,
          Icons.how_to_reg_outlined,
          Icons.contact_mail_outlined,
        ];
    }
  }
}

/// The gradient banner behind every dashboard header and app bar, with the
/// role's icons scattered across it. Drop-in replacement for the plain
/// `Container(decoration: gradient)` the screens used before.
class RoleHeaderBackground extends StatelessWidget {
  const RoleHeaderBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: RoleController.instance.role,
      builder: (context, role, _) {
        return LayoutBuilder(
          builder: (context, constraints) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: AppColors.headerGradient,
              ),
            ),
            child: Stack(
              // Inside an app bar the banner is given a fixed height and the
              // child fills it. In a Column (no height given) the banner is
              // as tall as its child; `expand` there would ask for infinite
              // height and the whole page would fail to draw.
              fit: constraints.hasBoundedHeight ? StackFit.expand : StackFit.loose,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRect(
                      child: CustomPaint(painter: RoleArtPainter(RoleTheme.headerIcons(role))),
                    ),
                  ),
                ),
                constraints.hasBoundedHeight ? child : SizedBox(width: double.infinity, child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Draws [icons] as a loose, slightly rotated, low-contrast pattern. The
/// layout is a pure function of the size and the icon list, so it never
/// jumps when the widget rebuilds.
class RoleArtPainter extends CustomPainter {
  RoleArtPainter(this.icons, {this.opacity = 0.13});

  final List<IconData> icons;
  final double opacity;

  static const double _cell = 58;

  @override
  void paint(Canvas canvas, Size size) {
    if (icons.isEmpty || size.isEmpty) return;
    final columns = (size.width / _cell).ceil() + 1;
    final rows = (size.height / _cell).ceil() + 1;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        final index = (r * 3 + c * 5 + r * c) % icons.length;
        // Every other row is shifted half a cell so the pattern does not look like a grid.
        final dx = c * _cell + (r.isOdd ? _cell / 2 : 0) + ((c * 7 + r * 3) % 9) - 4;
        final dy = r * _cell + ((c * 5 + r * 11) % 9) - 4;
        final iconSize = 22.0 + ((c + r * 2) % 4) * 3;
        final angle = (((c * 3 + r * 5) % 7) - 3) * 0.11;

        final icon = icons[index];
        final painter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: iconSize,
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              color: Colors.white.withValues(alpha: opacity),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        canvas.save();
        canvas.translate(dx + painter.width / 2, dy + painter.height / 2);
        canvas.rotate(angle * math.pi);
        painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoleArtPainter oldDelegate) =>
      oldDelegate.icons != icons || oldDelegate.opacity != opacity;
}
