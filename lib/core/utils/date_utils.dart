import 'package:intl/intl.dart';

/// Date formatting and helper utilities.
///
/// All dates are stored as UTC in the database and displayed
/// in the user's local timezone.
abstract final class AppDateUtils {
  // ── Formatters ──

  static final _fullDate = DateFormat('dd MMM yyyy');       // 24 Aug 2026
  static final _shortDate = DateFormat('dd MMM');            // 24 Aug
  static final _monthYear = DateFormat('MMMM yyyy');         // August 2026
  static final _dayMonthYear = DateFormat('d MMMM yyyy');    // 24 August 2026
  static final _time = DateFormat('h:mm a');                 // 2:30 PM
  static final _dateTime = DateFormat('dd MMM yyyy, h:mm a');// 24 Aug 2026, 2:30 PM
  static final _iso = DateFormat('yyyy-MM-dd');              // 2026-08-24

  /// "24 Aug 2026"
  static String formatFull(DateTime date) => _fullDate.format(date);

  /// "24 Aug"
  static String formatShort(DateTime date) => _shortDate.format(date);

  /// "August 2026"
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  /// "24 August 2026"
  static String formatLong(DateTime date) => _dayMonthYear.format(date);

  /// "2:30 PM"
  static String formatTime(DateTime date) => _time.format(date);

  /// "24 Aug 2026, 2:30 PM"
  static String formatDateTime(DateTime date) => _dateTime.format(date);

  /// "2026-08-24" (for database/API)
  static String formatIso(DateTime date) => _iso.format(date);

  // ── Relative time ──

  /// "Just now", "5m ago", "2h ago", "Yesterday", "24 Aug"
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (date.year == now.year) return formatShort(date);
    return formatFull(date);
  }

  // ── Helpers ──

  /// Whether two dates fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Whether the date is today.
  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  /// Whether the date is yesterday.
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Start of the current month.
  static DateTime startOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, 1);
  }

  /// End of the current month.
  static DateTime endOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month + 1, 0, 23, 59, 59);
  }

  /// Group key for transaction list section headers.
  /// Returns "Today", "Yesterday", "24 Aug 2026", etc.
  static String groupLabel(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isYesterday(date)) return 'Yesterday';
    final now = DateTime.now();
    if (date.year == now.year) return formatShort(date);
    return formatFull(date);
  }
}
