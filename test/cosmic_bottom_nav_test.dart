// test/cosmic_bottom_nav_test.dart
// CosmicBottomNav ("hap" bar) — düzen / dokunma / etiket görünürlüğü testleri.
//
// Etiketler düz string'dir; AppLocalizations gerektirmez.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/providers/ask_context_provider.dart';
import 'package:flutter_application/widgets/navigation/cosmic_bottom_nav.dart';

const List<String> _labels = <String>[
  'Today',
  'Chart',
  'Ask',
  'Match',
  'Profile',
];

const List<IconData> _icons = <IconData>[
  Icons.wb_sunny_outlined,
  Icons.public_outlined,
  Icons.auto_awesome_outlined,
  Icons.favorite_border,
  Icons.person_outline,
];

const List<IconData> _activeIcons = <IconData>[
  Icons.wb_sunny,
  Icons.public,
  Icons.auto_awesome,
  Icons.favorite,
  Icons.person,
];

/// [count] adet sekme (3/4/5). 5 öğede sonuncusunun `index`'i [kAskTab].
List<CosmicNavItem> _items(int count) => <CosmicNavItem>[
      for (var i = 0; i < count; i++)
        CosmicNavItem(
          index: i,
          icon: _icons[i],
          activeIcon: _activeIcons[i],
          label: _labels[i],
        ),
    ];

Widget _app({
  required List<CosmicNavItem> items,
  required int selectedIndex,
  ValueChanged<int>? onTap,
  double textScale = 1.0,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: CosmicBottomNav(
              items: items,
              selectedIndex: selectedIndex,
              onTap: onTap ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpAt(
  WidgetTester tester,
  Size logicalSize,
  Widget widget,
) async {
  tester.view.physicalSize = logicalSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
  // pumpAndSettle KULLANILMAZ: Ask "nefes" animasyonu sonsuz döngüdür.
  await tester.pump();
}

/// Ağacı boşaltır: tekrarlı glow animasyonu dispose edilsin.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

const List<Size> _sizes = <Size>[Size(360, 640), Size(320, 568)];

void main() {
  for (final count in <int>[3, 4, 5]) {
    group('$count öğe', () {
      for (final size in _sizes) {
        for (final scale in <double>[1.0, 1.3]) {
          testWidgets(
            'taşma yok — ${size.width.toInt()}x${size.height.toInt()} '
            'textScale $scale',
            (tester) async {
              await _pumpAt(
                tester,
                size,
                _app(
                  items: _items(count),
                  selectedIndex: 0,
                  textScale: scale,
                ),
              );

              expect(tester.takeException(), isNull);
              expect(find.byType(CosmicBottomNav), findsOneWidget);

              await _unmount(tester);
            },
          );
        }
      }

      testWidgets('dokunma doğru index ile onTap çağırır', (tester) async {
        final taps = <int>[];
        final items = _items(count);
        await _pumpAt(
          tester,
          const Size(360, 640),
          _app(items: items, selectedIndex: 0, onTap: taps.add),
        );

        // Seçili olmayan son öğeye dokun.
        final target = items[count - 1];
        await tester.tap(find.byIcon(target.icon));
        await tester.pump();

        expect(taps, <int>[target.index]);

        await _unmount(tester);
      });

      testWidgets('yalnızca aktif etiket görünür', (tester) async {
        await _pumpAt(
          tester,
          const Size(360, 640),
          _app(items: _items(count), selectedIndex: 1),
        );

        expect(find.text(_labels[1]), findsOneWidget); // Chart (aktif)
        expect(find.text(_labels[0]), findsNothing); // Today (pasif)

        await _unmount(tester);
      });
    });
  }

  testWidgets('Ask sekmesi kAskTab index taşır (glow yolu)', (tester) async {
    final items = _items(5);
    expect(items.last.index, kAskTab);

    await _pumpAt(
      tester,
      const Size(360, 640),
      _app(items: items, selectedIndex: kAskTab),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(_labels.last), findsOneWidget);

    await _unmount(tester);
  });
}
