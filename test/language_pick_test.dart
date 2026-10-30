import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/providers/language_provider.dart';

void main() {
  final supported =
      LanguageProvider.supportedLanguages.map((l) => l['code']!).toList();
  test('no saved, device de -> de', () {
    expect(pickLocaleCode(null, 'de', supported), 'de');
  });
  test('no saved, device ja (unsupported) -> en', () {
    expect(pickLocaleCode(null, 'ja', supported), 'en');
  });
  test('saved tr wins over device de', () {
    expect(pickLocaleCode('tr', 'de', supported), 'tr');
  });
  test('saved unsupported xx falls back to device de', () {
    expect(pickLocaleCode('xx', 'de', supported), 'de');
  });
  test('device pt_BR -> pt', () {
    expect(pickLocaleCode(null, 'pt_BR', supported), 'pt');
  });
}
