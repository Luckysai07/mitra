import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/supabase_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/organization/presentation/screens/create_org_screen.dart';
import '../../features/organization/presentation/screens/join_org_screen.dart';
import '../../features/organization/presentation/screens/org_switcher_screen.dart';
import '../../features/organization/presentation/screens/members_screen.dart';
import '../../features/organization/presentation/screens/audit_logs_screen.dart';
import '../../features/organization/presentation/screens/event_budget_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/transaction_list_screen.dart';
import '../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/more_screen.dart';
import 'scaffold_with_nav.dart';

import '../../features/organization/presentation/screens/owner_dashboard_screen.dart';

/// App-wide route names for type-safe navigation.
abstract final class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Org setup & Management
  static const String createOrg = '/org/create';
  static const String joinOrg = '/org/join';
  static const String orgSwitcher = '/org/switch';
  static const String orgSettings = '/org/settings';
  static const String members = '/org/members';
  static const String ownerDashboard = '/org/owner-dashboard';
  static const String auditLogs = '/org/audit-logs';
  static const String eventBudgets = '/org/budgets';

  // Main (inside org)
  static const String home = '/home';
  static const String book = '/book';
  static const String addTransaction = '/book/add';
  static const String reports = '/reports';
  static const String more = '/more';
}

/// GoRouter configuration with auth redirect guards.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = SupabaseService.isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.welcome;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      // On splash screen -> redirect based on auth status
      if (isSplash) {
        return isAuthenticated ? AppRoutes.home : AppRoutes.login;
      }

      // Not authenticated -> send directly to login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // Authenticated but on auth route -> send directly to home dashboard
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      return null; // No redirect
    },
    routes: [
      // ── Splash ──
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashRedirect(),
      ),

      // ── Auth routes ──
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ── Org setup & management ──
      GoRoute(
        path: AppRoutes.createOrg,
        builder: (context, state) => const CreateOrgScreen(),
      ),
      GoRoute(
        path: AppRoutes.joinOrg,
        builder: (context, state) => const JoinOrgScreen(),
      ),
      GoRoute(
        path: AppRoutes.orgSwitcher,
        builder: (context, state) => const OrgSwitcherScreen(),
      ),
      GoRoute(
        path: AppRoutes.members,
        builder: (context, state) => const MembersScreen(),
      ),
      GoRoute(
        path: AppRoutes.ownerDashboard,
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.auditLogs,
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: AppRoutes.eventBudgets,
        builder: (context, state) => const EventBudgetScreen(),
      ),
      GoRoute(
        path: AppRoutes.orgSettings,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Organization Settings')),
        ),
      ),

      // ── Main shell with bottom navigation ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.book,
                builder: (context, state) => const TransactionListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reports,
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Add Transaction ──
      GoRoute(
        path: AppRoutes.addTransaction,
        builder: (context, state) => const AddTransactionScreen(),
      ),
    ],
  );
});

/// Temporary splash screen that redirects based on auth state.
class _SplashRedirect extends StatefulWidget {
  const _SplashRedirect();

  @override
  State<_SplashRedirect> createState() => _SplashRedirectState();
}

class _SplashRedirectState extends State<_SplashRedirect> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      if (SupabaseService.isAuthenticated) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Mitra',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
