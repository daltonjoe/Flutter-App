import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, PostgrestException;

/// Zorunlu rıza sürümü (privacy + terms).
const int kConsentVersion = 1;

/// Zorunlu rıza (privacy + terms) kaydı; asla throw etmez.
class ConsentService {
  /// "İleri" onayında privacy ve terms satırlarını yazar.
  static Future<void> recordAccept() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    for (final kind in const ['privacy', 'terms']) {
      try {
        await Supabase.instance.client.from('user_consents').insert({
          'user_id': uid,
          'kind': kind,
          'version': kConsentVersion,
          'accepted_at': DateTime.now().toUtc().toIso8601String(),
        });
      } on PostgrestException catch (e) {
        if (e.code == '23505') continue; // zaten var
        debugPrint('ConsentService.recordAccept failed: ${e.code} ${e.message}');
        await _retryNoDate(uid, kind);
      } catch (e) {
        debugPrint('ConsentService.recordAccept failed: $e');
        await _retryNoDate(uid, kind);
      }
    }
  }

  static Future<void> _retryNoDate(String uid, String kind) async {
    try {
      await Supabase.instance.client.from('user_consents').insert({
        'user_id': uid,
        'kind': kind,
        'version': kConsentVersion,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      debugPrint('ConsentService.recordAccept retry failed: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('ConsentService.recordAccept retry failed: $e');
    }
  }

  /// privacy + terms tamam mı; hata halinde false.
  static Future<bool> hasRequired() async {
    try {
      final rows = await Supabase.instance.client
          .from('user_consents')
          .select('kind')
          .inFilter('kind', ['privacy', 'terms']);
      final kinds = rows.map((r) => r['kind']).toSet();
      return kinds.contains('privacy') && kinds.contains('terms');
    } catch (e) {
      debugPrint('ConsentService.hasRequired failed: $e');
      return false;
    }
  }
}
