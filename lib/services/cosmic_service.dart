import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'astro_service.dart';

/// POST /cosmic-pulse: collective sky, same for every user (no profile).
/// Last good response is cached per locale.
class CosmicService {
  static Future<Map<String, dynamic>> fetch(String locale) async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) {
      throw AstroServiceException(code: 'NO_SESSION', message: 'no session');
    }
    http.Response r;
    try {
      r = await http
          .post(
            Uri.parse('${AstroService.baseUrl}/cosmic-pulse'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({'locale': locale}),
          )
          .timeout(const Duration(seconds: 20));
    } on Exception {
      throw AstroServiceException(code: 'NETWORK_ERROR', message: 'network error');
    }
    if (r.statusCode != 200) {
      throw AstroServiceException(
          code: 'HTTP_${r.statusCode}', message: 'server error: ${r.statusCode}');
    }
    final out =
        Map<String, dynamic>.from(jsonDecode(utf8.decode(r.bodyBytes)) as Map);
    await _save(locale, out);
    return out;
  }

  static String _ck(String loc) => 'cosmic_last_$loc';

  static Future<void> _save(String loc, Map<String, dynamic> data) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_ck(loc),
          jsonEncode({'saved_at': DateTime.now().toIso8601String(), 'data': data}));
    } catch (e) {
      debugPrint('cosmic cache save: $e');
    }
  }

  /// Last good response: data map and saved_at, or null.
  static Future<Map<String, dynamic>?> cached(String loc) async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_ck(loc));
      if (s == null) return null;
      final m = jsonDecode(s) as Map;
      return {
        'data': Map<String, dynamic>.from(m['data'] as Map),
        'saved_at': DateTime.parse(m['saved_at'] as String),
      };
    } catch (e) {
      debugPrint('cosmic cache read: $e');
      return null;
    }
  }
}
