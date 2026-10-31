import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, PostgrestException;

/// user_consents kind 'ai' (kolonlar bilinmediği için 3 şema varyasyonu denenir).
class AiConsentService {
  /// Rızası bu oturumda doğrulanmış kullanıcı; her soruda sorgu atılmasın diye.
  static String? _okUid;

  static Future<bool> hasAi() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null && uid == _okUid) return true;
    try {
      final rows = await Supabase.instance.client
          .from('user_consents')
          .select('kind')
          .eq('kind', 'ai')
          .limit(1);
      if (rows.isNotEmpty) _okUid = uid;
      return rows.isNotEmpty;
    } catch (e) {
      debugPrint('AiConsentService.hasAi failed: $e');
      return false;
    }
  }

  static Future<bool> revokeAi() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;
    _okUid = null;
    try {
      await Supabase.instance.client
          .from('user_consents')
          .delete()
          .eq('user_id', uid)
          .eq('kind', 'ai');
      return !(await hasAi());
    } catch (e) {
      debugPrint('AiConsentService.revokeAi failed: $e');
      return false;
    }
  }

  static Future<bool> grantAi() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;
    final variants = <Map<String, dynamic>>[
      {'user_id': uid, 'kind': 'ai', 'version': 1},
      {'user_id': uid, 'kind': 'ai'},
      {'user_id': uid, 'kind': 'ai', 'version': '1'},
    ];
    for (final v in variants) {
      try {
        await Supabase.instance.client.from('user_consents').insert(v);
        _okUid = uid;
        return true;
      } on PostgrestException catch (e) {
        if (e.code == '23505') { // zaten var
          _okUid = uid;
          return true;
        }
        debugPrint('AiConsentService.grantAi failed: ${e.code} ${e.message}');
      } catch (e) {
        debugPrint('AiConsentService.grantAi failed: $e');
      }
    }
    return false;
  }
}
