/// True once a posting is past its application deadline (the whole of that day
/// still counts) or its automatic closing time. Mirrors `posting_has_expired()`
/// in the database, which is what actually refuses applications.
bool postingIsExpired({String? deadline, String? closesAt, DateTime? now}) {
  final current = now ?? DateTime.now();
  if (deadline != null) {
    final day = DateTime.tryParse(deadline);
    if (day != null) {
      final today = DateTime(current.year, current.month, current.day);
      if (today.isAfter(DateTime(day.year, day.month, day.day))) return true;
    }
  }
  if (closesAt != null) {
    final at = DateTime.tryParse(closesAt);
    if (at != null && !at.isAfter(current)) return true;
  }
  return false;
}
