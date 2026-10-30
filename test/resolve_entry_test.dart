import "package:flutter_test/flutter_test.dart";
import "package:flutter_application/session/resolve_entry.dart";

const _all = {"privacy", "terms"};
const _part = {"privacy"};

EntryRoute _r({
  SessionKind s = SessionKind.user,
  int? n = 0,
  Set<String>? c = _all,
  bool si = false,
  EntryIntent i = EntryIntent.none,
}) => resolveEntry(
  session: s,
  profileCount: n,
  consentKinds: c,
  showSignin: si,
  intent: i,
);

void main() {
  test("01 session none -> loading", () {
    expect(_r(s: SessionKind.none), EntryRoute.loading);
  });
  test("02 showSignin -> signin", () {
    expect(_r(s: SessionKind.anon, si: true), EntryRoute.signin);
  });
  test("03 profil hatasi -> retry", () {
    expect(_r(n: null), EntryRoute.retry);
  });
  test("04 riza hatasi -> retry", () {
    expect(_r(n: 1, c: null), EntryRoute.retry);
  });
  test("05 anon+0 riza tam -> onboarding", () {
    expect(_r(s: SessionKind.anon), EntryRoute.onboarding);
  });
  test("06 anon+0 riza yok -> onboarding", () {
    expect(_r(s: SessionKind.anon, c: <String>{}), EntryRoute.onboarding);
  });
  test("07 anon+n+riza tam -> home", () {
    expect(_r(s: SessionKind.anon, n: 1), EntryRoute.home);
  });
  test("08 user+n+riza tam -> home", () {
    expect(_r(n: 2), EntryRoute.home);
  });
  test("09 user+n+riza eksik -> home", () {
    expect(_r(n: 1, c: _part), EntryRoute.home);
  });
  test("10 user+0+riza tam intent none -> onboarding", () {
    expect(_r(), EntryRoute.onboarding);
  });
  test("11 user+0+riza tam intent signin -> notFound", () {
    expect(_r(i: EntryIntent.signin), EntryRoute.notFound);
  });
  test("12 user+0+0 intent signin -> notFound", () {
    expect(_r(c: <String>{}, i: EntryIntent.signin), EntryRoute.notFound);
  });
  test("13 user+0+0 intent none -> onboarding", () {
    expect(_r(c: <String>{}), EntryRoute.onboarding);
  });
  test("14 session none retry ve signin den once gelir", () {
    expect(
      _r(s: SessionKind.none, n: null, c: null, si: true),
      EntryRoute.loading,
    );
  });
  test("15 profil var privacy+terms -> home", () {
    expect(_r(n: 1, c: {"privacy", "terms"}), EntryRoute.home);
  });
  test("16 profil var yalniz privacy -> home", () {
    expect(_r(n: 1, c: {"privacy"}), EntryRoute.home);
  });
}
