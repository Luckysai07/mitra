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

/// Reports Screen featuring live financial analytics, CSV spreadsheet exports, and Pandal Posters.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeOrg = ref.watch(activeOrgProvider);
    final txnsAsync = ref.watch(orgTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Statements'),
      ),
      body: SafeArea(
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
                // ── Summary Card ──
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
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Organization Cash Flow',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatPaise(netBalancePaise),
                        style: AppTypography.balanceAmount.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Income', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                                Text(
                                  CurrencyFormatter.formatPaise(totalIncomePaise),
                                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 36, color: Colors.white24),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Expense', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                                  Text(
                                    CurrencyFormatter.formatPaise(totalExpensePaise),
                                    style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Financial Health Breakdown ──
                Text('Financial Health Breakdown', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),

                _ReportStatTile(
                  icon: Icons.pie_chart_rounded,
                  title: 'Income vs Expense Ratio',
                  value: totalIncomePaise > 0
                      ? '${((totalExpensePaise / totalIncomePaise) * 100).toStringAsFixed(1)}% Expense Ratio'
                      : 'No entries recorded',
                  subtitle: 'Calculated from total recorded entries',
                  color: colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ReportStatTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'Total Recorded Entries',
                  value: '${txns.length} Transactions',
                  subtitle: 'Real-time database sync',
                  color: AppColors.income,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Export Actions ──
                ElevatedButton.icon(
                  onPressed: () {
                    final orgToUse = activeOrg ?? OrganizationModel(
                      id: 'org-demo',
                      name: 'Mitra Association',
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
