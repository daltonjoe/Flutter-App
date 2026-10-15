// lib/session/session_controller.dart (adim 6; main e bagli DEGIL)
import "dart:async";
import "package:flutter/foundation.dart";
import "../providers/active_profile_provider.dart";
import "../providers/language_provider.dart";
import "resolve_entry.dart";

abstract class SessionDataSource {
  SessionKind sessionKind();
  String? uid();
  Future<List<String>> profileIds();
  Future<Set<String>> consentKinds();
  Future<EntryIntent> authIntent();
  Future<void> clearIntent();
}

class SessionController extends ChangeNotifier {
  SessionController({
    required this.source,
    required this.profiles,
    required this.language,
  });

  final SessionDataSource source;
  final ActiveProfileProvider profiles;
  final LanguageProvider language;

  bool _showSignin = false;
  bool _seen = false;
  String? _uid;
  EntryRoute _route = EntryRoute.loading;

  EntryRoute get route => _route;
  String? get uid => _uid;
  bool get showSignin => _showSignin;

  set showSignin(bool v) {
    if (_showSignin == v) return;
    _showSignin = v;
    unawaited(refresh());
  }

  Future<EntryIntent> _intent() async {
    try {
      return await source.authIntent();
    } catch (e) {
      debugPrint("authIntent failed: $e");
      return EntryIntent.none;
    }
  }

  Future<void> refresh() async {
    final kind = source.sessionKind();
    final now = source.uid();
    if (_seen && now != _uid) {
      await profiles.clearActive();
    }
    _seen = true;
    _uid = now;
    if (kind == SessionKind.none) {
      _set(EntryRoute.loading);
      return;
    }
    List<String>? ids;
    Set<String>? kinds;
    try {
      ids = await source.profileIds();
    } catch (e) {
      debugPrint("profileIds failed: $e");
    }
    try {
      kinds = await source.consentKinds();
    } catch (e) {
      debugPrint("consentKinds failed: $e");
    }
    final intent = await _intent();
    if (ids != null) {
      final a = profiles.activeProfileId;
      if (ids.isEmpty) {
        if (a != null) await profiles.clearActive();
      } else if (a == null || !ids.contains(a)) {
        await profiles.setActive(ids.first);
      }
    }
    debugPrint("DIAG68 gate kind=${kind.name} ids=${ids?.length} kinds=${kinds?.length} intent=${intent.name} chosen=${language.chosen}");
    _set(resolveEntry(
      session: kind,
      profileCount: ids?.length,
      consentKinds: kinds,
      showSignin: _showSignin,
      intent: intent,
      languageChosen: language.chosen,
    ));
  }

  Future<void> resolveNotFound() async {
    await source.clearIntent();
    await refresh();
  }

  void _set(EntryRoute r) {
    debugPrint("DIAG68 gate route ${r.name}");
    _route = r;
    notifyListeners();
  }
}
