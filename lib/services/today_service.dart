import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'astro_service.dart';

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
    http.Response r;
    try {
      r = await http
          .post(
            Uri.parse('${AstroService.baseUrl}/daily-events'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({'profile_id': profileId, 'date': day, 'locale': locale}),
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
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(r.bodyBytes)) as Map);
  }
}