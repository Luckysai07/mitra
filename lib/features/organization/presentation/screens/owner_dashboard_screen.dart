import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../services/supabase_service.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';
import 'package:mitra/features/organization/providers/permissions_provider.dart';
import 'package:mitra/features/transactions/providers/transaction_providers.dart';

// ─────────────────────────────────────────────────────────────
// Role display helpers
// ─────────────────────────────────────────────────────────────

const _roleLabels = {
  'owner': 'Owner',
  'president': 'President',
  'treasurer': 'Treasurer',
  'secretary': 'Secretary',
  'member': 'Member',
  'viewer': 'Viewer',
};

const _roleColors = {
  'owner': Color(0xFFD97706),
  'president': Color(0xFF7C3AED),
  'treasurer': Color(0xFF2563EB),
  'secretary': Color(0xFF059669),
  'member': Color(0xFF6B7280),
  'viewer': Color(0xFF9CA3AF),
};

const _roleIcons = {
  'owner': Icons.shield_rounded,
  'president': Icons.star_rounded,
  'treasurer': Icons.account_balance_wallet_rounded,
  'secretary': Icons.edit_note_rounded,
  'member': Icons.person_rounded,
  'viewer': Icons.visibility_rounded,
};

const _allRoles = ['owner', 'president', 'treasurer', 'secretary', 'member', 'viewer'];

