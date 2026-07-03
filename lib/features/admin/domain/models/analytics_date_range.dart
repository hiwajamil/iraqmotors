/// Inclusive date window for admin analytics queries and charts.
class AnalyticsDateRange {
  const AnalyticsDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  /// Last 30 calendar days ending today (inclusive).
  factory AnalyticsDateRange.last30Days() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(const Duration(days: 29));
    return AnalyticsDateRange(start: start, end: end);
  }

  int get dayCount => days.length;

  List<DateTime> get days {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    final count = normalizedEnd.difference(normalizedStart).inDays + 1;
    return List.generate(
      count,
      (i) => normalizedStart.add(Duration(days: i)),
    );
  }

  String formatChip() {
    String part(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${part(start)} – ${part(end)}';
  }

  AnalyticsDateRange copyWith({DateTime? start, DateTime? end}) {
    return AnalyticsDateRange(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}
