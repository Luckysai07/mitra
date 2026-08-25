import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:mitra/features/organization/providers/org_providers.dart';

/// Organization switcher — lists user's organizations and allows switching.
class OrgSwitcherScreen extends ConsumerWidget {
  const OrgSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final userOrgsAsync = ref.watch(userOrganizationsProvider);
    final activeOrg = ref.watch(activeOrgProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('My Organizations'),
      ),
      body: SafeArea(
        child: userOrgsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Error loading organizations: ${err.toString()}'),
          ),
          data: (orgs) {
            if (orgs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 72,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'No organizations joined yet',
                        style: AppTypography.titleLarge.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Create a new group ledger or join using an 8-character invite code.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.createOrg),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Create Organization'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.joinOrg),
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join Organization'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Switch Active Ledger',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Select an organization to view transactions, budget, and reports.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                ...orgs.map((org) {
                  final isSelected = activeOrg?.id == org.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withOpacity(0.4)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withOpacity(0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.lg),
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        foregroundColor: isSelected
                            ? Colors.white
                            : colorScheme.primary,
                        child: Text(
                          org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        org.name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xs),
                          Text('Code: ${org.joinCode} • ${org.orgType.replaceAll('_', ' ').toUpperCase()}'),
                          if (org.location != null && org.location!.isNotEmpty)
                            Text('📍 ${org.location}'),
                        ],
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 28)
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        ref.read(activeOrgProvider.notifier).setActiveOrg(org);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched to ${org.name}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        context.go(AppRoutes.home);
                      },
                    ),
                  );
                }),

                const SizedBox(height: AppSpacing.xxl),
                const Divider(),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.createOrg),
                        icon: const Icon(Icons.add),
                        label: const Text('New Org'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.joinOrg),
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join Code'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
