import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_update_dialog.dart';
import '../../../../core/widgets/developer_about_dialog.dart';
import '../../../../core/widgets/profile_edit_dialog.dart';
import '../../../../services/supabase_service.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';

/// More Menu screen — access to Profile Edit, Members, Receipts, Audit Logs, Budgets, Settings.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = SupabaseService.currentUser;
    final activeOrg = ref.watch(activeOrgProvider);

    final metadata = user?.userMetadata ?? {};
    final userName = metadata['full_name'] as String? ?? user?.email?.split('@').first ?? 'Member';
    final userPhone = metadata['phone_number'] as String? ?? user?.phone ?? 'Add mobile number';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── User Profile Header Card ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.6),
                  colorScheme.surfaceContainerHighest,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_iphone, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            userPhone,
                            style: AppTypography.labelSmall.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => ProfileEditDialog.show(context),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Active Org Card ──
          if (activeOrg != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_rounded, color: Color(0xFF6366F1)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeOrg.name,
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text('Invite Code: ${activeOrg.joinCode}', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.orgSwitcher),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text('Switch'),
                  ),
                ],
              ),
            ),

          // ── Organization Management ──
          const _SectionHeader(title: 'ORGANIZATION MANAGEMENT'),
          _MenuItem(
            icon: Icons.language_rounded,
            title: 'Public Transparency Page',
            subtitle: 'Share live public tally & verified receipts link',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🌐 Public Transparency Link copied: https://app.url/public/mitra'),
                  backgroundColor: AppColors.approved,
                ),
              );
            },
          ),
          _MenuItem(
            icon: Icons.auto_awesome_rounded,
            title: 'Festive & Seasonal Themes',
            subtitle: 'Ganesh Utsav, Diwali, Durga Puja, Youth Sports',
            onTap: () => context.push(AppRoutes.home),
          ),
          _MenuItem(
            icon: Icons.add_circle_outline_rounded,
            title: 'Create New Organization',
            subtitle: 'Start a new digital book for festival / group',
            onTap: () => context.push(AppRoutes.createOrg),
          ),
          _MenuItem(
            icon: Icons.group_add_outlined,
            title: 'Join Organization with Code',
            subtitle: 'Enter 8-character invite code',
            onTap: () => context.push(AppRoutes.joinOrg),
          ),
          _MenuItem(
            icon: Icons.people_outline_rounded,
            title: 'Team Members & Phone Directory',
            subtitle: 'View members, phone contacts, and roles',
            onTap: () => context.push(AppRoutes.members),
          ),
          _MenuItem(
            icon: Icons.history_rounded,
            title: 'Immutable Audit Logs',
            subtitle: 'Permanent activity and edit records',
            onTap: () => context.push(AppRoutes.auditLogs),
          ),
          _MenuItem(
            icon: Icons.pie_chart_outline_rounded,
            title: 'Festival & Event Budget Planner',
            subtitle: 'Budget targets vs actual spending',
            onTap: () => context.push(AppRoutes.eventBudgets),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Settings & Logout ──
          const _SectionHeader(title: 'ACCOUNT & SECURITY'),
          _MenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile & Mobile Number',
            onTap: () => ProfileEditDialog.show(context),
          ),
          _MenuItem(
            icon: Icons.system_update_rounded,
            title: 'Check for Updates',
            subtitle: 'Get latest features & APK download',
            iconColor: const Color(0xFF10B981),
            onTap: () => AppUpdateDialog.checkAndShow(context, showToastIfUpToDate: true),
          ),
          _MenuItem(
            icon: Icons.info_outline_rounded,
            title: 'About Developer & Copyright',
            subtitle: AppConstants.developerName,
            onTap: () => DeveloperAboutDialog.show(context),
          ),
          _MenuItem(
            icon: Icons.logout_rounded,
            title: 'Log Out',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () async {
              await SupabaseService.client.auth.signOut();
              ref.read(activeOrgProvider.notifier).clear();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Developer Copyright Footer ──
          GestureDetector(
            onTap: () => DeveloperAboutDialog.show(context),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    'Mitra v1.0.0',
                    style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.copyrightNotice,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? colorScheme.primary),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: textColor ?? colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
