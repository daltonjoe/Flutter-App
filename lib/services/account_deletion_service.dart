import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:flutter_application/diag68.dart";

class AccountDeletionService {
  /// Yeni anonim uid acildiktan sonra eski uid'e ait aktif profili sil.
  static Future<void> _clearActive69() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove("active_profile_id");
    } catch (_) {}
  }

  /// 89: yalniz sunucuda sil; yerel oturum ve profil dokunulmaz.
  static Future<void> deleteRemoteOnly() async {
    final response = await Supabase.instance.client.functions.invoke(
      "delete-account",
    );
    if (response.status < 200 || response.status >= 300) {
      throw Exception("remote delete failed");
    }
  }

  static Future<void> deleteAccount() async {
    final response = await Supabase.instance.client.functions.invoke(
      'delete-account',
    );

    if (response.status < 200 || response.status >= 300) {
      final error = response.data is Map
          ? (response.data as Map)['error']?.toString()
          : null;
      throw Exception(error ?? 'Account deletion failed');
    }

    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
    await Supabase.instance.client.auth.signInAnonymously();
    await _clearActive69();
    diag68("delete after-anon");
  }

    /// Oturum sunucuda hâlâ geçerli mi? Silinmiş kullanıcıysa yerel oturumu
  /// temizleyip yeni anonim oturum açar. Ağ hatasında dokunmaz.
  static Future<void> ensureValidSession() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) return;
    diag68("ensure pre", "exp_in_s=${(auth.currentSession?.expiresAt ?? 0) - DateTime.now().millisecondsSinceEpoch ~/ 1000}");
    try {
      await auth.getUser();
 } on AuthRetryableFetchException {
      return; // ağ hatası: oturuma dokunma
    } on AuthException catch (e) {
      diag68("ensure getUser FAIL", "type=${e.runtimeType} status=${e.statusCode} msg=${e.message} str=${e.toString()}");
      diag68("ensure before-signout");
      try {
        await auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
      await auth.signInAnonymously();
      await _clearActive69();
      diag68("ensure after-anon");
    }
  }
}
