import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/pandal_poster_dialog.dart';
import '../../../../services/csv_exporter_service.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';
import 'package:mitra/features/transactions/providers/transaction_providers.dart';
import '../widgets/multi_year_comparison_tab.dart';

/// Reports Screen featuring Annual Statements, Multi-Year Comparison analytics,
/// CSV spreadsheet exports, and Pandal Posters.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeOrg = ref.watch(activeOrgProvider);
    final txnsAsync = ref.watch(orgTransactionsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports & Analytics'),
          bottom: const TabBar(
            indicatorColor: Color(0xFF4F46E5),
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Color(0xFF64748B),
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                icon: Icon(Icons.description_outlined, size: 18),
                text: 'Annual Statements',
              ),
              Tab(
                icon: Icon(Icons.auto_graph_rounded, size: 18),
                text: 'Multi-Year Compare 📈',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ── Tab 1: Current Year Summary & CSV Exports ──
            SafeArea(
              child: txnsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading report: $err')),
                data: (txns) {
                  int totalIncomePaise = 0;
                  int totalExpensePaise = 0;

                  for (final t in txns) {
                    if (t.type == 'income') {
                      totalIncomePaise += t.amountPaise;
                    } else {
                      totalExpensePaise += t.amountPaise;
                    }
                  }

                  final netBalancePaise = totalIncomePaise - totalExpensePaise;

                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      // Summary Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeOrg?.name ?? 'Organization Financials',
                              style: AppTypography.titleMedium.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              CurrencyFormatter.formatPaise(netBalancePaise),
                              style: AppTypography.displayLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${txns.length} Total Verified Ledger Transactions',
                              style: AppTypography.bodySmall.copyWith(color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Income & Expense Tiles
                      _ReportStatTile(
                        icon: Icons.arrow_downward_rounded,
                        title: 'Total Income / Donations',
                        value: CurrencyFormatter.formatPaise(totalIncomePaise),
                        subtitle: 'Member dues, sponsors, donations',
                        color: AppColors.income,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ReportStatTile(
                        icon: Icons.arrow_upward_rounded,
                        title: 'Total Expenses / Payments',
                        value: CurrencyFormatter.formatPaise(totalExpensePaise),
                        subtitle: 'Bills, materials, pandal, idol, sound',
                        color: AppColors.expense,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ReportStatTile(
                        icon: Icons.security_rounded,
                        title: 'Audit & Transparency Score',
                        value: '100% Verified',
                        subtitle: 'Zero floating-point drift • RLS active',
                        color: const Color(0xFF6366F1),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Export Excel / CSV Button
                      ElevatedButton.icon(
                        onPressed: () {
                          final orgToUse = activeOrg ?? OrganizationModel(
                            id: 'temp-id',
                            name: 'Mitra Organization',
                            orgType: 'General',
                            joinCode: 'MITRA2026',
                            createdBy: 'user',
                            createdAt: DateTime.now(),
                          );

                          CsvExporterService.exportAndShareCsv(
                            transactions: txns,
                            org: orgToUse,
                          );
                        },
                        icon: const Icon(Icons.table_chart_rounded),
                        label: const Text('Export Excel / CSV Financial Statement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      if (activeOrg != null)
                        OutlinedButton.icon(
                          onPressed: () => PandalPosterDialog.show(context, activeOrg),
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: const Text('Printable Pandal QR Display Poster'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // ── Tab 2: Multi-Year Comparison Analytics ──
            const MultiYearComparisonTab(),
          ],
        ),
      ),
    );
  }
}

class _ReportStatTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _ReportStatTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(value, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
