import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../services/supabase_service.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';

import '../widgets/member_lifecycle_tab.dart';

class MemberItem {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final DateTime joinedAt;

  const MemberItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.joinedAt,
  });
}

/// Member List, Multi-Year Movement & Dues Screen connected to Supabase.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  Future<List<MemberItem>> _fetchMembers(String orgId) async {
    try {
      final response = await SupabaseService.client
          .from('organization_members')
          .select('id, role, joined_at, user_id, users(full_name, email, phone)')
          .eq('org_id', orgId);

      final List<MemberItem> members = [];
      for (final row in (response as List)) {
        final userData = row['users'] as Map<String, dynamic>? ?? {};
        members.add(
          MemberItem(
            id: row['id'] as String,
            name: userData['full_name'] as String? ?? 'Member',
            email: userData['email'] as String? ?? 'No email',
            phone: userData['phone'] as String? ?? 'No phone',
            role: (row['role'] as String? ?? 'member').toUpperCase(),
            joinedAt: row['joined_at'] != null ? DateTime.parse(row['joined_at']) : DateTime.now(),
          ),
        );
      }
      return members;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeOrg = ref.watch(activeOrgProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
          title: Text(activeOrg != null ? '${activeOrg.name} Team' : 'Team & Movement'),
          bottom: const TabBar(
            indicatorColor: Color(0xFF059669),
            labelColor: Color(0xFF059669),
            unselectedLabelColor: Color(0xFF64748B),
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                icon: Icon(Icons.people_alt_rounded, size: 18),
                text: 'Member Directory',
              ),
              Tab(
                icon: Icon(Icons.compare_arrows_rounded, size: 18),
                text: 'Yearly Roster & Dues 📋',
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD97706)),
              tooltip: 'Owner Dashboard & Permissions',
              onPressed: () => context.push('/org/owner-dashboard'),
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share Invite Code',
              onPressed: () {
                if (activeOrg != null) {
                  Clipboard.setData(ClipboardData(text: activeOrg.joinCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invite Code "${activeOrg.joinCode}" copied to clipboard!'),
                      backgroundColor: AppColors.incomeLight,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ── Tab 1: Member Directory ──
            SafeArea(
              child: activeOrg == null
                  ? const Center(child: Text('No active organization selected.'))
                  : FutureBuilder<List<MemberItem>>(
                      future: _fetchMembers(activeOrg.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final members = snapshot.data ?? [];

                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      // ── Invite Card ──
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invite Code: ${activeOrg.joinCode}',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Share code with team members to join',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: activeOrg.joinCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Code Copied!')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6366F1),
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Copy'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      Text(
                        'Team Members (${members.length})',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      if (members.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xxl),
                            child: Text('No members found. Share code to invite your team!'),
                          ),
                        ),

                      ...members.map((m) {
                        final isAdmin = m.role == 'ADMIN' || m.role == 'OWNER';

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAdmin
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              foregroundColor: isAdmin ? Colors.white : colorScheme.primary,
                              child: Text(
                                m.name.isNotEmpty ? m.name[0].toUpperCase() : 'M',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(m.name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAdmin ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    m.role,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📧 ${m.email}'),
                                Text('📱 ${m.phone}'),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),

            // ── Tab 2: Member Lifecycle & Annual Dues Tracker ──
            const MemberLifecycleTab(),
          ],
        ),
      ),
    );
  }
}
