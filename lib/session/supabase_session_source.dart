// lib/session/supabase_session_source.dart (adim 6c; main e bagli DEGIL)
import "package:shared_preferences/shared_preferences.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "resolve_entry.dart";
import "session_controller.dart";

/// Sorgu hatasi FIRLATILIR (null/bos sayilmaz); SessionController yakalar -> retry.
class SupabaseSessionSource implements SessionDataSource {
  SupabaseClient get _c => Supabase.instance.client;

  @override
  SessionKind sessionKind() {
    final u = _c.auth.currentUser;
    if (u == null) return SessionKind.none;
    return u.isAnonymous ? SessionKind.anon : SessionKind.user;
  }

  @override
  String? uid() => _c.auth.currentUser?.id;

  @override
  Future<List<String>> profileIds() async {
    final rows = await _c.from("user_profiles").select("id").order("created_at");
    return rows.map((r) => r["id"] as String).toList();
  }

  @override
  Future<Set<String>> consentKinds() async {
    final rows = await _c
        .from("user_consents")
        .select("kind")
        .inFilter("kind", ["privacy", "terms", "ai"]);
    return rows.map((r) => r["kind"] as String).toSet();
  }

  @override
  Future<EntryIntent> authIntent() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString("auth_intent") == "signin"
        ? EntryIntent.signin
        : EntryIntent.none;
  }

  @override
  Future<void> clearIntent() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove("auth_intent");
  }
}
