import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application/services/chat_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('save, load and remove roundtrip', () async {
    final k = ChatStore.key('u1', 'natal', 'p1');
    expect(await ChatStore.load(k), isNull);
    await ChatStore.save(
      k,
      const ChatRecord(
        msgs: [
          {'m': true, 't': 'hi', 'b': null, 's': false},
          {'m': false, 't': 'yo', 'b': ['x', 'y'], 's': true},
        ],
        loc: 'tr',
        updated: 5,
        month: '2026-10',
      ),
    );
    final r = await ChatStore.load(k);
    expect(r!.msgs.length, 2);
    expect(r.msgs.first['t'], 'hi');
    expect(r.msgs.last['b'], ['x', 'y']);
    expect(r.loc, 'tr');
    expect(r.month, '2026-10');
    await ChatStore.remove(k);
    expect(await ChatStore.load(k), isNull);
  });

  test('modes and pairs use separate keys', () async {
    final a = ChatStore.key('u1', 'natal', 'p1');
    final b = ChatStore.key('u1', 'forecast', 'p1');
    final c = ChatStore.key('u1', 'synastry', 'p1_p2');
    final d = ChatStore.key('u1', 'synastry', 'p2_p1');
    expect({a, b, c, d}.length, 4);
    await ChatStore.save(a, const ChatRecord(msgs: [], loc: 'tr', updated: 1));
    expect(await ChatStore.load(b), isNull);
    expect(await ChatStore.load(a), isNotNull);
  });

  test('last partner is stored per account and profile', () async {
    expect(await ChatStore.lastPartner('u1', 'p1'), isNull);
    await ChatStore.setLastPartner('u1', 'p1', 'p2');
    expect(await ChatStore.lastPartner('u1', 'p1'), 'p2');
    expect(await ChatStore.lastPartner('u1', 'p3'), isNull);
  });
}
