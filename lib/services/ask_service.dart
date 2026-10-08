import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'astro_service.dart';

class AskResult {
  final String? reply;
  final String? safety; // null | crisis | redirect | fallback
  const AskResult(this.reply, this.safety);
}

class AskService {
  /// POST /ask {message, contexts, locale, history} (sözleşme: handoff.md)
  static Future<AskResult> send({
    required String message,
    required List<Map<String, dynamic>> contexts,
    required String locale,
   required List<Map<String, String>> history,
  String? profileId,
      String? mode,
      String? forecastMonth,
    }) async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) {
      throw AstroServiceException(code: 'NO_SESSION', message: 'Oturum yok.');
    }
    http.Response r;
    try {
      r = await http
          .post(
            Uri.parse('${AstroService.baseUrl}/ask'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({
              'message': message,
              'contexts': contexts,
              'locale': locale,
               'history': history,
              'profile_id': ?profileId,
              'mode': ?mode,
              'forecast_month': ?forecastMonth,
            }),
          )
          .timeout(const Duration(seconds: 60));
    } on Exception {
      throw AstroServiceException(
          code: 'NETWORK_ERROR', message: 'Sunucuya bağlanılamadı.');
    }
    if (r.statusCode == 429) {
      throw AstroServiceException(code: 'RATE_LIMITED', message: 'Çok fazla istek.');
    }
    if (r.statusCode != 200) {
      throw AstroServiceException(
          code: 'HTTP_${r.statusCode}', message: 'Sunucu hatası: ${r.statusCode}');
    }
    final m = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
    return AskResult(m['reply'] as String?, m['safety'] as String?);
  }
}