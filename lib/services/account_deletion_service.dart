import 'package:supabase_flutter/supabase_flutter.dart';

class AccountDeletionService {
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
  }

    /// Oturum sunucuda hâlâ geçerli mi? Silinmiş kullanıcıysa yerel oturumu
  /// temizleyip yeni anonim oturum açar. Ağ hatasında dokunmaz.
  static Future<void> ensureValidSession() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) return;
    try {
      await auth.getUser();
 } on AuthRetryableFetchException {
      return; // ağ hatası: oturuma dokunma
    } on AuthException {
      try {
        await auth.signOut(scope: SignOutScope.local);
      } catch (_) {}
      await auth.signInAnonymously();
    }
  }
}
