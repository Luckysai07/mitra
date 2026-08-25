import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../services/supabase_service.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';

/// Position/Role options when joining an organization.
class MemberPosition {
  final String title;
  final String roleKey;
  final String icon;

  const MemberPosition(this.title, this.roleKey, this.icon);
}

abstract final class PositionOptions {
  static const List<MemberPosition> list = [
    MemberPosition('Committee Member', 'member', '👥'),
    MemberPosition('Treasurer / Financier', 'treasurer', '💰'),
    MemberPosition('President / Leader', 'president', '👑'),
    MemberPosition('Secretary / Admin', 'secretary', '📋'),
    MemberPosition('Viewer / Auditor', 'viewer', '👁️'),
  ];
}

class JoinOrgScreen extends ConsumerStatefulWidget {
  const JoinOrgScreen({super.key});

  @override
  ConsumerState<JoinOrgScreen> createState() => _JoinOrgScreenState();
}

class _JoinOrgScreenState extends ConsumerState<JoinOrgScreen> {
  final _codeController = TextEditingController();
  String _selectedPositionRole = 'member';
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinByCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid 8-character code (e.g. ABCD1234)'),
          backgroundColor: AppColors.errorLight,
        ),
      );
      return;
    }

    final user = SupabaseService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first to join an organization.'),
          backgroundColor: AppColors.errorLight,
        ),
      );
      context.push(AppRoutes.login);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Find org by join_code
      final orgResponse = await SupabaseService.client
          .from('organizations')
          .select()
          .eq('join_code', code)
          .maybeSingle();

      if (orgResponse == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No organization found with code "$code". Check the code and try again.'),
            backgroundColor: AppColors.errorLight,
          ),
        );
        return;
      }

      final org = OrganizationModel.fromMap(orgResponse as Map<String, dynamic>);

      // 2. Check if already a member
      final existingMember = await SupabaseService.client
          .from('organization_members')
          .select()
          .eq('org_id', org.id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingMember != null) {
        ref.read(activeOrgProvider.notifier).setActiveOrg(org);
        ref.invalidate(userOrganizationsProvider);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are already a member of ${org.name}. Opened organization!'),
            backgroundColor: AppColors.incomeLight,
          ),
        );
        context.go(AppRoutes.home);
        return;
      }

      // 3. Find role_id matching selected role position
      String? roleId;
      try {
        final roleRow = await SupabaseService.client
            .from('roles')
            .select('id')
            .eq('org_id', org.id)
            .ilike('name', '%$_selectedPositionRole%')
            .limit(1)
            .maybeSingle();

        if (roleRow != null) {
          roleId = roleRow['id'] as String;
        }
      } catch (_) {}

      // 4. Join organization with selected position
      final joinPayload = <String, dynamic>{
        'org_id': org.id,
        'user_id': user.id,
        'status': 'active',
        'joined_at': DateTime.now().toIso8601String(),
      };
      if (roleId != null) {
        joinPayload['role_id'] = roleId;
      }

      await SupabaseService.client.from('organization_members').insert(joinPayload);

      ref.read(activeOrgProvider.notifier).setActiveOrg(org);
      ref.invalidate(userOrganizationsProvider);

      if (!mounted) return;

      final selectedPos = PositionOptions.list.firstWhere(
        (p) => p.roleKey == _selectedPositionRole,
        orElse: () => PositionOptions.list.first,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined ${org.name} as ${selectedPos.title}!'),
          backgroundColor: AppColors.incomeLight,
        ),
      );

      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join organization: ${e.toString()}'),
          backgroundColor: AppColors.errorLight,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareJoinLink() {
    final code = _codeController.text.trim().toUpperCase();
    final link = 'https://app.url/join?code=${code.isNotEmpty ? code : 'ABCD1234'}';
    Share.share('Join our Organization on Mitra App! 🏛️\nUse Code: ${code.isNotEmpty ? code : 'ABCD1234'}\nJoin Link: $link');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Join Organization'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Banner ──
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                      child: const Icon(
                        Icons.group_add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join an Existing Group',
                            style: AppTypography.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Enter the 8-character invite code & select your position',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Code Input ──
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                textInputAction: TextInputAction.done,
                style: AppTypography.headlineMedium.copyWith(
                  letterSpacing: 8,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: '8-Character Organization Code',
                  hintText: 'ABCD1234',
                  counterText: '',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Select Position / Role Dropdown ──
              const Text(
                'Select Your Position / Role',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPositionRole,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: PositionOptions.list.map((pos) {
                  return DropdownMenuItem<String>(
                    value: pos.roleKey,
                    child: Text('${pos.icon} ${pos.title}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPositionRole = val);
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleJoinByCode,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Join Organization'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Shareable Join Link Button
              OutlinedButton.icon(
                onPressed: _shareJoinLink,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Join Link via WhatsApp'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
