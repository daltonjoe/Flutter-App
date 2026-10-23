// test/nav_tour_overlay_test.dart
// K34 — İlk açılış navigasyon turu katmanı testleri.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application/widgets/navigation/nav_tour_overlay.dart';

const List<NavTourStep> _steps = <NavTourStep>[
  NavTourStep(slot: 0, title: 'Bugün', body: 'Bugünün açıklaması.'),
  NavTourStep(slot: 1, title: 'Harita', body: 'Haritanın açıklaması.'),
  NavTourStep(slot: 2, title: 'Profil', body: 'Profilin açıklaması.'),
];

Widget _host({
  List<NavTourStep> steps = _steps,
  ValueChanged<int>? onStep,
  VoidCallback? onDone,
  TextDirection direction = TextDirection.ltr,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: SizedBox.expand(
          child: NavTourOverlay(
            steps: steps,
            pillRect: () => const Rect.fromLTWH(20, 500, 360, 64),
            onStep: onStep ?? (_) {},
            onDone: onDone ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('adımlar sırayla ilerler, son dokunuşta onDone bir kez çağrılır',
      (tester) async {
    final stepped = <int>[];
    var done = 0;
    await tester.pumpWidget(_host(onStep: stepped.add, onDone: () => done++));
    await tester.pump();

    expect(stepped, <int>[0]);
    expect(done, 0);

    await tester.tap(find.byType(NavTourOverlay));
    await tester.pump(const Duration(milliseconds: 500));
    expect(stepped, <int>[0, 1]);
    expect(done, 0);

    await tester.tap(find.byType(NavTourOverlay));
    await tester.pump(const Duration(milliseconds: 500));
    expect(stepped, <int>[0, 1, 2]);
    expect(done, 0);

    await tester.tap(find.byType(NavTourOverlay));
    await tester.pump(const Duration(milliseconds: 500));
    expect(done, 1);
  });

  testWidgets('başlık ve gövde metni görünür', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();

    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Bugünün açıklaması.'), findsOneWidget);
  });

  testWidgets('RTL yönünde hatasız çizilir', (tester) async {
    await tester.pumpWidget(_host(direction: TextDirection.rtl));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Bugün'), findsOneWidget);
  });

  test('navTourSeen önce false, markSeen sonra true', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    expect(await navTourSeen(), isFalse);
    await navTourMarkSeen();
    expect(await navTourSeen(), isTrue);
  });
}
