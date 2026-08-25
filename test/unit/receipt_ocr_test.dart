import 'package:flutter_test/flutter_test.dart';
import 'package:mitra/services/receipt_ocr_service.dart';

void main() {
  group('Receipt OCR Service Unit Tests', () {
    test('Parse amount, vendor name, and category from raw bill text', () {
      const billText = '''
ROYAL SOUND & LIGHTING
Date: 2026-08-25
Sound Setup            ₹12,500
TOTAL AMOUNT:          ₹12,500.00
Payment Method:        UPI
''';

      final result = ReceiptOcrService.parseText(billText);

      expect(result.amount, equals(12500.00));
      expect(result.merchantName, equals('ROYAL SOUND & LIGHTING'));
      expect(result.suggestedCategory, equals('Lighting'));
      expect(result.rawText, equals(billText));
    });

    test('Auto-match Prasadam / Food category keyword', () {
      const foodBill = '''
ANNAPURNA CATERING SERVICES
Food & Prasadam Items  ₹ 8,400.00
''';

      final result = ReceiptOcrService.parseText(foodBill);
      expect(result.suggestedCategory, equals('Prasadam / Food'));
    });
  });
}