/// Owner Dashboard — Premium admin panel for committee management.
class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 1) {
        ref.invalidate(pendingTransactionsCountProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeOrg = ref.watch(activeOrgProvider);
    final permsAsync = ref.watch(userPermissionsProvider);
    final pendingCountAsync = ref.watch(pendingTransactionsCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Owner Dashboard'),
            if (activeOrg != null)
              Text(
                activeOrg.name,
                style: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: () {
              ref.invalidate(orgMembersWithRolesProvider);
              ref.invalidate(pendingTransactionsCountProvider);
              ref.invalidate(userPermissionsProvider);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard refreshed! 🔄'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD97706),
          labelColor: const Color(0xFFD97706),
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: [
            const Tab(
              icon: Icon(Icons.people_alt_rounded, size: 18),
              text: 'Members',
            ),
            Tab(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.pending_actions_rounded, size: 18),
                  pendingCountAsync.when(
                    data: (count) => count > 0
                        ? Positioned(
                            right: -8,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.expense,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              text: 'Approvals',
            ),
            const Tab(
              icon: Icon(Icons.admin_panel_settings_rounded, size: 18),
              text: 'Permissions',
            ),
          ],
        ),
      ),
      body: permsAsync.when(
        data: (userPerms) {
          if (!userPerms.isAdmin && !userPerms.isOrgCreator) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 64, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Access Restricted',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Only the Owner and President can access this dashboard.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _MembersTab(userPerms: userPerms),
              _ApprovalsTab(userPerms: userPerms),
              _PermissionsTab(userPerms: userPerms),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading permissions: $e')),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 1 — MEMBER MANAGEMENT
// ═══════════════════════════════════════════════════════════════

class _MembersTab extends ConsumerWidget {
  final UserPermissions userPerms;
  const _MembersTab({required this.userPerms});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeOrg = ref.watch(activeOrgProvider);
    final membersAsync = ref.watch(orgMembersWithRolesProvider);

    return membersAsync.when(
      data: (members) {
        final active = members.where((m) => m.status == 'active').toList();
        final pending = members.where((m) => m.status == 'pending').toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(orgMembersWithRolesProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ── Stats Row ──
              Row(
                children: [
                  _StatChip(
                    icon: Icons.people_rounded,
                    label: '${active.length} Active',
                    color: AppColors.income,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatChip(
                    icon: Icons.hourglass_top_rounded,
                    label: '${pending.length} Pending',
                    color: AppColors.pending,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Pending Join Requests ──
              if (pending.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_add_rounded, color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pending Join Requests (${pending.length})',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...pending.map((m) => _PendingMemberCard(
                        member: m,
                        orgId: activeOrg?.id ?? '',
                        onAction: () => ref.invalidate(orgMembersWithRolesProvider),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Active Members ──
              Text(
                'Active Members (${active.length})',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),

              ...active.map((m) => _ActiveMemberCard(
                member: m,
                orgId: activeOrg?.id ?? '',
                canManage: userPerms.canManageMembers,
                currentUserId: SupabaseService.currentUser?.id ?? '',
                onRoleChanged: () => ref.invalidate(orgMembersWithRolesProvider),
              )),

              if (active.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxxl),
                  child: Center(child: Text('No active members found.')),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingMemberCard extends StatelessWidget {
  final MemberRole member;
  final String orgId;
  final VoidCallback onAction;
  const _PendingMemberCard({required this.member, required this.orgId, required this.onAction});

  Future<void> _handleApprove(BuildContext context) async {
    try {
      await SupabaseService.client
          .from('organization_members')
          .update({'status': 'active', 'role': 'member'})
          .eq('id', member.memberId);
      onAction();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.fullName} approved and added as Member ✅'),
            backgroundColor: AppColors.approved,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorLight),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    try {
      await SupabaseService.client
          .from('organization_members')
          .delete()
          .eq('id', member.memberId);
      onAction();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.fullName} request rejected'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorLight),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFEF3C7),
            child: Text(
              member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'M',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                if (member.phone != null)
                  Text('📱 ${member.phone}', style: AppTypography.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: AppColors.income),
            tooltip: 'Approve',
            onPressed: () => _handleApprove(context),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_rounded, color: AppColors.expense),
            tooltip: 'Reject',
            onPressed: () => _handleReject(context),
          ),
        ],
      ),
    );
  }
}

class _ActiveMemberCard extends StatelessWidget {
  final MemberRole member;
  final String orgId;
  final bool canManage;
  final String currentUserId;
  final VoidCallback onRoleChanged;

  const _ActiveMemberCard({
    required this.member,
    required this.orgId,
    required this.canManage,
    required this.currentUserId,
    required this.onRoleChanged,
  });

  Future<void> _changeRole(BuildContext context, String newRole) async {
    try {
      // Get the role_id for this new role
      final roleResponse = await SupabaseService.client
          .from('roles')
          .select('id')
          .eq('org_id', orgId)
          .eq('name', newRole)
          .maybeSingle();

      await SupabaseService.client
          .from('organization_members')
          .update({
        'role': newRole,
        if (roleResponse != null) 'role_id': roleResponse['id'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', member.memberId);

      onRoleChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.fullName} is now ${_roleLabels[newRole] ?? newRole}'),
            backgroundColor: AppColors.approved,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorLight),
        );
      }
    }
  }

  Future<void> _removeMember(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.fullName} from this committee?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseService.client
          .from('organization_members')
          .delete()
          .eq('id', member.memberId);
      onRoleChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.fullName} removed from committee'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorLight),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleColor = _roleColors[member.role] ?? AppColors.onSurfaceVariant;
    final roleIcon = _roleIcons[member.role] ?? Icons.person_rounded;
    final isSelf = member.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isSelf ? AppColors.primary.withOpacity(0.4) : colorScheme.outlineVariant.withOpacity(0.3),
          width: isSelf ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.15),
          child: Icon(roleIcon, color: roleColor, size: 20),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                member.fullName,
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelf) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('You', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: roleColor.withOpacity(0.3)),
              ),
              child: Text(
                _roleLabels[member.role] ?? member.role.toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
              ),
            ),
            if (member.phone != null) ...[
              const SizedBox(width: 8),
              Text('📱 ${member.phone}', style: AppTypography.labelSmall),
            ],
          ],
        ),
        trailing: canManage && !isSelf
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    enabled: false,
                    child: Text('Change Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  ..._allRoles.where((r) => r != 'owner').map((r) => PopupMenuItem(
                        value: r,
                        child: Row(
                          children: [
                            Icon(_roleIcons[r], size: 16, color: _roleColors[r]),
                            const SizedBox(width: 8),
                            Text(_roleLabels[r] ?? r),
                            if (member.role == r) ...[
                              const Spacer(),
                              const Icon(Icons.check_rounded, size: 16, color: AppColors.income),
                            ],
                          ],
                        ),
                      )),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: '__remove__',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove_rounded, size: 16, color: AppColors.expense),
                        SizedBox(width: 8),
                        Text('Remove Member', style: TextStyle(color: AppColors.expense)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == '__remove__') {
                    _removeMember(context);
                  } else {
                    _changeRole(context, value);
                  }
                },
              )
            : null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 2 — PENDING APPROVALS
