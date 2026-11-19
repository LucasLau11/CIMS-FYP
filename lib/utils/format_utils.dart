import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/common/shared_widgets.dart';
import '../theme/app_theme.dart';

/// Human-readable, locale-aware "time ago" string (e.g. "2 hours ago").
String timeAgo(BuildContext context, DateTime dateTime) {
  final l10n = AppLocalizations.of(context)!;
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return l10n.justNow;
  if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
  if (diff.inDays < 30) return l10n.weeksAgo((diff.inDays / 7).floor());
  final months = (diff.inDays / 30).floor();
  if (months < 12) return l10n.monthsAgo(months);
  return l10n.yearsAgo((diff.inDays / 365).floor());
}

/// Deterministic single-letter logo + color for a company/person name, so
/// the same name always renders the same way without storing a color.
String logoLetter(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
}

const List<Color> _paletteColors = [
  Color(0xFF00A3FF),
  Color(0xFF00B14F),
  Color(0xFFE30613),
  Color(0xFFEE4D2D),
  Color(0xFF8B0000),
  Color(0xFF6B4EFF),
  Color(0xFF0F7E8A),
  Color(0xFFD97706),
];

Color nameColor(String name) {
  if (name.isEmpty) return _paletteColors[0];
  final hash = name.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return _paletteColors[hash % _paletteColors.length];
}

/// The colour for the LETTER on a logo or avatar tinted with [nameColor] (12-15% of it over the
/// page). The raw palette colour on its own tint reads at only 2 to 3:1, so the letter is pushed
/// darker (lighter in the dark theme) until it reaches 4.5:1 on every ground it can sit on.
Color nameTextColor(String name) {
  final base = nameColor(name);
  final dark = AppColors.currentBrightness == Brightness.dark;
  Color tint(Color ground, double opacity) => Color.alphaBlend(base.withValues(alpha: opacity), ground);
  final grounds = <Color>[
    for (final ground in [AppColors.background, AppColors.surface, AppColors.surfaceVariant])
      for (final opacity in [0.12, 0.15]) tint(ground, opacity),
  ];
  return ensureContrast(base, grounds, lighten: dark);
}

/// Postgres `numeric`/`bigint` columns come back from PostgREST as JSON
/// strings (to avoid precision loss), not JSON numbers — a plain `as num?`
/// cast on them throws. Parse defensively regardless of the wire shape.
num? parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String formatAllowance(num? allowanceMonth) {
  if (allowanceMonth == null) return 'Unpaid';
  return 'RM ${allowanceMonth.toStringAsFixed(0)}/month';
}

String formatDuration(int months) => '$months month${months == 1 ? '' : 's'}';

/// How many months an intake lasts, which is how many monthly reports its students must submit: the days between its
/// start and end dates / 30.44, rounded, at least 1 (the same rule as the database function `intake_months`).
int intakeMonths(DateTime start, DateTime end) {
  final months = (end.difference(start).inDays / 30.4375).round();
  return months < 1 ? 1 : months;
}

IconData notificationIcon(String type) {
  switch (type) {
    case 'application':
      return Icons.work_outline;
    case 'report':
      return Icons.assignment_outlined;
    case 'document':
      return Icons.description_outlined;
    case 'message':
      return Icons.chat_bubble_outline;
    default:
      return Icons.info_outline;
  }
}

/// English label for an `applications.status` value, for screens that are
/// not localized. Student screens build their own badges
/// per-card since they're already wired to AppLocalizations.
String applicationStatusLabel(String status) {
  switch (status) {
    case 'active':
      return 'Active';
    case 'interview':
      return 'Interview Scheduled';
    case 'offered':
      return 'Offer Made';
    case 'unavailable':
      return 'Closed';
    case 'rejected':
      return 'Not Selected';
    default:
      return 'Pending Review';
  }
}

StatusBadge applicationStatusBadge(BuildContext context, String status) {
  switch (status) {
    case 'active':
      return StatusBadge.active(context);
    case 'rejected':
      return StatusBadge.rejected(context);
    case 'interview':
      return const StatusBadge(label: 'Interview', backgroundColor: Color(0xFFFEF3C7), textColor: Color(0xFFD97706));
    case 'offered':
      return StatusBadge.offered(context);
    case 'unavailable':
      return StatusBadge.unavailable(context);
    default:
      return StatusBadge.pending(context);
  }
}

Color notificationColor(String type) {
  switch (type) {
    case 'application':
      return AppColors.primary;
    case 'report':
      return const Color(0xFF1A9E6E);
    case 'document':
      return const Color(0xFFD97706);
    case 'message':
      return const Color(0xFF00A3FF);
    default:
      return const Color(0xFF5F5E5A);
  }
}
