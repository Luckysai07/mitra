import 'package:intl/intl.dart';

/// Integer-based monetary value (stored in paise).
///
/// ₹100.50 is represented as `Money(10050)`.
/// All arithmetic is integer-only — no floating-point drift.
///
/// ```dart
/// final donation = Money(500000);  // ₹5,000.00
/// final expense  = Money(150075);  // ₹1,500.75
/// final balance  = donation - expense; // ₹3,499.25 = Money(349925)
/// ```
class Money implements Comparable<Money> {
  /// Raw value in the smallest currency unit (paise for INR).
  final int paise;

  const Money(this.paise);

  /// Create from a rupee value. Use only for display input — internally
  /// always pass paise.
  ///
  /// ⚠️  Rounds to nearest paisa to avoid precision issues.
  factory Money.fromRupees(double rupees) {
    return Money((rupees * 100).round());
  }

  /// Zero money.
  static const Money zero = Money(0);

  // ── Getters ──

  /// Value in rupees (for display only).
  double get rupees => paise / 100;

  /// Whether this amount is zero.
  bool get isZero => paise == 0;

  /// Whether this amount is positive.
  bool get isPositive => paise > 0;

  /// Whether this amount is negative.
  bool get isNegative => paise < 0;

  // ── Formatting ──

  /// Indian locale format: ₹1,23,456.00
  String get formatted {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return '₹${formatter.format(rupees)}';
  }

  /// Compact format: ₹1.2L, ₹50.0K, ₹1.5Cr
  String get compact {
    final r = rupees.abs();
    if (r >= 10000000) {
      // ≥ 1 Crore Rupees (₹1,00,00,000)
      return '₹${(r / 10000000).toStringAsFixed(1)}Cr';
    } else if (r >= 100000) {
      // ≥ 1 Lakh Rupees (₹1,00,000)
      return '₹${(r / 100000).toStringAsFixed(1)}L';
    } else if (r >= 1000) {
      // ≥ 1 Thousand Rupees (₹1,000)
      return '₹${(r / 1000).toStringAsFixed(1)}K';
    }
    return formatted;
  }

  /// Format without decimals: ₹1,23,456
  String get formattedWhole {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return '₹${formatter.format(rupees)}';
  }

  /// Signed format: +₹5,000.00 / −₹1,200.00
  String get signedFormatted {
    if (paise > 0) return '+$formatted';
    if (paise < 0) return '−₹${NumberFormat('#,##,##0.00', 'en_IN').format(rupees.abs())}';
    return formatted;
  }

  // ── Arithmetic ──

  Money operator +(Money other) => Money(paise + other.paise);
  Money operator -(Money other) => Money(paise - other.paise);
  Money operator -() => Money(-paise);
  Money operator *(int factor) => Money(paise * factor);

  /// Percentage of this amount (rounded to nearest paisa).
  Money percentage(double percent) {
    return Money((paise * percent / 100).round());
  }

  // ── Comparison ──

  bool operator >(Money other) => paise > other.paise;
  bool operator <(Money other) => paise < other.paise;
  bool operator >=(Money other) => paise >= other.paise;
  bool operator <=(Money other) => paise <= other.paise;

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Money && paise == other.paise;

  @override
  int get hashCode => paise.hashCode;

  @override
  String toString() => 'Money($paise paise = $formatted)';
}
