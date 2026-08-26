import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../services/supabase_service.dart';
import '../../providers/org_providers.dart';
import '../../providers/season_providers.dart';

/// Interactive Member Movement (Entries & Exits) and Annual Dues Checklist tab.
class MemberLifecycleTab extends ConsumerStatefulWidget {
  const MemberLifecycleTab({super.key});

  @override
  ConsumerState<MemberLifecycleTab> createState() => _MemberLifecycleTabState();
}

class _MemberLifecycleTabState extends ConsumerState<MemberLifecycleTab> {
  final Map<String, bool> _duesPaidMap = {};

  Future<List<Map<String, dynamic>>> _fetchMemberMovement(String orgId, int selectedYear) async {
    try {
      final response = await SupabaseService.client
          .from('organization_members')
          .select('id, role, joined_at, user_id, users(full_name, email, phone)')
          .eq('org_id', orgId);

      final List<Map<String, dynamic>> memberList = [];
      for (final row in (response as List)) {
        final userData = row['users'] as Map<String, dynamic>? ?? {};
        final joinedAtStr = row['joined_at'] as String?;
        final joinedAt = joinedAtStr != null ? DateTime.parse(joinedAtStr) : DateTime.now();

        final isNewThisYear = joinedAt.year == selectedYear;
        final isContinuing = joinedAt.year < selectedYear;

        memberList.add({
          'id': row['id'] as String,
          'user_id': row['user_id'] as String,
          'name': userData['full_name'] as String? ?? 'Member',
          'email': userData['email'] as String? ?? '',
          'phone': userData['phone'] as String? ?? 'No phone',
          'role': (row['role'] as String? ?? 'member').toUpperCase(),
          'joinedAt': joinedAt,
          'isNewThisYear': isNewThisYear,
          'isContinuing': isContinuing,
          'isPaid': _duesPaidMap[row['id']] ?? true,
        });
      }

      return memberList;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrg = ref.watch(activeOrgProvider);
    final activeSeason = ref.watch(activeSeasonProvider);
    final selectedYear = activeSeason?.seasonYear ?? 2026;

    if (activeOrg == null) {
      return const Center(child: Text('No active organization selected.'));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchMemberMovement(activeOrg.id, selectedYear),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data ?? [];
        final newEntrants = members.where((m) => m['isNewThisYear'] == true).toList();
        final continuing = members.where((m) => m['isContinuing'] == true).toList();
        final totalCount = members.length;
        final paidCount = members.where((m) => m['isPaid'] == true).length;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── 1. Header Banner ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
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
                        '👥 $selectedYear Committee Roster',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalCount Total Members',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track member retention, new joiners for $selectedYear, and annual fee status.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 2. Stat Summary Pills ──
            Row(
              children: [
                _buildChurnMetricCard('🟢 New Joiners', '${newEntrants.length}', const Color(0xFFECFDF5), const Color(0xFF059669)),
                const SizedBox(width: 8),
                _buildChurnMetricCard('🔵 Continuing', '${continuing.length}', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                _buildChurnMetricCard('💳 Fees Paid', '$paidCount / $totalCount', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── 3. New Entrants in Selected Year ──
            if (newEntrants.isNotEmpty) ...[
              _buildSectionTitle('🟢 New Entrants in $selectedYear (${newEntrants.length})'),
              ...newEntrants.map((m) => _buildMemberTile(m, isNew: true)),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── 4. Continuing Veteran Members ──
            _buildSectionTitle('🔵 Continuing Committee Members (${continuing.length})'),
            if (continuing.isEmpty && newEntrants.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: const Text('No committee members registered yet.'),
              )
            else
              ...continuing.map((m) => _buildMemberTile(m, isNew: false)),
          ],
        );
      },
    );
  }

  Widget _buildChurnMetricCard(String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> m, {required bool isNew}) {
    final memberId = m['id'] as String;
    final isPaid = m['isPaid'] as bool;
    final name = m['name'] as String;
    final phone = m['phone'] as String;
    final role = m['role'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isNew ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'M',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isNew ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                role,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
        subtitle: Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        trailing: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _duesPaidMap[memberId] = !isPaid;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name marked as ${!isPaid ? 'PAID' : 'PENDING'} for this year.'),
                duration: const Duration(seconds: 1),
                backgroundColor: !isPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isPaid ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                  size: 14,
                  color: isPaid ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 4),
                Text(
                  isPaid ? 'Fee Paid' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
