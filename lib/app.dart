import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget for the Mitra app.
///
/// Sets up Material 3 theming (light + dark), GoRouter navigation,
/// and the Riverpod provider scope is expected to wrap this in main.dart.
class MitraApp extends ConsumerWidget {
  const MitraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // ── App Identity ──
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── Theming ──
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // ── Navigation ──
      routerConfig: router,
    );
  }
}
