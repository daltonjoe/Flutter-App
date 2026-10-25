import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/services/chat_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pv saklanir ve yuklenir', () async {
    SharedPreferences.setMockInitialValues({});
    const k = 'chat.v1.u.natal.p1';
    await ChatStore.save(
      k,
      const ChatRecord(msgs: [], loc: 'tr', updated: 5, pv: 'a|b'),
    );
    final r = await ChatStore.load(k);
    expect(r?.pv, 'a|b');
  });

  test('setPv tarihi korur, sid eslesmezse yazmaz', () async {
    SharedPreferences.setMockInitialValues({});
    const k = 'chat.v1.u.natal.p2';
    await ChatStore.save(
      k,
      const ChatRecord(msgs: [], loc: 'tr', updated: 7, sid: 's1'),
    );
    await ChatStore.setPv(k, 'x', 'zzz');
    expect((await ChatStore.load(k))?.pv, isNull);
    await ChatStore.setPv(k, 'x', 's1');
    final r = await ChatStore.load(k);
    expect(r?.pv, 'x');
    expect(r?.updated, 7);
  });
}
