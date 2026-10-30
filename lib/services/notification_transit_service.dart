import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'astro_service.dart';

/// Backend calls of N7: personal transit texts and tap-time question.
class NotificationTransitService {
  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Pure: POST /notification-transits response -> {day: notification text}.
  static Map<String, String> parseTransits(dynamic json) {
    final out = <String, String>{};
    if (json is! Map) return out;
    final items = json['items'];
    if (items is! List) return out;
    for (final it in items) {
      if (it is! Map) continue;
      final day = it['day'];
      final text = it['notification'];
      if (day is! String || text is! String) continue;
      if (text.trim().isEmpty) continue;
      out[day] = text.trim();
    }
    return out;
  }

  /// Strong transit texts per day (D8). Any failure -> empty map (shared text stays).
  static Future<Map<String, String>> fetch({
    required String profileId,
    required DateTime start,
    required String locale,
    int days = 30,
  }) async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) return <String, String>{};
    try {
      final r = await http
          .post(
            Uri.parse('${AstroService.baseUrl}/notification-transits'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({
              'profile_id': profileId,
              'start': _fmt(start),
              'days': days,
              'locale': locale,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return <String, String>{};
      return parseTransits(jsonDecode(utf8.decode(r.bodyBytes)));
    } catch (e) {
      debugPrint('NotificationTransitService.fetch failed: $e');
      return <String, String>{};
    }
  }

  /// POST /notification-question. 204 / error -> null (ready question stays).
  static Future<String?> question({
    required String seed,
    required String eventType,
    required String topic,
    required String locale,
    String? profileId,
  }) async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) return null;
    try {
      final r = await http
          .post(
            Uri.parse('${AstroService.baseUrl}/notification-question'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({
              'seed': seed,
              'event_type': eventType,
              'topic': topic,
              'locale': locale,
              if (profileId != null) 'profile_id': profileId,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final m = jsonDecode(utf8.decode(r.bodyBytes));
      final q = m is Map ? m['question'] : null;
      return q is String && q.trim().isNotEmpty ? q.trim() : null;
    } catch (e) {
      debugPrint('NotificationTransitService.question failed: $e');
      return null;
    }
  }
}
