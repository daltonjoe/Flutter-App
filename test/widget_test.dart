// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/main.dart';
import 'package:flutter_application/providers/language_provider.dart';
import 'package:flutter_application/providers/active_profile_provider.dart';

void main() {
  testWidgets('SoulBoundApp renders smoke test', (WidgetTester tester) async {
    final languageProvider = LanguageProvider();
    final activeProfileProvider = ActiveProfileProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
          ),
          ChangeNotifierProvider<ActiveProfileProvider>.value(
            value: activeProfileProvider,
          ),
        ],
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
