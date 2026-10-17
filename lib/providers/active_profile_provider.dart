import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/reference_ids.dart';

/// Aktif profilin üst çubuk/özet bileşenleri için hafif görünüm verisi.
///
/// `user_profiles` tablosundan tek satırla okunur; okunamazsa null olur.
class ActiveProfileSummary {
  const ActiveProfileSummary({
    required this.id,
    required this.name,
    this.sunSignId,
    this.moonSignId,
    this.ascSignId,
    this.birthTimeKnown = false,
  });

  final String id;
  final String name;
  final int? sunSignId;
  final int? moonSignId;
  final int? ascSignId;
  final bool birthTimeKnown;

  /// 0 tabanlı burç indeksleri (yoksa null).
  int? get sunIndex => RefIds.signIndex(sunSignId);
  int? get moonIndex => RefIds.signIndex(moonSignId);
  int? get ascIndex => RefIds.signIndex(ascSignId);
}

class ActiveProfileProvider extends ChangeNotifier {
  String? activeProfileId;
  int revision = 0;

  /// Aktif profilin özeti; okunamazsa null (UI baş harf avatarına düşer).
  ActiveProfileSummary? summary;

  static const String _prefKey = 'active_profile_id';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    activeProfileId = prefs.getString(_prefKey);
    await _loadSummary();
    notifyListeners();
  }

  Future<void> setActive(String id) async {
    activeProfileId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, id);
    await _loadSummary();
    notifyListeners();
  }

  Future<void> clearActive() async {
    activeProfileId = null;
    summary = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    notifyListeners();
  }

  void bump() {
    revision++;
    notifyListeners();
    unawaited(_refreshSummary());
  }

  Future<void> _refreshSummary() async {
    await _loadSummary(force: true);
    notifyListeners();
  }

  /// `user_profiles` tablosundan YALNIZ gerekli sütunlarla tek satır okur.
  /// [force] false iken aynı id için tekrar okuma yapılmaz.
  Future<void> _loadSummary({bool force = false}) async {
    final id = activeProfileId;
    if (id == null) {
      summary = null;
      return;
    }
    if (!force && summary?.id == id) return;
    try {
      final row = await Supabase.instance.client
          .from('user_profiles')
          .select(
            'id, display_name, sun_sign_id, moon_sign_id, '
            'ascendant_sign_id, birth_time_known',
          )
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        summary = null;
        return;
      }
      summary = ActiveProfileSummary(
        id: row['id']?.toString() ?? id,
        name: row['display_name']?.toString().trim() ?? '',
        sunSignId: (row['sun_sign_id'] as num?)?.toInt(),
        moonSignId: (row['moon_sign_id'] as num?)?.toInt(),
        ascSignId: (row['ascendant_sign_id'] as num?)?.toInt(),
        birthTimeKnown: row['birth_time_known'] == true,
      );
    } catch (e) {
      debugPrint('ActiveProfileProvider summary failed: $e');
      summary = null;
    }
  }
}
