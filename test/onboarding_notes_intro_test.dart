// test/onboarding_notes_intro_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/i18n/app_localizations.dart';
import 'package:flutter_application/screens/notes_page.dart';
import 'package:flutter_application/screens/onboarding/onboarding_notes_intro_page.dart';

Widget _app({required List<String> notes, required VoidCallback onDone}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: OnboardingNotesIntroPage(notes: notes, onDone: onDone),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // rootBundle statiktir ve testler arası paylaşılır (bkz. onboarding_chat_test).
  setUp(rootBundle.clear);

  testWidgets('her not için bir satır kartı görünür', (tester) async {
    await tester.pumpWidget(
      _app(notes: const ['one', 'two', 'three'], onDone: () {}),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotesRowCard), findsNWidgets(3));
    expect(find.text('3/10'), findsOneWidget);
    expect(
      find.text(
        'Your notes are a space of your own; you can add and change your own notes here whenever you like.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'kopya etkileşimsiz: IgnorePointer içinde, dokunma onDone etmez',
    (tester) async {
      var done = 0;
      await tester.pumpWidget(_app(notes: const ['one'], onDone: () => done++));
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.byType(NotesRowCard),
          matching: find.byWidgetPredicate(
            (w) => w is IgnorePointer && w.ignoring,
          ),
        ),
        findsWidgets,
      );

      await tester.tap(find.byType(NotesRowCard), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(done, 0);
    },
  );

  testWidgets('CTA onDone çağırır', (tester) async {
    var done = 0;
    await tester.pumpWidget(
      _app(notes: const ['one', 'two'], onDone: () => done++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(done, 1);
  });
}