// ═══════════════════════════════════════════════════════════════

/// Represents a transaction awaiting approval.
class _PendingTxn {
  final String id;
  final String type;
  final int amountPaise;
  final DateTime date;
  final String? description;
  final String? personName;
  final String createdBy;
  final String? creatorName;
  final DateTime createdAt;

  const _PendingTxn({
    required this.id,
    required this.type,
    required this.amountPaise,
    required this.date,
    this.description,
    this.personName,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
  });
}

class _ApprovalsTab extends ConsumerStatefulWidget {
  final UserPermissions userPerms;
  const _ApprovalsTab({required this.userPerms});

  @override
  ConsumerState<_ApprovalsTab> createState() => _ApprovalsTabState();
}

class _ApprovalsTabState extends ConsumerState<_ApprovalsTab> {
  List<_PendingTxn> _pendingTxns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending({bool showLoading = true}) async {
    final activeOrg = ref.read(activeOrgProvider);
    final overrides = ref.read(approvalOverridesProvider);
    if (activeOrg == null) return;

    if (showLoading) setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.client
          .from('transactions')
          .select('id, type, amount_paise, date, description, person_name, created_by, created_at')
          .eq('org_id', activeOrg.id)
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false);

      final txns = <_PendingTxn>[];
      for (final row in (response as List)) {
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty || overrides.containsKey(id)) continue;

        // Fetch creator name safely
        String? creatorName;
        final creatorId = row['created_by']?.toString();
        if (creatorId != null && creatorId.isNotEmpty) {
          try {
            final userRes = await SupabaseService.client
                .from('users')
                .select('full_name')
                .eq('id', creatorId)
                .maybeSingle();
            creatorName = userRes?['full_name'] as String?;
          } catch (_) {}
        }

        DateTime parsedDate = DateTime.now();
        if (row['date'] != null) {
          parsedDate = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
        }

        DateTime parsedCreatedAt = DateTime.now();
        if (row['created_at'] != null) {
          parsedCreatedAt = DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now();
        }

        int amount = 0;
        if (row['amount_paise'] is num) {
          amount = (row['amount_paise'] as num).toInt();
        } else if (row['amount_paise'] != null) {
          amount = int.tryParse(row['amount_paise'].toString()) ?? 0;
        }

