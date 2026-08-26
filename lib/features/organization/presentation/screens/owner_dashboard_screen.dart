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

  Future<void> _loadPending() async {
    final activeOrg = ref.read(activeOrgProvider);
    if (activeOrg == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.client
          .from('transactions')
          .select('id, type, amount_paise, date, description, person_name, created_by, created_at')
          .eq('org_id', activeOrg.id)
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false);

      final txns = <_PendingTxn>[];
      for (final row in (response as List)) {
        // Fetch creator name
        String? creatorName;
        try {
          final userRes = await SupabaseService.client
              .from('users')
              .select('full_name')
              .eq('id', row['created_by'])
              .maybeSingle();
          creatorName = userRes?['full_name'] as String?;
        } catch (_) {}

        txns.add(_PendingTxn(
          id: row['id'] as String,
          type: row['type'] as String,
          amountPaise: (row['amount_paise'] as num).toInt(),
          date: DateTime.parse(row['date']),
          description: row['description'] as String?,
          personName: row['person_name'] as String?,
          createdBy: row['created_by'] as String,
          creatorName: creatorName,
          createdAt: DateTime.parse(row['created_at']),
        ));
      }

      if (mounted) setState(() { _pendingTxns = txns; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(String txnId, String action, {String? reason}) async {
    try {
      final user = SupabaseService.currentUser;
      final activeOrg = ref.read(activeOrgProvider);

      // Update transaction
      await SupabaseService.client.from('transactions').update({
        'approval_status': action,
        'approved_by': user?.id,
        'approved_at': DateTime.now().toIso8601String(),
        if (action == 'rejected' && reason != null) 'rejection_reason': reason,
        'updated_by': user?.id,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', txnId);

      // Log the approval action
      if (activeOrg != null) {
        await SupabaseService.client.from('approval_actions').insert({
          'org_id': activeOrg.id,
          'transaction_id': txnId,
          'action': action,
          'reason': reason,
          'performed_by': user?.id,
        });
      }

      ref.invalidate(pendingTransactionsCountProvider);
      await _loadPending();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approved' ? 'Transaction Approved ✅' : 'Transaction Rejected ❌'),
            backgroundColor: action == 'approved' ? AppColors.approved : AppColors.expense,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorLight),
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
                      for (final txn in _pendingTxns) {
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
                canApprove: widget.userPerms.canApproveTransactions,
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
  // Local copy of the matrix so we can toggle switches optimistically
  Map<String, Set<String>> _matrix = {};
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final matrixAsync = ref.watch(rolePermissionsMatrixProvider);

    return matrixAsync.when(
      data: (serverMatrix) {
        if (!_loaded) {
          _matrix = serverMatrix.map((k, v) => MapEntry(k, Set.from(v)));
          _loaded = true;
        }

        // Roles to display (not owner — owner always has everything)
        const editableRoles = ['president', 'treasurer', 'secretary', 'member', 'viewer'];

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Header Info ──
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
                          'Permission Matrix',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5B21B6),
                          ),
                        ),
                        Text(
                          'Toggle permissions for each role. Owner always has full access.',
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

            // ── Quick Highlight: Transaction Approvers ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.incomeLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.income.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.income, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Who can approve transactions?',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.approved,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _ApproverChip(role: 'owner', enabled: true, onChanged: null), // always
                      ...editableRoles.map((r) => _ApproverChip(
                            role: r,
                            enabled: _matrix[r]?.contains(Permissions.approveTransaction) ?? false,
                            onChanged: widget.userPerms.canManagePermissions
                                ? (val) => _togglePermission(r, Permissions.approveTransaction, val)
                                : null,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Full Matrix ──
            ...editableRoles.map((role) => _RolePermissionCard(
                  role: role,
                  permissions: _matrix[role] ?? {},
                  canEdit: widget.userPerms.canManagePermissions,
                  onToggle: (perm, val) => _togglePermission(role, perm, val),
                )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _togglePermission(String role, String permission, bool enable) async {
    final activeOrg = ref.read(activeOrgProvider);
    if (activeOrg == null) return;

    setState(() {
      _matrix.putIfAbsent(role, () => {});
      if (enable) {
        _matrix[role]!.add(permission);
      } else {
        _matrix[role]!.remove(permission);
      }
    });

    try {
      if (enable) {
        await SupabaseService.client.from('role_permissions').upsert({
          'org_id': activeOrg.id,
          'role_name': role,
          'permission': permission,
          'granted_by': SupabaseService.currentUser?.id,
        });
      } else {
        await SupabaseService.client
            .from('role_permissions')
            .delete()
            .eq('org_id', activeOrg.id)
            .eq('role_name', role)
            .eq('permission', permission);
      }
    } catch (e) {
      // Revert on failure
      setState(() {
        if (enable) {
          _matrix[role]!.remove(permission);
        } else {
          _matrix[role]!.add(permission);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update permission: $e'), backgroundColor: AppColors.errorLight),
        );
      }
    }
  }
}

class _ApproverChip extends StatelessWidget {
  final String role;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const _ApproverChip({required this.role, required this.enabled, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = _roleColors[role] ?? AppColors.onSurfaceVariant;

    return FilterChip(
      selected: enabled,
      label: Text(_roleLabels[role] ?? role),
      avatar: Icon(_roleIcons[role], size: 16, color: enabled ? Colors.white : color),
      selectedColor: color,
      backgroundColor: color.withOpacity(0.08),
      labelStyle: TextStyle(
        color: enabled ? Colors.white : color,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: onChanged,
    );
  }
}

class _RolePermissionCard extends StatelessWidget {
  final String role;
  final Set<String> permissions;
  final bool canEdit;
  final void Function(String permission, bool enabled) onToggle;

  const _RolePermissionCard({
    required this.role,
    required this.permissions,
    required this.canEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleColor = _roleColors[role] ?? AppColors.onSurfaceVariant;

    // Don't show manage_permissions for non-owner roles (only owner should have it)
    final editablePerms = Permissions.all.where((p) => p != Permissions.managePermissions).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: roleColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // ── Role Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLg),
                topRight: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Icon(_roleIcons[role], color: roleColor, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _roleLabels[role] ?? role,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${permissions.length} / ${editablePerms.length}',
                  style: AppTypography.labelSmall.copyWith(color: roleColor),
                ),
              ],
            ),
          ),

          // ── Permission Toggles ──
          ...editablePerms.map((perm) {
            final isEnabled = permissions.contains(perm);
            return SwitchListTile(
              dense: true,
              title: Text(
                '${Permissions.icon(perm)} ${Permissions.label(perm)}',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
                  color: isEnabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                ),
              ),
              value: isEnabled,
              activeColor: roleColor,
              onChanged: canEdit ? (val) => onToggle(perm, val) : null,
            );
          }),
        ],
      ),
    );
  }
}
