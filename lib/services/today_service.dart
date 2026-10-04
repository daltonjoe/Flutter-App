import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'astro_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';


class TodayService {
  /// POST /daily-events {profile_id, date, locale} -> Map (sözleşme: design.md)
  static Future<Map<String, dynamic>> fetch({
    required String profileId,
    required String locale,
    DateTime? date,
  }) async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) {
      throw AstroServiceException(code: 'NO_SESSION', message: 'Oturum yok.');
    }
    final d = date ?? DateTime.now();
    final day =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final tz = await _tz();
    http.Response r;
    try {
      r = await http
          .post(
            Uri.parse('${AstroService.baseUrl}/daily-events'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({
              'profile_id': profileId,
              'date': day,
              'locale': locale,
                          'timezone': ?tz,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on Exception {
      throw AstroServiceException(code: 'NETWORK_ERROR', message: 'Sunucuya bağlanılamadı.');
    }
    if (r.statusCode == 429) {
      throw AstroServiceException(code: 'RATE_LIMITED', message: 'Çok fazla istek.');
    }
    if (r.statusCode != 200) {
      throw AstroServiceException(
          code: 'HTTP_${r.statusCode}', message: 'Sunucu hatası: ${r.statusCode}');
    }
    final out = Map<String, dynamic>.from(jsonDecode(utf8.decode(r.bodyBytes)) as Map);
    await _save(profileId, locale, out);
        if (tz != null) {
      try {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          await Supabase.instance.client.from('user_settings').upsert({
            'user_id': uid,
            'current_timezone': tz,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id');
        }
      } catch (e) {
        debugPrint('user_settings upsert: $e');
      }
    }
    return out;
  }
      static Future<String?> _tz() async {
    try {
      final v = await FlutterTimezone.getLocalTimezone();
      return v.identifier.isEmpty ? null : v.identifier;
    } catch (e) {
      debugPrint('timezone: $e');
      return null;
    }
  }
  static String _ck(String pid, String loc) => 'today_last_$pid|$loc';

  static Future<void> _save(String pid, String loc, Map<String, dynamic> data) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_ck(pid, loc),
          jsonEncode({'saved_at': DateTime.now().toIso8601String(), 'data': data}));
    } catch (e) {
      debugPrint('today cache save: $e');
    }
  }

  /// Son başarılı yanıt: {'data': Map, 'saved_at': DateTime} veya null.
  static Future<Map<String, dynamic>?> cached(String pid, String loc) async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_ck(pid, loc));
      if (s == null) return null;
      final m = jsonDecode(s) as Map;
      return {
        'data': Map<String, dynamic>.from(m['data'] as Map),
        'saved_at': DateTime.parse(m['saved_at'] as String),
      };
    } catch (e) {
      debugPrint('today cache read: $e');
      return null;
    }
  }
}