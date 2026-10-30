// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/main.dart';
import 'package:flutter_application/providers/language_provider.dart';
import 'package:flutter_application/providers/active_profile_provider.dart';
import 'package:flutter_application/session/resolve_entry.dart';
import 'package:flutter_application/session/session_controller.dart';

class _FakeSource implements SessionDataSource {
  @override
  SessionKind sessionKind() => SessionKind.none;
  @override
  String? uid() => null;
  @override
  Future<List<String>> profileIds() async => <String>[];
  @override
  Future<Set<String>> consentKinds() async => <String>{};
  @override
  Future<EntryIntent> authIntent() async => EntryIntent.none;
  @override
  Future<void> clearIntent() async {}
  @override
  Future<void> recordConsent() async {}
}

void main() {
  testWidgets('SoulBoundApp renders smoke test', (WidgetTester tester) async {
    final languageProvider = LanguageProvider();
    final activeProfileProvider = ActiveProfileProvider();
    final sessionController = SessionController(
      source: _FakeSource(),
      profiles: activeProfileProvider,
      language: languageProvider,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
          ),
          ChangeNotifierProvider<ActiveProfileProvider>.value(
            value: activeProfileProvider,
          ),
          ChangeNotifierProvider<SessionController>.value(
            value: sessionController,
          ),
        ],
        child: const SoulBoundApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SoulBoundApp), findsOneWidget);
  });
}