        txns.add(_PendingTxn(
          id: id,
          type: row['type']?.toString() ?? 'income',
          amountPaise: amount,
          date: parsedDate,
          description: row['description'] as String?,
          personName: row['person_name'] as String?,
          createdBy: creatorId ?? '',
          creatorName: creatorName,
          createdAt: parsedCreatedAt,
        ));
      }

      if (mounted) {
        setState(() {
          _pendingTxns = txns;
          if (showLoading) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && showLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(String txnId, String action, {String? reason}) async {
    // 1. Immediately record in session approval overrides for instant state consistency across app
    ref.read(approvalOverridesProvider.notifier).markStatus(txnId, action);

    // 2. Immediately remove from local list for instant UI feedback
    if (mounted) {
      setState(() {
        _pendingTxns.removeWhere((t) => t.id == txnId);
      });
    }

    try {
      final user = SupabaseService.currentUser;
      final activeOrg = ref.read(activeOrgProvider);

      // 2. Build full update payload
      final updateData = <String, dynamic>{
        'approval_status': action,
        'approved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (user?.id != null && user!.id.isNotEmpty) {
        updateData['approved_by'] = user.id;
      }
      if (action == 'rejected' && reason != null && reason.isNotEmpty) {
        updateData['rejection_reason'] = reason;
      }

      // 3. Resilient database update with fallback for missing table columns
      try {
        final res = await SupabaseService.client
            .from('transactions')
            .update(updateData)
            .eq('id', txnId)
            .select();
        
        if ((res as List).isEmpty) {
          // If 0 rows updated, try minimal approval_status update
          await SupabaseService.client
              .from('transactions')
              .update({'approval_status': action})
              .eq('id', txnId);
        }
      } catch (colErr) {
        debugPrint('Full update failed (missing columns/RLS), using minimal update: $colErr');
        await SupabaseService.client
            .from('transactions')
            .update({'approval_status': action})
            .eq('id', txnId);
      }

      // 4. Log the action to approval_actions if the table exists
      if (activeOrg != null) {
        try {
          final logData = <String, dynamic>{
            'org_id': activeOrg.id,
            'transaction_id': txnId,
            'action': action,
          };
          if (reason != null && reason.isNotEmpty) logData['reason'] = reason;
          if (user?.id != null && user!.id.isNotEmpty) logData['performed_by'] = user.id;

          await SupabaseService.client.from('approval_actions').insert(logData);
        } catch (logErr) {
          debugPrint('Approval log skipped: $logErr');
        }
      }

      // 5. Invalidate all transaction and pending count providers so Net Balance updates everywhere
      ref.invalidate(pendingTransactionsCountProvider);
      ref.invalidate(orgTransactionsProvider);
      ref.invalidate(approvedTransactionsProvider);
      ref.invalidate(pendingTransactionsProvider);

      // Quietly reload pending list from DB without full-screen loading spinner
      await _loadPending(showLoading: false);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'approved'
                  ? 'Transaction Approved ✅ (Added to Net Balance)'
                  : 'Transaction Rejected ❌',
            ),
            backgroundColor: action == 'approved' ? AppColors.approved : AppColors.expense,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Approval action error: $e');
      await _loadPending(showLoading: false);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: ${e.toString()}'),
            backgroundColor: AppColors.errorLight,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingTxns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.incomeLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded, size: 56, color: AppColors.income),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'All Clear! 🎉',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No pending transactions to review.',
                style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                onPressed: () => _loadPending(showLoading: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Check for New Submissions'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPending,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Batch Actions Bar ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions_rounded, color: Color(0xFF0369A1)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_pendingTxns.length} transaction${_pendingTxns.length > 1 ? 's' : ''} awaiting your review',
                    style: AppTypography.titleSmall.copyWith(
                      color: const Color(0xFF0369A1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.userPerms.canApproveTransactions && _pendingTxns.length > 1)
                  TextButton.icon(
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Approve All'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.income),
                    onPressed: () async {
                      final itemsToApprove = List<_PendingTxn>.from(_pendingTxns);
                      for (final txn in itemsToApprove) {
                        await _handleAction(txn.id, 'approved');
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Transaction Cards ──
          ..._pendingTxns.map((txn) => _PendingTxnCard(
                txn: txn,
                canApprove: true,
                onApprove: () => _handleAction(txn.id, 'approved'),
                onReject: () async {
                  final reason = await showDialog<String>(
                    context: context,
                    builder: (ctx) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: const Text('Rejection Reason'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Why are you rejecting this? (optional)',
                          ),
                          maxLines: 3,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, controller.text),
                            child: const Text('Reject', style: TextStyle(color: AppColors.expense)),
                          ),
                        ],
                      );
                    },
                  );
                  if (reason != null) {
                    await _handleAction(txn.id, 'rejected', reason: reason.isEmpty ? null : reason);
                  }
                },
              )),
        ],
      ),
    );
  }
}

