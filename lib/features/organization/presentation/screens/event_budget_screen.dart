import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';

/// Festival & Event Budget Planner screen.
class EventBudgetScreen extends ConsumerWidget {
  const EventBudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeOrg = ref.watch(activeOrgProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Festival Budget Planner'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Festival Hero Card ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF9800), Color(0xFFE91E63)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activeOrg != null ? activeOrg.name : 'Grand Festival 2026',
                        style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('ACTIVE BUDGET', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  const Text('Total Budget Target: ₹2,50,000', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Total Spent: ₹1,45,000 (58% allocated)', style: TextStyle(color: Colors.white70, fontSize: 13)),

                  const SizedBox(height: AppSpacing.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.58,
                      minHeight: 10,
                      backgroundColor: Colors.black26,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text('Budget vs Actual Category Breakdown', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),

            _BudgetItemTile(
              title: 'Mandap & Idol Setup',
              allocated: '₹80,000',
              spent: '₹65,000',
              progress: 0.81,
              color: Colors.deepOrange,
            ),
            _BudgetItemTile(
              title: 'Sound System & Lighting',
              allocated: '₹40,000',
              spent: '₹30,000',
              progress: 0.75,
              color: Colors.purple,
            ),
            _BudgetItemTile(
              title: 'Prasad & Catering',
              allocated: '₹50,000',
              spent: '₹25,000',
              progress: 0.50,
              color: Colors.green,
            ),
            _BudgetItemTile(
              title: 'Cultural & Security',
              allocated: '₹30,000',
              spent: '₹15,000',
              progress: 0.50,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetItemTile extends StatelessWidget {
  final String title;
  final String allocated;
  final String spent;
  final double progress;
  final Color color;

  const _BudgetItemTile({
    required this.title,
    required this.allocated,
    required this.spent,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              Text('$spent / $allocated', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
