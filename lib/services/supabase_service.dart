import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

/// Provides the Supabase client instance to the entire app.
///
/// Initialize once in `main.dart` via [SupabaseService.initialize],
/// then access anywhere via `ref.read(supabaseClientProvider)`.
class SupabaseService {
  SupabaseService._();

  /// Initialize Supabase. Call once in `main()`.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  /// The singleton Supabase client.
  static SupabaseClient get client => Supabase.instance.client;

  /// Current authenticated user (nullable).
  static User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Whether a user is currently signed in.
  static bool get isAuthenticated => currentUser != null;

  /// Auth state change stream.
  static Stream<AuthState> get authStateChanges {
    try {
      return client.auth.onAuthStateChange;
    } catch (_) {
      return const Stream.empty();
    }
  }
}

/// Riverpod provider for the Supabase client.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});

/// Riverpod provider that streams auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.authStateChanges;
});

/// Riverpod provider for the current user (nullable).
final currentUserProvider = Provider<User?>((ref) {
  // Re-evaluate when auth state changes
  ref.watch(authStateProvider);
  return SupabaseService.currentUser;
});
