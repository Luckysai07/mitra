import 'package:flutter_test/flutter_test.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';
import 'package:mitra/features/transactions/providers/transaction_providers.dart';
import 'package:mitra/services/whatsapp_share_service.dart';

void main() {
  group('WhatsApp Share Service Unit Tests', () {
    test('Build formatted official receipt text containing logo, location, and amount in words', () {
      final org = OrganizationModel(
        id: 'org-101',
        name: 'Bal Ganesh Samiti 2026',
        orgType: 'ganesh_utsav',
        location: 'Hyderabad, India',
        logoUrl: '🪔',
        joinCode: 'GANESH26',
        createdBy: 'user-001',
        createdAt: DateTime.now(),
      );

      final txn = TransactionModel(
        id: '12345678-abcd-efgh-ijkl-1234567890ab',
        orgId: org.id,
        txnNumber: 'TXN-00042',
        type: 'income',
        amountPaise: 50000, // ₹500.00
        date: DateTime(2026, 8, 25),
        description: 'Ganesh Utsav Donation',
        personName: 'Rajesh Kumar',
        paymentMethod: 'upi',
        createdBy: 'user-001',
        createdAt: DateTime.now(),
      );

      final text = WhatsAppShareService.buildReceiptText(
        txn: txn,
        org: org,
      );

      expect(text, contains('OFFICIAL DIGITAL RECEIPT'));
      expect(text, contains('BAL GANESH SAMITI 2026'));
      expect(text, contains('Hyderabad, India'));
      expect(text, contains('TXN-00042'));
      expect(text, contains('Rajesh Kumar'));
      expect(text, contains('₹500.00'));
      expect(text, contains('Five Hundred Rupees Only'));
      expect(text, contains('UPI'));
      expect(text, contains('Ganesh Utsav Donation'));
      expect(text, contains('https://app.url/verify/12345678'));
    });
  });
}
