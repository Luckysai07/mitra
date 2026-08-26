import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../services/supabase_service.dart';
import '../../../organization/providers/org_providers.dart';
import '../../../organization/providers/season_providers.dart';

/// Horizontal pill bar allowing the committee to switch between festival years (2025, 2026, 2027),
/// inspect historical archived records, or initialize a new annual edition.
class SeasonSelectorBar extends ConsumerWidget {
  const SeasonSelectorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrg = ref.watch(activeOrgProvider);
    final seasonsAsync = ref.watch(orgSeasonsProvider);
    final activeSeason = ref.watch(activeSeasonProvider);

    if (activeOrg == null) return const SizedBox.shrink();

    return seasonsAsync.when(
      data: (seasons) {
        if (seasons.isEmpty) return const SizedBox.shrink();

        // Auto-select current active year if not yet selected
        final selected = activeSeason ?? seasons.first;
        if (activeSeason == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(activeSeasonProvider.notifier).setActiveSeason(seasons.first);
          });
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Edition Label Icon ──
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Year:',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),

              // ── Horizontal Year Pills ──
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      ...seasons.map((season) {
                        final isSelected = season.seasonYear == selected.seasonYear;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(activeSeasonProvider.notifier).setActiveSeason(season);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                      )
                                    : null,
                                color: isSelected ? null : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4338CA)
                                      : const Color(0xFFCBD5E1),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (season.isClosed)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.lock_clock_rounded,
                                        size: 12,
                                        color: isSelected ? Colors.amberAccent : const Color(0xFF64748B),
                                      ),
                                    ),
                                  if (season.isActive)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: isSelected ? Colors.amberAccent : const Color(0xFF059669),
                                      ),
                                    ),
                                  Text(
                                    '${season.seasonYear}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? Colors.white : const Color(0xFF334155),
                                    ),
                                  ),
                                  if (season.status == 'closed') ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      'Archived',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isSelected ? Colors.white70 : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // ── Add New Year Button ──
                      InkWell(
                        onTap: () => _showAddSeasonDialog(context, ref, activeOrg.id, seasons),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 14, color: Color(0xFF059669)),
                              SizedBox(width: 2),
                              Text(
                                'Add Year',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showAddSeasonDialog(
    BuildContext context,
    WidgetRef ref,
    String orgId,
    List<FestivalSeasonModel> existingSeasons,
  ) {
    final nextYear = (existingSeasons.map((s) => s.seasonYear).fold(2026, (max, y) => y > max ? y : max)) + 1;
    final nameController = TextEditingController(text: 'Edition $nextYear');
    final budgetController = TextEditingController(text: '300000');
    final openingBalanceController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Text('Start Year $nextYear Committee'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Initialize a new yearly financial book for $nextYear while preserving all past year archives.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Festival Edition / Season Name',
                  hintText: 'e.g. Ganesh Utsav 2027',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Budget Goal (₹)',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: openingBalanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Carryover / Opening Balance (₹)',
                  prefixText: '₹ ',
                  helperText: 'Surplus carried from past year',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final budgetPaise = ((double.tryParse(budgetController.text.trim()) ?? 0) * 100).toInt();
              final openingPaise = ((double.tryParse(openingBalanceController.text.trim()) ?? 0) * 100).toInt();

              try {
                await SupabaseService.client.from('festival_periods').insert({
                  'org_id': orgId,
                  'name': nameController.text.trim(),
                  'season_year': nextYear,
                  'start_date': DateTime(nextYear, 1, 1).toIso8601String().split('T').first,
                  'target_budget_paise': budgetPaise,
                  'opening_balance_paise': openingPaise,
                  'status': 'active',
                });
              } catch (_) {
                // Ignore DB error if offline
              }

              ref.invalidate(orgSeasonsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: Text('Create $nextYear Book'),
          ),
        ],
      ),
    );
  }
}
