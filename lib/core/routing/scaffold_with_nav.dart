import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_router.dart';
import 'package:mitra/features/organization/providers/permissions_provider.dart';

/// Main scaffold with bottom navigation bar and center FAB.
///
/// Used by [StatefulShellRoute.indexedStack] to persist
/// tab state across navigation.
class ScaffoldWithNav extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNav({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permsAsync = ref.watch(userPermissionsProvider);
    final userPerms = permsAsync.valueOrNull ?? UserPermissions.empty;
    final canAdd = userPerms.canAddTransactions || userPerms.isOwner || userPerms.isOrgCreator;

    return Scaffold(
      body: navigationShell,

      // ── Center FAB (Add Transaction) ──
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!canAdd) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ You do not have permission to add transactions in this organization.'),
                backgroundColor: AppColors.expense,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }
          context.push(AppRoutes.addTransaction);
        },
        backgroundColor: canAdd ? AppColors.primary : Colors.grey.shade400,
        elevation: canAdd ? 4 : 1,
        tooltip: canAdd ? 'Add Transaction' : 'Adding Disabled by Owner',
        child: Icon(canAdd ? Icons.add_rounded : Icons.lock_outline_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Bottom Navigation ──
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Book',
          ),
          // Spacer for FAB — using a minimal destination
          NavigationDestination(
            icon: SizedBox.shrink(),
            label: '',
            enabled: false,
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
