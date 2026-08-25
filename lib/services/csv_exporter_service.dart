import 'package:share_plus/share_plus.dart';

import '../core/utils/currency_formatter.dart';
import '../features/organization/providers/org_providers.dart';
import '../features/transactions/providers/transaction_providers.dart';

/// Service for exporting financial transaction ledgers into CSV spreadsheets.
class CsvExporterService {
  CsvExporterService._();

  /// Build a CSV formatted string from list of transaction entries.
  static String buildCsvContent({
    required List<TransactionModel> transactions,
    required OrganizationModel org,
  }) {
    final buffer = StringBuffer();

    // ── Header Information ──
    buffer.writeln('# FINANCIAL STATEMENT & TRANSACTION LEDGER');
    buffer.writeln('# Organization: ${org.name}');
    buffer.writeln('# Location: ${org.location ?? "N/A"}');
    buffer.writeln('# Generated Date: ${DateTime.now().toString().split(" ")[0]}');
    buffer.writeln('# Total Entries: ${transactions.length}');
    buffer.writeln('');

    // ── CSV Column Headers ──
    buffer.writeln('Txn No,Date,Type,Amount (Paise),Amount (Formatted),Person / Donor,Payment Method,Notes,Created By');

    // ── CSV Data Rows ──
    for (final t in transactions) {
      final txnNo = _escapeCsv(t.txnNumber);
      final date = t.date.toString().split(' ')[0];
      final type = t.type.toUpperCase();
      final paise = t.amountPaise;
      final amountFormatted = _escapeCsv(CurrencyFormatter.formatPaise(paise));
      final person = _escapeCsv(t.personName ?? 'General');
      final payMethod = _escapeCsv(t.paymentMethod.toUpperCase());
      final notes = _escapeCsv(t.notes ?? (t.description ?? ''));
      final createdBy = _escapeCsv(t.createdBy);

      buffer.writeln('$txnNo,$date,$type,$paise,$amountFormatted,$person,$payMethod,$notes,$createdBy');
    }

    return buffer.toString();
  }

  /// Share CSV string via system share sheet.
  static Future<bool> exportAndShareCsv({
    required List<TransactionModel> transactions,
    required OrganizationModel org,
  }) async {
    final csvData = buildCsvContent(transactions: transactions, org: org);
    final fileName = '${org.name.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}_Statement.csv';

    final result = await Share.share(
      csvData,
      subject: 'Financial Statement - ${org.name}',
    );

    return result.status == ShareResultStatus.success;
  }

  static String _escapeCsv(String input) {
    if (input.contains(',') || input.contains('"') || input.contains('\n')) {
      final escaped = input.replaceAll('"', '""');
      return '"$escaped"';
    }
    return input;
  }
}
