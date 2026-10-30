import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/providers/ask_context_provider.dart';
import 'package:flutter_application/services/notification_tap_logic.dart';

void main() {
  test('parse valid payload', () {
    final r = parseTapPayload('2026-11-09|morning');
    expect(r, isNotNull);
    expect(r!.day, '2026-11-09');
    expect(r.slot, 'evening' == r.slot ? 'evening' : 'morning');
  });

  test('parse invalid payloads', () {
    expect(parseTapPayload(null), isNull);
    expect(parseTapPayload(''), isNull);
    expect(parseTapPayload('2026-11-09'), isNull);
    expect(parseTapPayload('2026-11-09|noon'), isNull);
    expect(parseTapPayload('9-11-2026|morning'), isNull);
    expect(parseTapPayload('2026-11-09|morning|x'), isNull);
  });

  test('tab for target', () {
    expect(tabForTarget('ask'), kAskTab);
    expect(tabForTarget('match'), 3);
    expect(tabForTarget('forecast'), 0);
    expect(tabForTarget('today'), 0);
    expect(tabForTarget('zzz'), 0);
  });
}
