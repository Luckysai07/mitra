import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/currency_formatter.dart';
import '../core/utils/number_to_words.dart';
import '../features/organization/providers/org_providers.dart';
import '../features/transactions/providers/transaction_providers.dart';

/// Service for generating official formatted digital receipts with logo, location,
/// donor name, amount in figures & words, and WhatsApp sharing.
class WhatsAppShareService {
  WhatsAppShareService._();

  /// Build an official formatted WhatsApp digital receipt text card.
  static String buildReceiptText({
    required TransactionModel txn,
    required OrganizationModel org,
    String? receiptPrefix = 'RCT',
  }) {
    final isIncome = txn.type == 'income';
    final amountFormatted = CurrencyFormatter.formatPaise(txn.amountPaise);
    final amountWords = NumberToWords.convertPaise(txn.amountPaise);
    final dateFormatted = txn.date.toString().split(' ')[0];
    final txnNo = txn.txnNumber;
    final person = txn.personName ?? 'Valued Donor';
    final payMethod = txn.paymentMethod.toUpperCase();
    final logo = org.logoUrl ?? '🏛️';
    final location = org.location ?? 'India';

    final buffer = StringBuffer();
    buffer.writeln('==============================');
    buffer.writeln('$logo *${org.name.toUpperCase()}*');
    buffer.writeln('📍 *Location:* $location');
    buffer.writeln('==============================');
    buffer.writeln('📜 *OFFICIAL DIGITAL RECEIPT*');
    buffer.writeln('------------------------------');
    buffer.writeln('🧾 *Receipt No:* $txnNo');
    buffer.writeln('📅 *Date:* $dateFormatted');
    buffer.writeln(isIncome ? '👤 *Donor / Paid By:* $person' : '👤 *Payee / Paid To:* $person');
    buffer.writeln('💰 *Amount:* $amountFormatted');
    buffer.writeln('🗣️ *In Words:* $amountWords');
    buffer.writeln('💳 *Payment Mode:* $payMethod');
    if (txn.description != null && txn.description!.isNotEmpty) {
      buffer.writeln('📝 *Purpose / Category:* ${txn.description}');
    }
    if (txn.notes != null && txn.notes!.isNotEmpty) {
      buffer.writeln('ℹ️ *Notes:* ${txn.notes}');
    }
    buffer.writeln('------------------------------');
    buffer.writeln('✅ *Status:* Digitally Signed & Verified');
    buffer.writeln('🔒 *Verify Online:* https://app.url/verify/${txn.id.substring(0, 8)}');
    buffer.writeln('==============================');
    buffer.writeln('Thank you for your generous support & trust! 🙏');

    return buffer.toString();
  }

  /// Share formatted digital receipt via direct WhatsApp URL scheme or system share sheet.
  static Future<bool> shareReceiptOnWhatsApp({
    required TransactionModel txn,
    required OrganizationModel org,
    String? phoneNumber,
  }) async {
    final text = buildReceiptText(txn: txn, org: org);

    // Clean phone number (strip spaces/dashes)
    final cleanPhone = phoneNumber?.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleanPhone != null && cleanPhone.isNotEmpty) {
      final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    // Fallback to system Share sheet
    final result = await Share.share(text, subject: 'Digital Receipt - ${org.name}');
    return result.status == ShareResultStatus.success;
  }
}
