import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitra/app.dart';

void main() {
  testWidgets('MitraApp initializes and builds ProviderScope router', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MitraApp(),
      ),
    );

    // Verify that the app mounts and initializes the widget tree
    expect(find.byType(MitraApp), findsOneWidget);
  });
}
