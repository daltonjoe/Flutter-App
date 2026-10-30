import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'astro_service.dart';
import 'cusp_parser.dart';

/// 12 house cusps of a profile for notification house lines (N3).
/// Known birth time: user_chart_houses. Unknown (D4): natal chart at 12:00, cached per profile.
/// Any failure -> null (the {house} sentence is simply left out).
class ChartCuspsService {
  static Future<List<double>?> loadCusps(
    String profileId, {
    String locale = 'tr',
  }) async {
    try {
      final client = Supabase.instance.client;
      final p = await client
          .from('user_profiles')
          .select(
            'birth_date, birth_time_known, birth_city, latitude, longitude, timezone',
          )
          .eq('id', profileId)
          .maybeSingle();
      if (p == null) return null;
      if (p['birth_time_known'] != false) {
        final rows = await client
            .from('user_chart_houses')
            .select('house_id, cusp_degree')
            .eq('profile_id', profileId);
        return CuspParser.fromRows(List<Map<String, dynamic>>.from(rows as List));
      }
      final date = p['birth_date']?.toString() ?? '';
      final lat = (p['latitude'] as num?)?.toDouble();
      final lon = (p['longitude'] as num?)?.toDouble();
      final tz = p['timezone']?.toString() ?? '';
      if (date.length < 10 || lat == null || lon == null || tz.isEmpty) {
        return null;
      }
      final day = date.substring(0, 10);
      final key = 'notif_cusps_${profileId}_${day}_${lat}_$lon';
      final prefs = await SharedPreferences.getInstance();
      final cached = CuspParser.decode(prefs.getString(key));
      if (cached != null) return cached;
      final chart = await AstroService.generateNatalChart(
        birthDate: day,
        birthTime: '12:00',
        city: p['birth_city']?.toString() ?? '',
        latitude: lat,
        longitude: lon,
        timezone: tz,
        locale: locale,
      );
      if (!chart.isSuccess) return null;
      final houses = chart.houses;
      if (houses == null) return null;
      final byHouse = <int, double>{};
      for (var i = 1; i <= 12; i++) {
        final h = houses['house_$i'];
        if (h != null) byHouse[i] = h.longitude;
      }
      final cusps = CuspParser.fromLongitudes(byHouse);
      if (cusps != null) await prefs.setString(key, CuspParser.encode(cusps));
      return cusps;
    } catch (e) {
      debugPrint('ChartCuspsService failed: $e');
      return null;
    }
  }
}
