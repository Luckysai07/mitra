import 'package:flutter_test/flutter_test.dart';
import 'package:mitra/core/utils/money.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';
import 'package:mitra/features/transactions/providers/transaction_providers.dart';
import 'package:mitra/services/receipt_ocr_service.dart';
import 'package:mitra/services/whatsapp_share_service.dart';

void main() {
  group('Mitra End-to-End System Integration Suite', () {
    test('E2E Flow: Organization Setup -> Ledger Transactions -> Net Balance -> Receipt Sharing', () {
      // 1. Setup Organization
      final orgMap = {
        'id': 'org-test-2026',
        'name': 'Sri Ganesh Youth Committee 2026',
        'org_type': 'ganesh_utsav',
        'description': 'Annual Festival Committee',
        'location': 'Hyderabad, India',
        'join_code': 'GANESH26',
        'created_by': 'user-owner-01',
        'created_at': DateTime.now().toIso8601String(),
      };

      final org = OrganizationModel.fromMap(orgMap);
      expect(org.id, equals('org-test-2026'));
      expect(org.name, equals('Sri Ganesh Youth Committee 2026'));
      expect(org.joinCode, equals('GANESH26'));

      // 2. Simulate Income & Expense Transactions
      final txns = <TransactionModel>[
        TransactionModel(
          id: 'txn-01',
          orgId: org.id,
          txnNumber: 'TXN-00001',
          type: 'income',
          amountPaise: 500000, // ₹5,000.00
          date: DateTime.now(),
          description: 'Donation',
          personName: 'Suresh Kumar',
          paymentMethod: 'upi',
          createdBy: 'user-owner-01',
          createdAt: DateTime.now(),
        ),
        TransactionModel(
          id: 'txn-02',
          orgId: org.id,
          txnNumber: 'TXN-00002',
          type: 'income',
          amountPaise: 1000000, // ₹10,000.00
          date: DateTime.now(),
          description: 'Sponsorship',
          personName: 'City Jewellers',
          paymentMethod: 'bank',
          createdBy: 'user-owner-01',
          createdAt: DateTime.now(),
        ),
        TransactionModel(
          id: 'txn-03',
          orgId: org.id,
          txnNumber: 'TXN-00003',
          type: 'expense',
          amountPaise: 350000, // ₹3,500.00
          date: DateTime.now(),
          description: 'Decorations & Stage',
          personName: 'Shree Decorators',
          paymentMethod: 'cash',
          createdBy: 'user-owner-01',
          createdAt: DateTime.now(),
        ),
      ];

      // 3. Compute Financial Aggregation via Money Integer Math
      int totalIncomePaise = 0;
      int totalExpensePaise = 0;

      for (final t in txns) {
        if (t.type == 'income') {
          totalIncomePaise += t.amountPaise;
        } else {
          totalExpensePaise += t.amountPaise;
        }
      }

      final incomeMoney = Money(totalIncomePaise);
      final expenseMoney = Money(totalExpensePaise);
      final netBalance = incomeMoney - expenseMoney;

      expect(incomeMoney.formatted, equals('₹15,000.00'));
      expect(expenseMoney.formatted, equals('₹3,500.00'));
      expect(netBalance.formatted, equals('₹11,500.00'));

      // 4. Verify Target Goal Progress Meter Math
      const goalPaise = 5000000; // Target ₹50,000.00
      final percentage = (totalIncomePaise / goalPaise);
      expect(percentage, equals(0.30)); // 30% of target raised

      // 5. Verify Receipt Sharing Card Generation
      final receiptCardText = WhatsAppShareService.buildReceiptText(
        txn: txns.first,
        org: org,
      );
      expect(receiptCardText, contains('OFFICIAL DIGITAL RECEIPT'));
      expect(receiptCardText, contains('TXN-00001'));
      expect(receiptCardText, contains('₹5,000.00'));
      expect(receiptCardText, contains('Suresh Kumar'));

      // 6. Verify AI Bill OCR Parsing Logic
      const billScan = '''
SHREE DECORATORS
Date: 2026-08-25
Stage & Flower Decor   ₹3,500
TOTAL AMOUNT:          ₹3,500.00
''';
      final ocrResult = ReceiptOcrService.parseText(billScan);
      expect(ocrResult.amount, equals(3500.00));
      expect(ocrResult.merchantName, equals('SHREE DECORATORS'));
      expect(ocrResult.suggestedCategory, equals('Decorations'));
    });
  });
}
