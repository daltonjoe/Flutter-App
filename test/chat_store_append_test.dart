import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/services/chat_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const k = 'chat.v1.u.natal.p1';

  ChatRecord rec(String? sid) => ChatRecord(
        msgs: [
          {'m': true, 't': 'q', 'ts': 1},
        ],
        loc: 'tr',
        updated: 1,
        sid: sid,
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('appendMsg: kayit yoksa null', () async {
    final n = await ChatStore.appendMsg(k, 'u', 'natal', {'m': false, 't': 'a'});
    expect(n, isNull);
  });

  test('appendMsg: kaydedilmemis sohbete eklenir, arsiv yazilmaz', () async {
    await ChatStore.save(k, rec(null));
    final n = await ChatStore.appendMsg(k, 'u', 'natal', {'m': false, 't': 'a'});
    expect(n!.msgs.length, 2);
    expect((await ChatStore.load(k))!.msgs.length, 2);
    expect(await ChatStore.load(ChatStore.archKey('u', 'natal', 's1')), isNull);
  });

  test('appendMsg: kayitli sohbette arsiv de guncellenir', () async {
    await ChatStore.save(k, rec('s1'));
    final n = await ChatStore.appendMsg(k, 'u', 'natal', {'m': false, 't': 'a'});
    expect(n!.msgs.last['t'], 'a');
    final a = await ChatStore.load(ChatStore.archKey('u', 'natal', 's1'));
    expect(a!.msgs.length, 2);
  });
}
