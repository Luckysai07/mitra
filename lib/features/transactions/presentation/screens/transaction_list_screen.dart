import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../services/whatsapp_share_service.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';
import 'package:mitra/features/transactions/providers/transaction_providers.dart';

/// Transaction List Screen displaying live ledger transactions from Supabase.
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final txnsAsync = ref.watch(orgTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Book Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Entry',
            onPressed: () => context.push(AppRoutes.addTransaction),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Entries'),
            Tab(text: 'Income (+)'),
            Tab(text: 'Expense (-)'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: SafeArea(
        child: txnsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading ledger: $err')),
          data: (txns) {
            final filterIndex = _tabController.index;
            final filteredList = txns.where((t) {
              if (filterIndex == 1) return t.type == 'income';
              if (filterIndex == 2) return t.type == 'expense';
              return true;
            }).toList();

            if (filteredList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                      const SizedBox(height: AppSpacing.md),
                      Text('No transaction entries yet', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Tap "+ Add Entry" to record income, donations, or expenses.', textAlign: TextAlign.center, style: AppTypography.bodySmall),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.addTransaction),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Entry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(orgTransactionsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: filteredList.length,
                itemBuilder: (context, idx) {
                  final t = filteredList[idx];
                  final isExpense = t.type == 'expense';

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isExpense
                            ? AppColors.expense.withOpacity(0.12)
                            : AppColors.income.withOpacity(0.12),
                        child: Icon(
                          isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: isExpense ? AppColors.expense : AppColors.income,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.description ?? (isExpense ? 'Expense' : 'Income'),
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (t.approvalStatus == 'pending') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.pending.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.pending.withOpacity(0.4)),
                              ),
                              child: const Text(
                                '⏳ Pending',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.pending),
                              ),
                            ),
                          ] else if (t.approvalStatus == 'rejected') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.expense.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '❌ Rejected',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.expense),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${t.personName ?? 'General'} • ${t.paymentMethod.toUpperCase()} • ${t.date.toString().split(' ')[0]}',
                        style: AppTypography.bodySmall,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isExpense ? '−' : '+'}${CurrencyFormatter.formatPaise(t.amountPaise)}',
                            style: AppTypography.transactionAmount.copyWith(
                              color: isExpense ? AppColors.expense : AppColors.income,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF25D366)),
                            tooltip: 'Share WhatsApp Receipt',
                            onPressed: () {
                              final activeOrg = ref.read(activeOrgProvider);
                              final orgToUse = activeOrg ?? OrganizationModel(
                                id: t.orgId,
                                name: 'Mitra Association',
                                orgType: 'General',
                                joinCode: 'MITRA2026',
                                createdBy: t.createdBy,
                                createdAt: t.createdAt,
                              );
                              WhatsAppShareService.shareReceiptOnWhatsApp(
                                txn: t,
                                org: orgToUse,
                                phoneNumber: t.personContact,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addTransaction),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Entry'),
      ),
    );
  }
}