class _PendingTxnCard extends StatelessWidget {
  final _PendingTxn txn;
  final bool canApprove;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingTxnCard({
    required this.txn,
    required this.canApprove,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = txn.type == 'income';
    final accentColor = isIncome ? AppColors.income : AppColors.expense;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: accentColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLg),
                topRight: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncome ? 'Income Entry' : 'Expense Entry',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      if (txn.description != null)
                        Text(
                          txn.description!,
                          style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatPaise(txn.amountPaise)}',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),

          // ── Details ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _DetailChip(icon: Icons.person_outline, text: txn.creatorName ?? 'Unknown'),
                const SizedBox(width: 8),
                if (txn.personName != null && txn.personName!.isNotEmpty)
                  _DetailChip(icon: Icons.swap_horiz, text: txn.personName!),
                const Spacer(),
                _DetailChip(
                  icon: Icons.calendar_today_rounded,
                  text: '${txn.date.day}/${txn.date.month}/${txn.date.year}',
                ),
              ],
            ),
          ),

          // ── Actions ──
          if (canApprove)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSpacing.radiusLg),
                  bottomRight: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.expense,
                        side: const BorderSide(color: AppColors.expense),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.income,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 3 — PERMISSIONS MATRIX
// ═══════════════════════════════════════════════════════════════

class _PermissionsTab extends ConsumerStatefulWidget {
  final UserPermissions userPerms;
  const _PermissionsTab({required this.userPerms});

  @override
  ConsumerState<_PermissionsTab> createState() => _PermissionsTabState();
}

class _PermissionsTabState extends ConsumerState<_PermissionsTab> {
  // Map of userId -> Map of permission -> isGranted boolean
  Map<String, Map<String, bool>> _memberOverrides = {};
  // Map of userId -> Overridden role string
  Map<String, String> _roleOverrides = {};
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(orgMembersWithRolesProvider);
    final activeOrg = ref.watch(activeOrgProvider);

