import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Target fundraising goal provider (in paise). Default ₹5,00,000 = 50000000 paise.
final fundraisingGoalProvider = StateProvider<int>((ref) => 50000000);

class FundraisingGoalWidget extends ConsumerWidget {
  final int totalRaisedPaise;

  const FundraisingGoalWidget({
    super.key,
    required this.totalRaisedPaise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalPaise = ref.watch(fundraisingGoalProvider);
    final percentage = (goalPaise > 0 ? (totalRaisedPaise / goalPaise) : 0.0).clamp(0.0, 1.0);
    final percentDisplay = (percentage * 100).toStringAsFixed(1);

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
                          'TARGET FUND GOAL',
                          style: AppTypography.labelSmall.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '$percentDisplay% Completed',
                          style: AppTypography.titleSmall.copyWith(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white70),
                  tooltip: 'Edit Target Goal',
                  onPressed: () => _showEditGoalDialog(context, ref, goalPaise),
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
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Target Goal', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPaise(goalPaise),
                      style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, WidgetRef ref, int currentGoalPaise) {
    final controller = TextEditingController(
      text: (currentGoalPaise / 100).toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Fundraising Target Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target Goal Amount (₹)',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final rupees = double.tryParse(controller.text.trim());
              if (rupees != null && rupees > 0) {
                ref.read(fundraisingGoalProvider.notifier).state = (rupees * 100).round();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save Target'),
          ),
        ],
      ),
    );
  }
}
