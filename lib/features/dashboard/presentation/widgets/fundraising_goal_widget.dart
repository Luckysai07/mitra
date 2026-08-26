import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../services/supabase_service.dart';
import '../../../organization/providers/org_providers.dart';
import '../../../organization/providers/season_providers.dart';

/// Target fundraising goal meter.
/// Reads and persists real target budget values for the active festival edition (defaults to ₹0 until set).
class FundraisingGoalWidget extends ConsumerWidget {
  final int totalRaisedPaise;

  const FundraisingGoalWidget({
    super.key,
    required this.totalRaisedPaise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrg = ref.watch(activeOrgProvider);
    final activeSeason = ref.watch(activeSeasonProvider);
    final goalPaise = activeSeason?.targetBudgetPaise ?? 0;
    final selectedYear = activeSeason?.seasonYear ?? 2026;

    final isGoalSet = goalPaise > 0;
    final percentage = isGoalSet ? (totalRaisedPaise / goalPaise).clamp(0.0, 1.0) : 0.0;
    final percentDisplay = isGoalSet ? '${(percentage * 100).toStringAsFixed(1)}%' : 'Not Set';

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$selectedYear TARGET FUND GOAL',
                          style: AppTypography.labelSmall.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          isGoalSet ? '$percentDisplay Completed' : 'Tap ✏️ to set your goal',
                          style: AppTypography.titleSmall.copyWith(
                            color: isGoalSet ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.amberAccent, size: 26),
                  tooltip: 'Edit $selectedYear Target Goal',
                  onPressed: () => _showEditGoalDialog(context, ref, activeOrg, activeSeason, goalPaise, selectedYear),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Animated Progress Bar ──
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 12,
                backgroundColor: const Color(0xFF334155),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGoalSet ? const Color(0xFF10B981) : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Raised vs Goal Figures ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Raised', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPaise(totalRaisedPaise),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showEditGoalDialog(context, ref, activeOrg, activeSeason, goalPaise, selectedYear),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Row(
                        children: [
                          Text('Target Goal', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.edit_outlined, color: Colors.amberAccent, size: 12),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isGoalSet ? CurrencyFormatter.formatPaise(goalPaise) : '₹0 (Set Goal)',
                        style: TextStyle(
                          color: isGoalSet ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(
    BuildContext context,
    WidgetRef ref,
    OrganizationModel? activeOrg,
    FestivalSeasonModel? activeSeason,
    int currentGoalPaise,
    int selectedYear,
  ) {
    final controller = TextEditingController(
      text: currentGoalPaise > 0 ? (currentGoalPaise / 100).toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.track_changes_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Text('Set $selectedYear Target Goal'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the total fundraising / budget target for the $selectedYear festival edition.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Target Goal Amount (₹)',
                hintText: 'e.g. 150000 or 50000',
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final inputRupees = double.tryParse(controller.text.trim()) ?? 0;
              final newGoalPaise = (inputRupees * 100).round();

              // 1. Immediately update in-memory state
              ref.read(activeSeasonProvider.notifier).updateTargetGoal(newGoalPaise);
              if (activeSeason != null) {
                final updated = activeSeason.copyWith(targetBudgetPaise: newGoalPaise);
                ref.read(activeSeasonProvider.notifier).setActiveSeason(updated);
              }

              // 2. Persist to local SharedPreferences immediately (infallible client storage)
              if (activeOrg != null) {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('target_goal_${activeOrg.id}_$selectedYear', newGoalPaise);
                } catch (_) {}

                // 3. Persist to Supabase Database
                try {
                  await SupabaseService.client.from('festival_periods').upsert({
                    'org_id': activeOrg.id,
                    'season_year': selectedYear,
                    'name': activeSeason?.name ?? '${activeOrg.name} $selectedYear',
                    'target_budget_paise': newGoalPaise,
                    'status': 'active',
                  });
                } catch (_) {
                  try {
                    await SupabaseService.client
                        .from('festival_periods')
                        .update({'target_budget_paise': newGoalPaise})
                        .eq('org_id', activeOrg.id);
                  } catch (_) {}
                }

                // Invalidate provider so cache updates
                ref.invalidate(orgSeasonsProvider);
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      newGoalPaise > 0
                          ? 'Target goal updated to ${CurrencyFormatter.formatPaise(newGoalPaise)} for $selectedYear!'
                          : 'Target goal reset to ₹0.',
                    ),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Target'),
          ),
        ],
      ),
    );
  }
}
