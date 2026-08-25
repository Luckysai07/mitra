import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/festive_3d_theme_showcase.dart';

/// Welcome screen — First screen for users with 3D animation theme offers & branding.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),

              // ── Header Branding ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    AppConstants.appName,
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Transparent, Accountable & Simple Digital Book',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── 3D Animated Theme Showcase Card ──
              const Festive3DThemeShowcase(),

              const SizedBox(height: AppSpacing.xxxl),

              // ── Create Organization Button ──
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.createOrg),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Create New Organization'),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Join Organization Button ──
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.joinOrg),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Join Organization with Code'),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Log In Link ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.login),
                    child: const Text('Log In'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
