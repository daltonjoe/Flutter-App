import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'astro_service.dart';

class AskResult {
  final String? reply;
  final String? safety; // null | crisis | redirect | fallback
  final List<String>? bubbles; // AV: yalnÄ±z bubbles=true isteÄŸinde
  final String? need; // friend | sibling | parent | expert
  const AskResult(this.reply, this.safety, {this.bubbles, this.need});
}

class AskService {
  static String _detail(http.Response r) {
    try {
      final m = jsonDecode(utf8.decode(r.bodyBytes));
      if (m is Map) return '${m['detail']}';
    } catch (e) {
      debugPrint('AskService detail parse failed: $e');
    }
    return '';
  }

  /// POST /ask {message, contexts, locale, history} (sÃ¶zleÅŸme: handoff.md)
  static Future<AskResult> send({
    required String message,
    required List<Map<String, dynamic>> contexts,
    required String locale,
    required List<Map<String, String>> history,
    String? profileId,
    String? mode,
    String? forecastMonth,
    bool bubbles = false,
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
              if (bubbles) 'bubbles': true,
            }),
          )
          .timeout(const Duration(seconds: 60));
    } on Exception {
      throw AstroServiceException(
          code: 'NETWORK_ERROR', message: 'Sunucuya baÄŸlanÄ±lamadÄ±.');
    }
    if (r.statusCode == 429) {
      if (_detail(r) == 'quota') {
        throw AstroServiceException(code: 'QUOTA', message: 'GÃ¼nlÃ¼k hak doldu.');
      }
      throw AstroServiceException(code: 'RATE_LIMITED', message: 'Ã‡ok fazla istek.');
    }
    if (r.statusCode != 200) {
      throw AstroServiceException(
          code: 'HTTP_${r.statusCode}', message: 'Sunucu hatasÄ±: ${r.statusCode}');
    }
    final m = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
    List<String>? bl;
    final b = m['bubbles'];
    if (b is List) {
      bl = [for (final x in b) '$x'].where((s) => s.trim().isNotEmpty).toList();
    }
    return AskResult(m['reply'] as String?, m['safety'] as String?,
        bubbles: bl, need: m['need'] as String?);
  }

  static Future<void> _mem(String method, String path, String text) async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) {
      throw AstroServiceException(code: 'NO_SESSION', message: 'Oturum yok.');
    }
    final uri = Uri.parse('${AstroService.baseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    };
    final body = jsonEncode({'text': text});
    http.Response r;
    try {
      r = method == 'PATCH'
          ? await http
              .patch(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 30))
          : await http
              .post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 30));
    } on Exception {
      throw AstroServiceException(
          code: 'NETWORK_ERROR', message: 'Sunucuya baÄŸlanÄ±lamadÄ±.');
    }
    if (r.statusCode == 200) return;
    final d = _detail(r);
    final code = r.statusCode == 403
        ? 'MEM_CONSENT'
        : r.statusCode == 409
            ? 'MEM_LIMIT'
            : r.statusCode == 404
                ? 'MEM_NOT_FOUND'
                : (r.statusCode == 400 && d == 'not_allowed')
                    ? 'MEM_NOT_ALLOWED'
                    : (r.statusCode == 400 && d == 'empty')
                        ? 'MEM_EMPTY'
                        : 'HTTP_${r.statusCode}';
    throw AstroServiceException(code: code, message: 'Not hatasÄ±: ${r.statusCode}');
  }

  /// POST /memory {text} (rÄ±za yoksa 403, gÃ¼vensiz 400, 10 not dolu 409).
  static Future<void> memoryAdd(String text) => _mem('POST', '/memory', text);

  /// PATCH /memory/{id} {text}
  static Future<void> memoryEdit(String id, String text) =>
      _mem('PATCH', '/memory/$id', text);

  static String memoryErrKey(Object e) {
    final c = e is AstroServiceException ? e.code : '';
    switch (c) {
      case 'MEM_NOT_ALLOWED':
        return 'ask.remember.not_allowed';
      case 'MEM_LIMIT':
        return 'notes.limit';
      default:
        return 'ask.error';
    }
  }
}
