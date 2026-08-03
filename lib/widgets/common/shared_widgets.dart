import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

// Gradient wave app bar used throughout the app
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showWave;
  final double extraHeight;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showWave = false,
    this.extraHeight = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + extraHeight + (showWave ? 20 : 0));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              actions: actions,
              leading: leading,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            if (showWave)
              CustomPaint(
                painter: _WavePainter(),
                size: const Size(double.infinity, 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, size.height, size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Accent card with left teal border
class AccentCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? accentColor;

  const AccentCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // A BoxDecoration can't combine a borderRadius with a Border whose
    // sides have different colors (the left accent stripe vs. the neutral
    // AppColors.border on the other three) — Flutter can only paint that
    // combination for a *uniform* border. In debug builds that mismatch
    // throws mid-paint (aborting before the child ever paints, i.e. a
    // blank card); in release builds the assert is stripped but the
    // paint still doesn't reliably draw the stripe. So the left stripe is
    // its own solid-color bar instead of a border side, and the outer
    // decoration keeps a plain uniform border + radius.
    //
    // The stripe is positioned via Stack, not a Row with
    // CrossAxisAlignment.stretch — AccentCard is used both inside
    // ListView items (bounded height) and inside a plain Column in a
    // scrolling page (Profile screen's resume section), and stretch
    // needs a bounded cross-axis constraint from the parent to resolve.
    // Inside the unbounded case it throws "BoxConstraints forces an
    // infinite height", which — same as the border/radius bug — takes
    // down the whole page's layout, not just this card. Stack sizes
    // itself from the non-positioned content child first, then lays out
    // the Positioned stripe against that resolved height, so it works
    // in both contexts.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            Padding(
              padding: (padding ?? const EdgeInsets.all(14)).add(const EdgeInsets.only(left: 4)),
              child: child,
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: accentColor ?? AppColors.cardAccent),
            ),
          ],
        ),
      ),
    );
  }
}

// Status badge pill
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  factory StatusBadge.pending(BuildContext context) => StatusBadge(
    label: AppLocalizations.of(context)!.pending,
    backgroundColor: AppColors.warningBg,
    textColor: AppColors.warning,
  );

  factory StatusBadge.approved(BuildContext context) => StatusBadge(
    label: AppLocalizations.of(context)!.statusApproved,
    backgroundColor: AppColors.successBg,
    textColor: AppColors.success,
  );

  factory StatusBadge.rejected(BuildContext context) => StatusBadge(
    label: AppLocalizations.of(context)!.rejected,
    backgroundColor: AppColors.errorBg,
    textColor: AppColors.error,
  );

  factory StatusBadge.submitted(BuildContext context) => StatusBadge(
    label: AppLocalizations.of(context)!.statusSubmitted,
    backgroundColor: AppColors.infoBg,
    textColor: AppColors.info,
  );

  factory StatusBadge.active(BuildContext context) => StatusBadge(
    label: AppLocalizations.of(context)!.active,
    backgroundColor: AppColors.successBg,
    textColor: AppColors.success,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// Section header
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: AppTextStyles.h3)),
          if (actionIcon != null)
            GestureDetector(
              onTap: onAction,
              child: Icon(actionIcon, size: 20, color: AppColors.primary),
            )
          else if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Metric stat card (for dashboard)
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// Empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: AppTextStyles.h3,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(description,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center),
            if (buttonLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onButton,
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Notification dot indicator
class NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const NotificationBell({super.key, this.count = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined, color: Colors.white),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Progress step indicator
class ProgressStepper extends StatelessWidget {
  final List<String> steps;
  final int currentStep;

  const ProgressStepper({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final isCompleted = i < currentStep;
        final isActive = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary
                            : isActive
                            ? AppColors.primaryLight
                            : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: isActive || isCompleted
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Container(
                  height: 2,
                  width: 20,
                  color: i < currentStep ? AppColors.primary : AppColors.border,
                  margin: const EdgeInsets.only(bottom: 22),
                ),
            ],
          ),
        );
      }),
    );
  }
}