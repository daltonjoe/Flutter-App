import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, PostgrestException;

/// user_consents kind 'ai' (kolonlar bilinmediÄŸi iÃ§in 3 ÅŸema varyasyonu denenir).
class AiConsentService {
  static Future<bool> hasAi() async {
    try {
      final rows = await Supabase.instance.client
          .from('user_consents')
          .select('kind')
          .eq('kind', 'ai')
          .limit(1);
      return rows.isNotEmpty;
    } catch (e) {
      debugPrint('AiConsentService.hasAi failed: $e');
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
        return true;
      } on PostgrestException catch (e) {
        if (e.code == '23505') return true; // zaten var
        debugPrint('AiConsentService.grantAi failed: ${e.code} ${e.message}');
      } catch (e) {
        debugPrint('AiConsentService.grantAi failed: $e');
      }
    }
    return false;
  }
}
