// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/main.dart';
import 'package:flutter_application/providers/language_provider.dart';

void main() {
  testWidgets('SoulBoundApp renders CreateProfilePage smoke test', (WidgetTester tester) async {
    final languageProvider = LanguageProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<LanguageProvider>.value(
        value: languageProvider,
        child: const SoulBoundApp(),
      ),
    );

    // Pump a few frames to let entrance animations run
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app rendered successfully
    expect(find.byType(SoulBoundApp), findsOneWidget);
  });
}
