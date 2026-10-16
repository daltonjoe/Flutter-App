// Ev anlamını Supabase'ten çeker (Faz 8). Metin yoksa null döner => panel yer tutucu gösterir.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HouseMeaningService {
  const HouseMeaningService._();

  static final Map<String, String> _cache = <String, String>{};

  static Future<String?> fetch({
    required int house,
    required String locale,
  }) async {
    final key = '$locale|$house';
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final text = await _query(house, locale);
      if (text != null) {
        _cache[key] = text;
        return text;
      }
      if (locale != 'en') {
        final fallback = await _query(house, 'en');
        if (fallback != null) {
          _cache[key] = fallback;
          return fallback;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HouseMeaningService.fetch failed ($locale|$house): $e');
      }
      return null;
    }
  }

  static Future<String?> _query(int house, String locale) async {
    final rows = await Supabase.instance.client
        .from('astrological_house_translations')
        .select('meaning')
        .eq('house_id', house)
        .eq('locale', locale)
        .limit(1);
    if (rows.isEmpty) return null;
    final raw = rows.first['meaning'];
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
