import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/supabase_service.dart';
import '../../transactions/providers/transaction_providers.dart';
import 'org_providers.dart';

/// Data model representing a Yearly Festival Edition / Season (e.g., 2025, 2026, 2027).
class FestivalSeasonModel {
  final String id;
  final String orgId;
  final String name;
  final int seasonYear;
  final DateTime startDate;
  final DateTime? endDate;
  final int openingBalancePaise;
  final int targetBudgetPaise;
  final String status; // 'active', 'closed', 'upcoming'

  const FestivalSeasonModel({
    required this.id,
    required this.orgId,
    required this.name,
    required this.seasonYear,
    required this.startDate,
    this.endDate,
    this.openingBalancePaise = 0,
    this.targetBudgetPaise = 0,
    this.status = 'active',
  });

  bool get isClosed => status == 'closed';
  bool get isActive => status == 'active';
  bool get isUpcoming => status == 'upcoming';

  factory FestivalSeasonModel.fromMap(Map<String, dynamic> map) {
    return FestivalSeasonModel(
      id: map['id'] as String? ?? 'season-${map['season_year'] ?? 2026}',
      orgId: map['org_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Season ${map['season_year'] ?? 2026}',
      seasonYear: (map['season_year'] as num?)?.toInt() ?? 2026,
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : DateTime(map['season_year'] ?? 2026, 1, 1),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      openingBalancePaise: (map['opening_balance_paise'] as num?)?.toInt() ?? 0,
      targetBudgetPaise: (map['target_budget_paise'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'active',
    );
  }

  FestivalSeasonModel copyWith({
    String? id,
    String? orgId,
    String? name,
    int? seasonYear,
    DateTime? startDate,
    DateTime? endDate,
    int? openingBalancePaise,
    int? targetBudgetPaise,
    String? status,
  }) {
    return FestivalSeasonModel(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      name: name ?? this.name,
      seasonYear: seasonYear ?? this.seasonYear,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      openingBalancePaise: openingBalancePaise ?? this.openingBalancePaise,
      targetBudgetPaise: targetBudgetPaise ?? this.targetBudgetPaise,
      status: status ?? this.status,
    );
  }
}

/// Provider for list of all festival seasons/years for the active organization with persistent cache.
final orgSeasonsProvider = FutureProvider<List<FestivalSeasonModel>>((ref) async {
  final activeOrg = ref.watch(activeOrgProvider);
  if (activeOrg == null) return [];

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {}

  List<FestivalSeasonModel> seasons = [];

  // 1. Fetch from Supabase Database
  try {
    final response = await SupabaseService.client
        .from('festival_periods')
        .select()
        .eq('org_id', activeOrg.id)
        .order('season_year', ascending: false);

    seasons = (response as List)
        .map((row) => FestivalSeasonModel.fromMap(row as Map<String, dynamic>))
        .toList();
  } catch (_) {}

  if (seasons.isEmpty) {
    seasons = [
      FestivalSeasonModel(
        id: 'default-${activeOrg.id}-2026',
        orgId: activeOrg.id,
        name: '${activeOrg.name} 2026',
        seasonYear: 2026,
        startDate: DateTime(2026, 1, 1),
        openingBalancePaise: 0,
        targetBudgetPaise: 0,
        status: 'active',
      ),
      FestivalSeasonModel(
        id: 'default-${activeOrg.id}-2025',
        orgId: activeOrg.id,
        name: '${activeOrg.name} 2025',
        seasonYear: 2025,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 12, 31),
        openingBalancePaise: 0,
        targetBudgetPaise: 0,
        status: 'closed',
      ),
    ];
  }

  // 2. Merge with locally cached persistent target budget if DB returned 0
  if (prefs != null) {
    seasons = seasons.map((season) {
      final cachedGoal = prefs?.getInt('target_goal_${activeOrg.id}_${season.seasonYear}') ?? 0;
      if (season.targetBudgetPaise == 0 && cachedGoal > 0) {
        return season.copyWith(targetBudgetPaise: cachedGoal);
      }
      return season;
    }).toList();
  }

  return seasons;
});

/// StateNotifier for the currently selected Active Season/Year.
class ActiveSeasonNotifier extends StateNotifier<FestivalSeasonModel?> {
  ActiveSeasonNotifier() : super(null);

  void setActiveSeason(FestivalSeasonModel season) {
    // If we already have a custom target set in memory, preserve it if the incoming season has 0
    if (state != null && state!.seasonYear == season.seasonYear && state!.targetBudgetPaise > 0 && season.targetBudgetPaise == 0) {
      state = season.copyWith(targetBudgetPaise: state!.targetBudgetPaise);
    } else {
      state = season;
    }
  }

  void updateTargetGoal(int newGoalPaise) {
    if (state != null) {
      state = state!.copyWith(targetBudgetPaise: newGoalPaise);
    }
  }

  void reset() {
    state = null;
  }
}

/// Provider for the currently active/selected season in the UI.
final activeSeasonProvider = StateNotifierProvider<ActiveSeasonNotifier, FestivalSeasonModel?>((ref) {
  return ActiveSeasonNotifier();
});

/// Provider for APPROVED transactions filtered by the currently active/selected season year (for net balance computation).
final activeSeasonTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final allTxnsAsync = ref.watch(orgTransactionsProvider);
  final activeSeason = ref.watch(activeSeasonProvider);

  return allTxnsAsync.when(
    data: (txns) {
      final approvedTxns = txns.where((t) => t.approvalStatus == 'approved');
      if (activeSeason == null) return approvedTxns.toList();
      return approvedTxns.where((t) => t.date.year == activeSeason.seasonYear).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Data class holding summary metrics for a specific year.
class YearSummaryMetric {
  final int year;
  final String seasonName;
  final int openingBalancePaise;
  final int totalIncomePaise;
  final int totalExpensePaise;
  final int closingBalancePaise;
  final int transactionCount;
  final Map<String, int> categoryTotalsPaise;

  const YearSummaryMetric({
    required this.year,
    required this.seasonName,
    required this.openingBalancePaise,
    required this.totalIncomePaise,
    required this.totalExpensePaise,
    required this.closingBalancePaise,
    required this.transactionCount,
    required this.categoryTotalsPaise,
  });

  int get netSurplusPaise => totalIncomePaise - totalExpensePaise;
}

/// Provider computing Year-over-Year (YoY) comparison metrics across all available years (APPROVED ONLY).
final multiYearComparisonProvider = Provider<List<YearSummaryMetric>>((ref) {
  final allTxnsAsync = ref.watch(orgTransactionsProvider);
  final seasonsAsync = ref.watch(orgSeasonsProvider);

  final rawTxns = allTxnsAsync.value ?? [];
  final txns = rawTxns.where((t) => t.approvalStatus == 'approved').toList();
  final seasons = seasonsAsync.value ?? [];

  // Collect distinct years
  final yearsSet = <int>{2025, 2026};
  for (final t in txns) {
    yearsSet.add(t.date.year);
  }
  for (final s in seasons) {
    yearsSet.add(s.seasonYear);
  }

  final sortedYears = yearsSet.toList()..sort((a, b) => a.compareTo(b)); // Ascending

  final List<YearSummaryMetric> summaries = [];
  int previousClosingPaise = 0;

  for (final year in sortedYears) {
    final yearTxns = txns.where((t) => t.date.year == year).toList();

    int income = 0;
    int expense = 0;
    final Map<String, int> catTotals = {};

    for (final t in yearTxns) {
      if (t.type == 'income') {
        income += t.amountPaise;
      } else {
        expense += t.amountPaise;
      }

      final catKey = t.description?.split(':').last.trim() ?? 'General';
      catTotals[catKey] = (catTotals[catKey] ?? 0) + t.amountPaise;
    }

    final matchingSeason = seasons.where((s) => s.seasonYear == year).firstOrNull;
    final openingBalance = matchingSeason?.openingBalancePaise != 0
        ? (matchingSeason?.openingBalancePaise ?? previousClosingPaise)
        : previousClosingPaise;

    final closingBalance = openingBalance + income - expense;
    previousClosingPaise = closingBalance > 0 ? closingBalance : 0;

    summaries.add(
      YearSummaryMetric(
        year: year,
        seasonName: matchingSeason?.name ?? 'Edition $year',
        openingBalancePaise: openingBalance,
        totalIncomePaise: income,
        totalExpensePaise: expense,
        closingBalancePaise: closingBalance,
        transactionCount: yearTxns.length,
        categoryTotalsPaise: catTotals,
      ),
    );
  }

  return summaries;
});
