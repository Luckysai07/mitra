import 'package:intl/intl.dart';

/// Currency formatting utilities for INR (Indian Rupees).
///
/// Uses Indian numbering system:
/// - 1,000 (one thousand)
/// - 10,000 (ten thousand)
/// - 1,00,000 (one lakh)
/// - 10,00,000 (ten lakh)
/// - 1,00,00,000 (one crore)
abstract final class CurrencyFormatter {
  static final _inrFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _inrFormatWhole = NumberFormat('#,##,##0', 'en_IN');

  /// Format paise to full rupee string: 10050 → "₹100.50"
  static String formatPaise(int paise, {bool showDecimal = true}) {
    final rupees = paise / 100;
    if (showDecimal) {
      return '₹${_inrFormat.format(rupees)}';
    }
    return '₹${_inrFormatWhole.format(rupees)}';
  }

  /// Format paise with sign: 10050 → "+₹100.50", -5000 → "−₹50.00"
  static String formatPaiseSigned(int paise) {
    final rupees = paise.abs() / 100;
    final formatted = _inrFormat.format(rupees);
    if (paise > 0) return '+₹$formatted';
    if (paise < 0) return '−₹$formatted';
    return '₹$formatted';
  }

  /// Compact format for dashboard cards:
  /// - < ₹1K    → "₹500"
  /// - < ₹1L    → "₹50K"
  /// - < ₹1Cr   → "₹12.5L"
  /// - ≥ ₹1Cr   → "₹1.2Cr"
  static String formatPaiseCompact(int paise) {
    final abs = paise.abs();
    final rupees = abs / 100;

    String result;
    if (rupees >= 10000000) {
      result = '₹${(rupees / 10000000).toStringAsFixed(1)}Cr';
    } else if (rupees >= 100000) {
      result = '₹${(rupees / 100000).toStringAsFixed(1)}L';
    } else if (rupees >= 1000) {
      result = '₹${(rupees / 1000).toStringAsFixed(1)}K';
    } else {
      result = '₹${_inrFormatWhole.format(rupees)}';
    }

    return paise < 0 ? '-$result' : result;
  }

  /// Convert rupee input string to paise.
  /// "100.50" → 10050, "5000" → 500000
  static int? parseToPaise(String input) {
    final cleaned = input.replaceAll(RegExp(r'[₹,\s]'), '');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }

  /// Number to words (Indian English) for receipt generation.
  /// 5000 → "Five Thousand Rupees Only"
  static String amountInWords(int paise) {
    final rupees = paise ~/ 100;
    final paiseRemainder = paise % 100;

    final rupeePart = _numberToWords(rupees);
    if (paiseRemainder == 0) {
      return '$rupeePart Rupees Only';
    }
    final paisePart = _numberToWords(paiseRemainder);
    return '$rupeePart Rupees and $paisePart Paise Only';
  }

  static String _numberToWords(int number) {
    if (number == 0) return 'Zero';

    const ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
      'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen',
    ];
    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
      'Sixty', 'Seventy', 'Eighty', 'Ninety',
    ];

    if (number < 0) return 'Minus ${_numberToWords(-number)}';
    if (number < 20) return ones[number];
    if (number < 100) {
      final t = tens[number ~/ 10];
      final o = ones[number % 10];
      return o.isEmpty ? t : '$t $o';
    }
    if (number < 1000) {
      final h = '${ones[number ~/ 100]} Hundred';
      final rem = number % 100;
      return rem == 0 ? h : '$h and ${_numberToWords(rem)}';
    }
    if (number < 100000) {
      final t = '${_numberToWords(number ~/ 1000)} Thousand';
      final rem = number % 1000;
      return rem == 0 ? t : '$t ${_numberToWords(rem)}';
    }
    if (number < 10000000) {
      final l = '${_numberToWords(number ~/ 100000)} Lakh';
      final rem = number % 100000;
      return rem == 0 ? l : '$l ${_numberToWords(rem)}';
    }
    final cr = '${_numberToWords(number ~/ 10000000)} Crore';
    final rem = number % 10000000;
    return rem == 0 ? cr : '$cr ${_numberToWords(rem)}';
  }
}
