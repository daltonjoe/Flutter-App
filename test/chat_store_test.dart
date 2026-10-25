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

  test('archive key and saved fields roundtrip', () async {
    final k = ChatStore.archKey('u1', 'natal', 's1');
    expect(k, 'chat.v1.u1.natal.arch.s1');
    await ChatStore.save(
      k,
      const ChatRecord(
        msgs: [],
        loc: 'tr',
        updated: 1,
        sid: 's1',
        title: 'T',
        pa: 'p1',
        pb: 'p2',
        pn: 'A',
      ),
    );
    final r = await ChatStore.load(k);
    expect(r!.sid, 's1');
    expect(r.title, 'T');
    expect(r.pa, 'p1');
    expect(r.pb, 'p2');
    expect(r.pn, 'A');
  });

  test('purgeStale removes only old unsaved active chats', () async {
    final now = DateTime(2026, 10, 25, 12);
    final old = DateTime(2026, 10, 24, 23).millisecondsSinceEpoch;
    final today = DateTime(2026, 10, 25, 1).millisecondsSinceEpoch;
    final a = ChatStore.key('u1', 'natal', 'p1');
    final b = ChatStore.key('u1', 'forecast', 'p1');
    final c = ChatStore.key('u1', 'natal', 'p2');
    final d = ChatStore.archKey('u1', 'natal', 's9');
    final e = ChatStore.key('u2', 'natal', 'p1');
    await ChatStore.save(a, ChatRecord(msgs: [], loc: 'tr', updated: old));
    await ChatStore.save(b, ChatRecord(msgs: [], loc: 'tr', updated: old, sid: 's2'));
    await ChatStore.save(c, ChatRecord(msgs: [], loc: 'tr', updated: today));
    await ChatStore.save(d, ChatRecord(msgs: [], loc: 'tr', updated: old));
    await ChatStore.save(e, ChatRecord(msgs: [], loc: 'tr', updated: old));
    await ChatStore.setLastPartner('u1', 'p1', 'p2');
    await ChatStore.purgeStale('u1', now);
    expect(await ChatStore.load(a), isNull);
    expect(await ChatStore.load(b), isNotNull);
    expect(await ChatStore.load(c), isNotNull);
    expect(await ChatStore.load(d), isNotNull);
    expect(await ChatStore.load(e), isNotNull);
    expect(await ChatStore.lastPartner('u1', 'p1'), 'p2');
  });
}
