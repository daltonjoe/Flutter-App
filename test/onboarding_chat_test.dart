// test/onboarding_chat_test.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application/i18n/app_localizations.dart';
import 'package:flutter_application/models/onboarding_profile.dart';
import 'package:flutter_application/screens/onboarding/onboarding_chat_page.dart';

Widget _app({
  required VoidCallback onDone,
  Future<bool?> Function()? onNotification,
  Future<void> Function()? onReview,
  void Function(List<String> notes)? onNotes,
  Future<void> Function()? onInitAds,
}) {
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
        child: OnboardingChatPage(
          onDone: onDone,
          requestNotificationPermission: onNotification,
          requestReview: onReview,
          // Testte gerçek AdService.init hiç tamamlanmaz; varsayılan olarak
          // anında tamamlanan sahte init enjekte edilir.
          initAds: onInitAds ?? () async {},
          onNotes: onNotes,
        ),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // rootBundle statiktir ve testler arası paylaşılır: önceki testin FakeAsync
  // zone'unda oluşan önbellekteki asset Future'ı sonraki testte tamamlanmaz.
  // (locales/en.json yüklemesi takılıp Localizations placeholder'da kalır.)
  setUp(rootBundle.clear);

  group('OnboardingProfile', () {
    test('JSON gidiş-dönüş: şema alanları korunur', () {
      const profile = OnboardingProfile(
        goal: 'self',
        area: 'love',
        reaction: 'act',
        tone: 'soft',
        alert: 'all',
        notif: 'granted',
      );

      final decoded = jsonDecode(profile.encode()) as Map<String, dynamic>;
      expect(decoded['version'], 1);
      expect(decoded['migrated'], false);
      expect(decoded.keys.toSet(), <String>{
        'version',
        'migrated',
        'goal',
        'area',
        'reaction',
        'tone',
        'alert',
        'notif',
      });

      final back = OnboardingProfile.fromJson(decoded);
      expect(back.goal, 'self');
      expect(back.area, 'love');
      expect(back.reaction, 'act');
      expect(back.tone, 'soft');
      expect(back.alert, 'all');
      expect(back.notif, 'granted');
    });

    test('save: prefKey altına tek JSON nesnesi yazar', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const profile = OnboardingProfile(
        goal: 'horoscope',
        area: 'career',
        reaction: 'wait',
        tone: 'direct',
        alert: 'regret',
        notif: 'denied',
      );
      await profile.save();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(OnboardingProfile.prefKey);
      expect(raw, isNotNull);
      final stored = OnboardingProfile.fromJson(
        jsonDecode(raw!) as Map<String, dynamic>,
      );
      expect(stored.tone, 'direct');
      expect(stored.notif, 'denied');
    });
  });

  group('OnboardingChatPage', () {
    testWidgets('soft yol: profil yazılır, onDone çağrılır', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      var done = 0;
      var notifCalls = 0;
      var reviewCalls = 0;

      await tester.pumpWidget(
        _app(
          onDone: () => done++,
          onNotification: () async {
            notifCalls++;
            return true;
          },
          onReview: () async => reviewCalls++,
        ),
      );
      await _settle(tester);

      expect(
        find.text('What would you like to look at first?'),
        findsOneWidget,
      );
      expect(prefs.getString(OnboardingProfile.prefKey), isNull);

      await _tap(tester, 'Myself');
      // Sohbet yarıda: kısmi durum yazılmaz.
      expect(prefs.getString(OnboardingProfile.prefKey), isNull);

      await _tap(tester, 'Love');
      await _tap(tester, 'I act right away');
      await _tap(tester, 'Gently');
      expect(
        find.text(
          'Alright, I\'ll keep things warm and gentle; we won\'t rush.',
        ),
        findsOneWidget,
      );
      expect(prefs.getString(OnboardingProfile.prefKey), isNull);

      await _tap(tester, 'All of them');
      await _tap(tester, 'Allow');
      await _tap(tester, 'Yes');
      await _tap(tester, 'Continue');

      expect(done, 1);
      expect(notifCalls, 1);
      expect(reviewCalls, 1);
      expect(find.byType(TextField), findsNothing);

      final raw = prefs.getString(OnboardingProfile.prefKey);
      expect(raw, isNotNull);
      final stored = OnboardingProfile.fromJson(
        jsonDecode(raw!) as Map<String, dynamic>,
      );
      expect(stored.goal, 'self');
      expect(stored.area, 'love');
      expect(stored.reaction, 'act');
      expect(stored.tone, 'soft');
      expect(stored.alert, 'all');
      expect(stored.notif, 'granted');
    });

    testWidgets('direct yol: ret ve puan reddi', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      var done = 0;
      var notifCalls = 0;
      var reviewCalls = 0;

      await tester.pumpWidget(
        _app(
          onDone: () => done++,
          onNotification: () async {
            notifCalls++;
            return false;
          },
          onReview: () async => reviewCalls++,
        ),
      );
      await _settle(tester);

      await _tap(tester, 'My intentions');
      await _tap(tester, 'Career');
      await _tap(tester, 'I wait');
      await _tap(tester, 'Directly');
      expect(
        find.text(
          'Alright, I\'ll keep things short and clear, with nothing extra.',
        ),
        findsOneWidget,
      );

      await _tap(tester, 'Before I say something I\'d regret');
      expect(
        find.text(
          'Noted: words you may regret. I\'ll walk beside you to pause before you speak.',
        ),
        findsOneWidget,
      );

      await _tap(tester, 'Allow');
      expect(find.text('No problem. We\'ll continue.'), findsOneWidget);

      await _tap(tester, 'No');
      expect(find.text('Fine. Moving on.'), findsOneWidget);
      expect(
        find.text('That\'s all for now. Come back anytime.'),
        findsOneWidget,
      );

      await _tap(tester, 'Continue');

      expect(done, 1);
      expect(notifCalls, 1);
      expect(reviewCalls, 0);

      final raw = prefs.getString(OnboardingProfile.prefKey);
      expect(raw, isNotNull);
      final stored = OnboardingProfile.fromJson(
        jsonDecode(raw!) as Map<String, dynamic>,
      );
      expect(stored.goal, 'intentions');
      expect(stored.area, 'career');
      expect(stored.reaction, 'wait');
      expect(stored.tone, 'direct');
      expect(stored.alert, 'regret');
      expect(stored.notif, 'denied');
    });

    testWidgets('"Not now" seçilirse izin istenmez', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      var notifCalls = 0;

      await tester.pumpWidget(
        _app(
          onDone: () {},
          onNotification: () async {
            notifCalls++;
            return true;
          },
          onReview: () async {},
        ),
      );
      await _settle(tester);

      await _tap(tester, 'Myself');
      await _tap(tester, 'Love');
      await _tap(tester, 'I act right away');
      await _tap(tester, 'Gently');
      await _tap(tester, 'All of them');
      await _tap(tester, 'Not now');
      await _tap(tester, 'Yes');
      await _tap(tester, 'Continue');

      expect(notifCalls, 0);
      final raw = prefs.getString(OnboardingProfile.prefKey);
      expect(raw, isNotNull);
      final stored = OnboardingProfile.fromJson(
        jsonDecode(raw!) as Map<String, dynamic>,
      );
      expect(stored.notif, 'denied');
    });

    testWidgets('izin sorulmazsa (null) skipped yazılır', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _app(
          onDone: () {},
          onNotification: () async => null,
          onReview: () async {},
        ),
      );
      await _settle(tester);

      await _tap(tester, 'Myself');
      await _tap(tester, 'Love');
      await _tap(tester, 'I act right away');
      await _tap(tester, 'Gently');
      await _tap(tester, 'All of them');
      await _tap(tester, 'Allow');
      await _tap(tester, 'Yes');
      await _tap(tester, 'Continue');

      final raw = prefs.getString(OnboardingProfile.prefKey);
      expect(raw, isNotNull);
      final stored = OnboardingProfile.fromJson(
        jsonDecode(raw!) as Map<String, dynamic>,
      );
      expect(stored.notif, 'skipped');
    });

    testWidgets('onNotes: yarıda susar, bitince sıralı not metinleri gelir', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final seen = <List<String>>[];

      await tester.pumpWidget(
        _app(
          onDone: () {},
          onNotification: () async => true,
          onReview: () async {},
          onNotes: seen.add,
        ),
      );
      await _settle(tester);

      // Sohbet henüz bitmedi: tanıtım notu verilmez.
      await _tap(tester, 'Myself');
      expect(seen, isEmpty);

      await _tap(tester, 'Love');
      await _tap(tester, 'I act right away');
      await _tap(tester, 'Gently');
      await _tap(tester, 'All of them');
      await _tap(tester, 'Allow');
      await _tap(tester, 'Yes');
      await _tap(tester, 'Continue');

      expect(seen, hasLength(1));
      expect(seen.single, <String>[
        'My goal: getting to know myself better.',
        'The area I struggle with most: love.',
        'When something goes wrong, I usually act right away.',
        "I'd like you to alert me about: everything.",
      ]);
    });

    testWidgets('init tamamlanana kadar review adımına geçilmez', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final gate = Completer<void>();
      var initCalls = 0;

      await tester.pumpWidget(
        _app(
          onDone: () {},
          onNotification: () async => true,
          onReview: () async {},
          onInitAds: () {
            initCalls++;
            return gate.future;
          },
        ),
      );
      await _settle(tester);

      await _tap(tester, 'Myself');
      await _tap(tester, 'Love');
      await _tap(tester, 'I act right away');
      await _tap(tester, 'Gently');
      await _tap(tester, 'All of them');
      await _tap(tester, 'Allow');

      // init henüz tamamlanmadı: sohbet review adımına geçemez.
      expect(initCalls, 1);
      expect(find.text('Yes'), findsNothing);

      gate.complete();
      await _settle(tester);

      // init bitti: review adımı açılır.
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('init 30 sn icinde bitmezse akis yine de review adimina gecer', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final never = Completer<void>();

      await tester.pumpWidget(
        _app(
          onDone: () {},
          onNotification: () async => true,
          onReview: () async {},
          onInitAds: () => never.future,
        ),
      );
      await _settle(tester);

      await _tap(tester, 'Myself');
      await _tap(tester, 'Love');
      await _tap(tester, 'I act right away');
      await _tap(tester, 'Gently');
      await _tap(tester, 'All of them');
      await _tap(tester, 'Allow');

      expect(find.text('Yes'), findsNothing);

      await tester.pump(const Duration(seconds: 31));
      await _settle(tester);

      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('init hata verirse akis review adimina gecer', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(
        _app(
          onDone: () {},
          onNotification: () async => true,
          onReview: () async {},
          onInitAds: () => Future<void>.error(StateError('init failed')),
        ),
      );
      await _settle(tester);

      await _tap(tester, 'Myself');
      await _tap(tester, 'Love');
      await _tap(tester, 'I act right away');
      await _tap(tester, 'Gently');
      await _tap(tester, 'All of them');
      await _tap(tester, 'Allow');

      expect(find.text('Yes'), findsOneWidget);
    });

    testWidgets('init beklenirken sayfa kapanirsa hata atilmaz', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final gate = Completer<void>();

      await tester.pumpWidget(
        _app(
          onDone: () {},
          onNotification: () async => true,
          onReview: () async {},
          onInitAds: () => gate.future,
        ),
      );
      await _settle(tester);

      await _tap(tester, 'Myself');
      await _tap(tester, 'Love');
      await _tap(tester, 'I act right away');
      await _tap(tester, 'Gently');
      await _tap(tester, 'All of them');
      await _tap(tester, 'Allow');

      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete();
      await _settle(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
