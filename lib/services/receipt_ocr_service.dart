import 'dart:io';

/// Parsed OCR Receipt data structure.
class ParsedOcrReceipt {
  final double? amount;
  final DateTime? date;
  final String? merchantName;
  final String? suggestedCategory;
  final String rawText;

  const ParsedOcrReceipt({
    this.amount,
    this.date,
    this.merchantName,
    this.suggestedCategory,
    required this.rawText,
  });
}

/// Service for extracting structured details from scanned receipt images.
class ReceiptOcrService {
  ReceiptOcrService._();

  /// Parse raw text string extracted from receipt image.
  static ParsedOcrReceipt parseText(String rawText) {
    final lower = rawText.toLowerCase();

    // 1. Extract Amount (look for ₹, Total, Amount, RS)
    double? extractedAmount;
    final amountRegex = RegExp(r'(total|amount|rs|₹|net)\s*[:\=]?\s*₹?\s*(\d+[\d,]*(\.\d{2})?)', caseSensitive: false);
    final match = amountRegex.firstMatch(rawText);
    if (match != null && match.groupCount >= 2) {
      final clean = match.group(2)?.replaceAll(',', '');
      if (clean != null) {
        extractedAmount = double.tryParse(clean);
      }
    }

    // 2. Extract Merchant Name (first non-empty capitalized line)
    String? merchant;
    final lines = rawText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      merchant = lines.first.trim();
    }

    // 3. Category auto-matching based on keywords
    String? category;
    if (lower.contains('food') || lower.contains('restaurant') || lower.contains('catering') || lower.contains('prasadam')) {
      category = 'Prasadam / Food';
    } else if (lower.contains('light') || lower.contains('electric') || lower.contains('bulb')) {
      category = 'Lighting';
    } else if (lower.contains('sound') || lower.contains('music') || lower.contains('dj')) {
      category = 'Sound & Music';
    } else if (lower.contains('flower') || lower.contains('decor') || lower.contains('stage')) {
      category = 'Decorations';
    } else {
      category = 'Miscellaneous';
    }

    return ParsedOcrReceipt(
      amount: extractedAmount,
      date: DateTime.now(),
      merchantName: merchant,
      suggestedCategory: category,
      rawText: rawText,
    );
  }

  /// Simulate OCR scanning from image file path.
  static Future<ParsedOcrReceipt> processImageFile(File file) async {
    // Simulated fast local OCR text extraction
    await Future.delayed(const Duration(milliseconds: 800));

    final sampleText = '''
SHREE GANESH DECORATORS
Date: 2026-08-25
Invoice #: INV-9942
-----------------------------
Stage & Flower Decor   ₹15,000
Lighting Setup         ₹ 5,000
-----------------------------
TOTAL AMOUNT:          ₹20,000.00
Payment Method:        UPI GPay
Thank you for your business!
''';

    return parseText(sampleText);
  }
}
