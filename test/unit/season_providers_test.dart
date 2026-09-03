import 'package:flutter_test/flutter_test.dart';
import 'package:mitra/features/organization/providers/season_providers.dart';

void main() {
  group('Festival Season & Financial Metrics Unit Tests', () {
    test('FestivalSeasonModel creation and default values', () {
      final season = FestivalSeasonModel(
        id: 'season-2026',
        orgId: 'org-123',
        name: 'Ganesh Utsav 2026',
        seasonYear: 2026,
        startDate: DateTime(2026, 1, 1),
        openingBalancePaise: 500000, // ₹5,000.00
        targetBudgetPaise: 5000000, // ₹50,000.00
        status: 'active',
      );

      expect(season.seasonYear, equals(2026));
      expect(season.openingBalancePaise, equals(500000));
      expect(season.targetBudgetPaise, equals(5000000));
      expect(season.isActive, isTrue);
      expect(season.isClosed, isFalse);
    });

    test('YearSummaryMetric calculations for net surplus and closing balance', () {
      const summary = YearSummaryMetric(
        year: 2026,
        seasonName: 'Edition 2026',
        openingBalancePaise: 100000, // ₹1,000.00
        totalIncomePaise: 500000,   // ₹5,000.00
        totalExpensePaise: 200000,  // ₹2,000.00
        closingBalancePaise: 400000, // ₹4,000.00
        transactionCount: 5,
        categoryTotalsPaise: {'Donations': 500000, 'Decorations': 200000},
      );

      expect(summary.netSurplusPaise, equals(300000)); // ₹3,000.00 surplus
      expect(summary.closingBalancePaise, equals(400000));
      expect(summary.transactionCount, equals(5));
    });
  });
}