    return membersAsync.when(
      data: (members) {
        if (!_loaded && activeOrg != null) {
          _fetchMemberOverrides(activeOrg.id);
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Header Banner ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF7C3AED), size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Member Access & Role Assignments',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5B21B6),
                          ),
                        ),
                        Text(
                          'Assign committee roles and toggle individual transaction, approval, and management permissions for each user by name.',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Member Permission Cards ──
            ...members.map((member) {
              final activeRole = _roleOverrides[member.userId] ?? member.role;
              final effectiveMember = member.copyWith(role: activeRole);

              return _MemberUserPermissionCard(
                member: effectiveMember,
                isOwnerAccount: effectiveMember.userId == activeOrg?.createdBy || effectiveMember.role == 'owner',
                userPermissions: _getEffectiveMemberPermissions(effectiveMember),
                canEdit: true,
                onTogglePermission: (perm, enable) => _toggleMemberPermission(effectiveMember.userId, perm, enable),
                onRoleChanged: (newRole) => _changeMemberRole(context, effectiveMember, newRole),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading members: $e')),
    );
  }

  Set<String> _getEffectiveMemberPermissions(MemberRole member) {
    final Set<String> perms = {};

    // Base permissions derived from assigned role
    switch (member.role.toLowerCase()) {
      case 'owner':
        perms.addAll(Permissions.all);
        break;
      case 'president':
        perms.addAll([
          Permissions.approveTransaction,
          Permissions.addTransaction,
          Permissions.editTransaction,
          Permissions.manageMembers,
          Permissions.viewReports,
        ]);
        break;
      case 'treasurer':
        // Treasurer can record/edit transactions, but requires explicit Owner grant for approvals
        perms.addAll([
          Permissions.addTransaction,
          Permissions.editTransaction,
          Permissions.viewReports,
          Permissions.exportData,
        ]);
        break;
      case 'secretary':
        perms.addAll([
          Permissions.addTransaction,
          Permissions.manageMembers,
          Permissions.viewReports,
        ]);
        break;
      case 'member':
        perms.addAll([
          Permissions.addTransaction,
          Permissions.viewReports,
        ]);
        break;
      case 'viewer':
        perms.add(Permissions.viewReports);
        break;
      default:
        perms.addAll([Permissions.addTransaction, Permissions.viewReports]);
    }

    // Merge custom overrides for this specific member (grant OR revoke)
    final userOverrides = _memberOverrides[member.userId];
    if (userOverrides != null) {
      userOverrides.forEach((perm, isGranted) {
        if (isGranted) {
          perms.add(perm);
        } else {
          perms.remove(perm);
        }
      });
    }

    return perms;
  }

  Future<void> _changeMemberRole(BuildContext context, MemberRole member, String newRole) async {
    final activeOrg = ref.read(activeOrgProvider);
    if (activeOrg == null) return;

    final oldRole = _roleOverrides[member.userId] ?? member.role;

    // 1. Instant local UI update
    setState(() {
      _roleOverrides[member.userId] = newRole;
    });

    // 2. Instant session override for provider
    ref.read(memberRoleOverridesProvider.notifier).setRoleOverride(member.userId, newRole);

    try {
      // 3. Update DB using org_id + user_id compound key (matches UNIQUE constraint)
      await SupabaseService.client
          .from('organization_members')
          .update({'role': newRole})
          .eq('org_id', activeOrg.id)
          .eq('user_id', member.userId);

      // 4. Verify the DB write actually took effect
      final verifyRes = await SupabaseService.client
          .from('organization_members')
          .select('role')
          .eq('org_id', activeOrg.id)
          .eq('user_id', member.userId)
          .maybeSingle();

      final dbRole = verifyRes?['role'] as String?;

      if (dbRole == newRole) {
        // DB update confirmed — clear session override so next re-fetch uses DB truth
        ref.read(memberRoleOverridesProvider.notifier).removeOverride(member.userId);
        ref.invalidate(orgMembersWithRolesProvider);
        ref.invalidate(userPermissionsProvider);

        if (context.mounted) {
          final roleLabel = _roleTitles[newRole] ?? newRole.toUpperCase();
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.fullName} assigned as $roleLabel ✅'),
              backgroundColor: AppColors.approved,
            ),
          );
        }
      } else {
        // DB update was silently rejected (RLS or constraint issue)
        debugPrint('Role update rejected by DB. Expected: $newRole, Got: $dbRole');
        setState(() {
          _roleOverrides[member.userId] = oldRole;
        });
        ref.read(memberRoleOverridesProvider.notifier).removeOverride(member.userId);
        ref.invalidate(orgMembersWithRolesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role update was rejected by the database. Check Supabase RLS policies.'),
              backgroundColor: AppColors.errorLight,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Role update error: $e');
      setState(() {
        _roleOverrides[member.userId] = oldRole;
      });
      ref.read(memberRoleOverridesProvider.notifier).removeOverride(member.userId);
      ref.invalidate(orgMembersWithRolesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: $e'),
            backgroundColor: AppColors.errorLight,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _fetchMemberOverrides(String orgId) async {
    try {
      final response = await SupabaseService.client
          .from('permission_overrides')
          .select('user_id, permission, is_granted')
          .eq('org_id', orgId);

      final Map<String, Map<String, bool>> overrides = {};
      for (final row in (response as List)) {
        final userId = row['user_id'] as String;
        final perm = row['permission'] as String;
        final isGranted = row['is_granted'] as bool? ?? true;
        overrides.putIfAbsent(userId, () => {})[perm] = isGranted;
      }

      if (mounted) {
        setState(() {
          _memberOverrides = overrides;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loaded = true);
      }
    }
  }

  Future<void> _toggleMemberPermission(String userId, String permission, bool enable) async {
    final activeOrg = ref.read(activeOrgProvider);
    if (activeOrg == null) return;

    // Instant local UI state update
    setState(() {
      _memberOverrides.putIfAbsent(userId, () => {})[permission] = enable;
    });

    try {
      await SupabaseService.client.from('permission_overrides').upsert({
        'org_id': activeOrg.id,
        'user_id': userId,
        'permission': permission,
        'is_granted': enable,
        'granted_by': SupabaseService.currentUser?.id,
        'granted_at': DateTime.now().toIso8601String(),
      }, onConflict: 'org_id,user_id,permission');

      ref.invalidate(userPermissionsProvider);

      if (mounted) {
        final permName = Permissions.label(permission);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enable ? '$permName enabled ✅' : '$permName disabled 🚫',
            ),
            backgroundColor: enable ? AppColors.approved : AppColors.expense,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save permission override: $e');
      setState(() {
        _memberOverrides.putIfAbsent(userId, () => {})[permission] = !enable;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update permission: $e'), backgroundColor: AppColors.errorLight),
        );
      }
    }
  }
}

const Map<String, String> _roleTitles = {
  'owner': '👑 Owner (Master Admin)',
  'president': '🎖️ President',
  'treasurer': '💰 Treasurer',
  'secretary': '📋 Secretary',
  'member': '👥 Member',
  'viewer': '👁️ Viewer',
};

class _MemberUserPermissionCard extends StatelessWidget {
  final MemberRole member;
  final bool isOwnerAccount;
  final Set<String> userPermissions;
  final bool canEdit;
  final void Function(String permission, bool enabled) onTogglePermission;
  final void Function(String newRole) onRoleChanged;

  const _MemberUserPermissionCard({
    required this.member,
    required this.isOwnerAccount,
    required this.userPermissions,
    required this.canEdit,
    required this.onTogglePermission,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final keyPermissions = [
      Permissions.approveTransaction,
      Permissions.addTransaction,
      Permissions.editTransaction,
      Permissions.voidTransaction,
      Permissions.manageMembers,
      Permissions.viewReports,
      Permissions.editOrgSettings,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isOwnerAccount ? const Color(0xFFD97706).withOpacity(0.4) : colorScheme.outlineVariant.withOpacity(0.4),
          width: isOwnerAccount ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Member Header ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isOwnerAccount ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLg),
                topRight: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isOwnerAccount ? const Color(0xFFD97706) : AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Text(
                    member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'M',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (member.email != null || member.phone != null)
                        Text(
                          member.email ?? member.phone ?? '',
                          style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (isOwnerAccount)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '👑 Owner (Full Access)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  )
                else if (canEdit)
                  // Role Selector Dropdown for Owner to assign roles to users by name
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _roleTitles.containsKey(member.role) ? member.role : 'member',
                        isDense: true,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        items: _roleTitles.entries
                            .map((e) => DropdownMenuItem<String>(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null && val != member.role) {
                            onRoleChanged(val);
                          }
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (_roleTitles[member.role] ?? member.role.toUpperCase()),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),

          // ── Permission Toggles ──
          if (isOwnerAccount)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The Owner retains master authorization across all transaction approvals, entries, member management, and settings. Owner permissions cannot be revoked.',
                      style: TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else
            ...keyPermissions.map((perm) {
              final isEnabled = userPermissions.contains(perm);
              return SwitchListTile(
                dense: true,
                title: Text(
                  '${Permissions.icon(perm)} ${Permissions.label(perm)}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
                    color: isEnabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  ),
                ),
                subtitle: perm == Permissions.approveTransaction
                    ? Text(
                        isEnabled ? 'Can review & approve pending income / expense entries' : 'Cannot approve pending entries until enabled by Owner',
                        style: TextStyle(
                          fontSize: 11,
                          color: isEnabled ? AppColors.income : AppColors.expense,
                        ),
                      )
                    : null,
                value: isEnabled,
                activeColor: AppColors.primary,
                onChanged: canEdit ? (val) => onTogglePermission(perm, val) : null,
              );
            }),
        ],
      ),
    );
  }
}
