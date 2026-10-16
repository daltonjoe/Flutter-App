// test/glyph_test.dart
// AstroGlyphs anahtarları + Glyph widget çizimi ve semantics davranışı.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_application/core/constants/astro_glyphs.dart';
import 'package:flutter_application/presentation/widgets/components/glyph.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  setUpAll(() {
    // Test ortamında ağ yok; font getirimini kapat (fallback ile çizilir).
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('tüm anahtarlar hatasız çizilir', (tester) async {
    expect(AstroGlyphs.glyphs, isNotEmpty);

    for (final name in AstroGlyphs.glyphs.keys) {
      await tester.pumpWidget(_wrap(Glyph(name)));
      expect(tester.takeException(), isNull, reason: 'anahtar: $name');
      await tester.pumpWidget(_wrap(const Glyph('sun', size: 16)));
    }
  });

  testWidgets('bilinmeyen anahtar boş kutu döndürür', (tester) async {
    await tester.pumpWidget(_wrap(const Glyph('not_a_real_glyph')));

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(of: find.byType(Glyph), matching: find.byType(SizedBox)),
      findsWidgets,
    );
    expect(
      find.descendant(of: find.byType(Glyph), matching: find.byType(Text)),
      findsNothing,
    );
  });

  testWidgets('decorative=true semantics ağacında görünmez', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(const Glyph('sun', decorative: true, semanticLabel: 'Sun label')),
    );

    expect(find.bySemanticsLabel('Sun label'), findsNothing);
    handle.dispose();
  });

  testWidgets('decorative=false semanticLabel görünür', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(const Glyph('sun', semanticLabel: 'Sun label')),
    );

    // Unicode karakterin semantics'i üst düğümle birleşebilir; alt dizge eşleşmesi kullanılır.
    expect(find.bySemanticsLabel(RegExp('Sun label')), findsOneWidget);
    handle.dispose();
  });
}
