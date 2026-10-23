import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:flutter_application/providers/active_profile_provider.dart";
import "package:flutter_application/providers/language_provider.dart";
import "package:flutter_application/session/resolve_entry.dart";
import "package:flutter_application/session/session_controller.dart";

class _Prov extends ActiveProfileProvider {
  int clears = 0;
  final List<String> sets = <String>[];
  @override
  Future<void> clearActive() async {
    clears++;
    await super.clearActive();
  }

  @override
  Future<void> setActive(String id) async {
    sets.add(id);
    await super.setActive(id);
  }
}

class _Src implements SessionDataSource {
  SessionKind kind = SessionKind.user;
  String? id = "a";
  List<String>? ids = <String>["p1"];
  Set<String>? kinds = <String>{"privacy", "terms"};
  EntryIntent intent = EntryIntent.none;
  int cleared = 0;
  @override
  SessionKind sessionKind() => kind;
  @override
  String? uid() => id;
  @override
  Future<List<String>> profileIds() async {
    if (ids == null) throw Exception("x");
    return ids!;
  }

  @override
  Future<Set<String>> consentKinds() async {
    if (kinds == null) throw Exception("x");
    return kinds!;
  }

  @override
  Future<EntryIntent> authIntent() async => intent;
  @override
  Future<void> clearIntent() async {
    cleared++;
    intent = EntryIntent.none;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Src src;
  late _Prov prov;
  late SessionController c;
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    src = _Src();
    prov = _Prov();
    c = SessionController(
      source: src,
      profiles: prov,
      language: LanguageProvider(),
    );
  });
  test("1 uid degisince clearActive", () async {
    await c.refresh();
    src.id = "b";
    await c.refresh();
    expect(prov.clears, 1);
  });
  test("2 uid ayni clearActive yok", () async {
    await c.refresh();
    await c.refresh();
    expect(prov.clears, 0);
  });
  test("3 profil hatasi retry, clearActive yok", () async {
    src.ids = null;
    await c.refresh();
    expect(c.route, EntryRoute.retry);
    expect(prov.clears, 0);
  });
  test("4 riza hatasi retry", () async {
    src.kinds = null;
    await c.refresh();
    expect(c.route, EntryRoute.retry);
  });
  test("5 intent refresh sonrasi korunur", () async {
    src.ids = <String>[];
    src.kinds = <String>{};
    src.intent = EntryIntent.signin;
    await c.refresh();
    expect(c.route, EntryRoute.notFound);
    expect(src.cleared, 0);
  });
  test("6 resolveNotFound intent siler", () async {
    src.ids = <String>[];
    src.kinds = <String>{};
    src.intent = EntryIntent.signin;
    await c.refresh();
    await c.resolveNotFound();
    expect(src.cleared, 1);
    expect(c.route, EntryRoute.consent);
  });
  test("7 profil var aktif yok setActive(first)", () async {
    await c.refresh();
    expect(prov.sets, <String>["p1"]);
    expect(c.route, EntryRoute.home);
  });
  test("8 aktif listede degil setActive(first)", () async {
    await prov.setActive("zz");
    await c.refresh();
    expect(prov.sets.last, "p1");
  });
  test("9 profil var privacy+terms -> home", () async {
    src.kinds = <String>{"privacy", "terms"};
    await c.refresh();
    expect(c.route, EntryRoute.home);
  });
  test("10 profil var yalniz privacy -> consent", () async {
    src.kinds = <String>{"privacy"};
    await c.refresh();
    expect(c.route, EntryRoute.consent);
  });
}
