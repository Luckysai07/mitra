import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/supabase_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Catch any unhandled Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Lock to portrait on mobile safely
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Orientation setup warning: $e');
  }

  // Initialize Supabase with error safety
  try {
    await SupabaseService.initialize();
  } catch (e, stack) {
    debugPrint('Supabase initialization error: $e\n$stack');
  }

  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: MitraApp(),
    ),
  );
}
