import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_update_dialog.dart';
import '../../../../core/widgets/create_org_dialog.dart';
import '../../../../core/widgets/festive_3d_theme_showcase.dart';
import '../../../../core/widgets/profile_edit_dialog.dart';
import '../../../../core/widgets/voice_assistant_dialog.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/whatsapp_share_service.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';
import 'package:mitra/features/organization/providers/season_providers.dart';
import 'package:mitra/features/transactions/providers/transaction_providers.dart';
import 'package:mitra/features/organization/providers/permissions_provider.dart';
import '../widgets/fundraising_goal_widget.dart';
import '../widgets/season_selector_bar.dart';

/// Vibrant, 3D Animated Dashboard Screen with Top-Right Menu/Members/Receipts actions,
/// modal Create Org popup, real Supabase transaction metrics, and live Ledger Feed.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-check for updates when opening the dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppUpdateDialog.checkAndShow(context);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = SupabaseService.currentUser;
    final activeOrg = ref.watch(activeOrgProvider);
    final txnsAsync = ref.watch(orgTransactionsProvider);

    final metadata = user?.userMetadata ?? {};
    final userName = metadata['full_name'] as String? ?? user?.email?.split('@').first ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Mitra',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // ── Compact Mobile Icons without overlap ──
          IconButton(
            icon: const Icon(Icons.people_alt_rounded, color: Color(0xFF059669), size: 22),
            tooltip: 'Members Directory',
            onPressed: () => context.push(AppRoutes.members),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706), size: 22),
            tooltip: 'All Ledger Receipts',
            onPressed: () => context.push(AppRoutes.book),
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF4F46E5), size: 22),
            tooltip: 'Menu & Settings',
            onPressed: () => context.push(AppRoutes.more),
          ),
          const SizedBox(width: 4),

          // Profile Avatar
          GestureDetector(
            onTap: () => ProfileEditDialog.show(context),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF6366F1),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userOrganizationsProvider);
            ref.invalidate(orgTransactionsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ── 1. Organization Hub & Creation Card ──
              if (activeOrg == null) ...[
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFC026D3)],
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('🏛️', style: TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome to Mitra!',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                                  ),
                                  Text(
                                    'Create or join a committee / trust to start recording entries',
                                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => CreateOrgDialog.show(context),
                                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF4F46E5)),
                                label: const Text('Create Committee'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF4F46E5),
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push(AppRoutes.joinOrg),
                                icon: const Icon(Icons.group_add_outlined, color: Colors.white),
                                label: const Text('Join Code'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Your Organizations History (Auto-load & Quick Open) ──
                Consumer(
                  builder: (context, ref, _) {
                    final userOrgsAsync = ref.watch(userOrganizationsProvider);

                    return userOrgsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (orgs) {
                        if (orgs.isEmpty) return const SizedBox.shrink();

                        // Auto-select first org if available
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (ref.read(activeOrgProvider) == null) {
                            ref.read(activeOrgProvider.notifier).setActiveOrg(orgs.first);
                          }
                        });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '🏛️ Your Organizations History',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                ),
                                Text(
                                  '${orgs.length} Available',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...orgs.map((org) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFEEF2FF),
                                  child: Text(
                                    org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
                                    style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(org.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('Code: ${org.joinCode} • ${org.orgType.toUpperCase()}'),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    ref.read(activeOrgProvider.notifier).setActiveOrg(org);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Open'),
                                ),
                              ),
                            )),
                          ],
                        );
                      },
                    );
                  },
                ),
              ] else ...[
                // ── Active Org Card ──
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              activeOrg.logoUrl ?? '🏛️',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeOrg.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${activeOrg.orgType} • ${activeOrg.location ?? 'India'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => context.push(AppRoutes.orgSwitcher),
                            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                            label: const Text('Switch'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF059669),
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Invite Code: ${activeOrg.joinCode}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // ── 2. Yearly Season / Festival Edition Switcher ──
              const SeasonSelectorBar(),
              const SizedBox(height: AppSpacing.md),

              // ── 3. Net Organization Balance Card ──
              txnsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Card(
                  color: const Color(0xFFFEF2F2),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading financial ledger: ${err.toString()}'),
                  ),
                ),
                data: (_) {
                  final activeSeason = ref.watch(activeSeasonProvider);
                  final seasonTxns = ref.watch(activeSeasonTransactionsProvider);

                  int totalIncomePaise = 0;
                  int totalExpensePaise = 0;

                  for (final t in seasonTxns) {
                    if (t.type == 'income') {
                      totalIncomePaise += t.amountPaise.toInt();
                    } else {
                      totalExpensePaise += t.amountPaise.toInt();
                    }
                  }

                  final openingBalancePaise = activeSeason?.openingBalancePaise ?? 0;
                  final netBalancePaise = openingBalancePaise + totalIncomePaise - totalExpensePaise;
                  final displayYear = activeSeason?.seasonYear ?? 2026;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '$displayYear NET BALANCE',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: const Color(0xFF475569),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    if (activeSeason?.isClosed ?? false) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'ARCHIVED',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${seasonTxns.length} Entries',
                                    style: const TextStyle(
                                      color: Color(0xFF4F46E5),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (openingBalancePaise > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Includes ${CurrencyFormatter.formatPaise(openingBalancePaise)} opening carryover',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              CurrencyFormatter.formatPaise(netBalancePaise),
                              style: AppTypography.displayLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                color: netBalancePaise >= 0 ? const Color(0xFF0F172A) : AppColors.expense,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Total Money In / Money Out Stats
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(Icons.arrow_downward_rounded, color: Color(0xFF059669), size: 16),
                                            SizedBox(width: 4),
                                            Text('Total Money In', style: TextStyle(color: Color(0xFF047857), fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormatter.formatPaise(totalIncomePaise),
                                          style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFECACA)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(Icons.arrow_upward_rounded, color: Color(0xFFDC2626), size: 16),
                                            SizedBox(width: 4),
                                            Text('Total Money Out', style: TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormatter.formatPaise(totalExpensePaise),
                                          style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 16),
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
                      const SizedBox(height: AppSpacing.lg),

                      // Fundraising Goal Progress Meter
                      FundraisingGoalWidget(totalRaisedPaise: totalIncomePaise),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── 3. Quick Action Buttons ──
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.addTransaction),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ Money In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.addTransaction),
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      label: const Text('- Money Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── 4. RECENT LEDGER TRANSACTIONS FEED (Below Money In / Money Out) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📒 Recent Ledger Entries',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.book),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              Builder(
                builder: (context) {
                  final seasonTxns = ref.watch(activeSeasonTransactionsProvider);
                  if (seasonTxns.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.menu_book_rounded, color: Color(0xFF94A3B8), size: 36),
                          SizedBox(height: 8),
                          Text('No transactions recorded for this year yet.', style: TextStyle(color: Color(0xFF64748B))),
                          Text('Tap + Money In or - Money Out to add entries', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  final recentList = seasonTxns.take(5).toList();

                  return Column(
                    children: recentList.map((t) {
                      final isIncome = t.type == 'income';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                            child: Icon(
                              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            t.description ?? (isIncome ? 'Deposit' : 'Withdrawal'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${t.personName ?? 'General'} • ${t.paymentMethod.toUpperCase()}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isIncome ? '+' : '−'}${CurrencyFormatter.formatPaise(t.amountPaise)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF25D366)),
                                tooltip: 'WhatsApp Receipt',
                                onPressed: () {
                                  if (activeOrg != null) {
                                    WhatsAppShareService.shareReceiptOnWhatsApp(
                                      txn: t,
                                      org: activeOrg,
                                      phoneNumber: t.personContact,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── 5. 3D Animated Festive Showcase ──
              Text(
                '🪔 Festive & Event Themes 2026',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '3D glassmorphic cards for Ganesh Utsav, Diwali, New Year & Tournaments',
                style: AppTypography.bodySmall.copyWith(color: const Color(0xFF475569)),
              ),
              const SizedBox(height: AppSpacing.md),

              const Festive3DThemeShowcase(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const VoiceAssistantDialog(),
          );
        },
        icon: const Icon(Icons.mic_rounded, color: Colors.white),
        label: const Text('Voice Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
