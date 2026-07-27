import 'package:flutter/material.dart';

/// Human-readable "time ago" string (e.g. "2 hours ago", "3 days ago").
String timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
  if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  if (diff.inDays < 30) {
    final weeks = (diff.inDays / 7).floor();
    return '$weeks week${weeks == 1 ? '' : 's'} ago';
  }
  final months = (diff.inDays / 30).floor();
  if (months < 12) return '$months month${months == 1 ? '' : 's'} ago';
  final years = (diff.inDays / 365).floor();
  return '$years year${years == 1 ? '' : 's'} ago';
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

Color notificationColor(String type) {
  switch (type) {
    case 'application':
      return const Color(0xFF0F7E8A);
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
