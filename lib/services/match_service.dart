import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'astro_service.dart';

class MatchAspect {
  final int bodyAId;
  final int bodyBId;
  final int aspectTypeId;
  final double orb;
  final double tightness;

  const MatchAspect({
    required this.bodyAId,
    required this.bodyBId,
    required this.aspectTypeId,
    required this.orb,
    required this.tightness,
  });
}

class MatchResult {
  final bool timeKnownA;
  final bool timeKnownB;
  final List<MatchAspect> aspects;

  const MatchResult({
    required this.timeKnownA,
    required this.timeKnownB,
    required this.aspects,
  });
}

class MatchService {
  MatchService._();

  // Anahtar: 'minId-maxId-aspectTypeId' -> aktif dil (yoksa en) metni.
  static String textKey(int a, int b, int aspectTypeId) {
    final lo = a < b ? a : b;
    final hi = a < b ? b : a;
    return '$lo-$hi-$aspectTypeId';
  }

  /// Yönsüz sinastri metinleri. Hata/boş -> boş map (etiket-only).
  static Future<Map<String, String>> fetchTexts(
    List<MatchAspect> aspects,
    String locale,
  ) async {
    if (aspects.isEmpty) return {};
    try {
      final ids = <int>{};
      for (final a in aspects) {
        ids.add(a.bodyAId);
        ids.add(a.bodyBId);
      }
      final idList = ids.toList();
      final rows = await Supabase.instance.client
          .from('snippet_templates')
          .select(
              'transit_body_id,natal_body_id,aspect_type_id,snippet_translations(locale,body)')
          .eq('kind', 'synastry')
          .inFilter('transit_body_id', idList)
          .inFilter('natal_body_id', idList)
          .limit(1000);
      final out = <String, String>{};
      for (final row in rows as List) {
        if (row is! Map) continue;
        final lo = _toInt(row['transit_body_id']);
        final hi = _toInt(row['natal_body_id']);
        final at = _toInt(row['aspect_type_id']);
        final trs = row['snippet_translations'];
        if (trs is! List) continue;
        String? pick;
        String? en;
        for (final t in trs) {
          if (t is! Map) continue;
          final body = (t['body'] as String?)?.trim();
          if (body == null || body.isEmpty) continue;
          if (t['locale'] == locale) pick = body;
          if (t['locale'] == 'en') en = body;
        }
        final text = pick ?? en;
        if (text != null) out[textKey(lo, hi, at)] = text;
      }
      return out;
    } catch (e, st) {
      debugPrint('synastry texts error: $e\n$st');
      return {};
    }
  }

  static double _toDouble(Object? o, {double fallback = 0.0}) {
    if (o is num) return o.toDouble();
    if (o is String) {
      return double.tryParse(o) ?? fallback;
    }
    return fallback;
  }

  static int _toInt(Object? o, {int fallback = 0}) {
    if (o is num) return o.toInt();
    if (o is String) {
      return int.tryParse(o) ?? fallback;
    }
    return fallback;
  }

  static Future<MatchResult> fetch(String profileA, String profileB) async {
    final jwt = Supabase.instance.client.auth.currentSession?.accessToken;
    if (jwt == null) {
      throw AstroServiceException(code: 'NO_SESSION', message: 'Oturum yok.');
    }
    http.Response r;
    try {
      r = await http
          .post(
            Uri.parse('${AstroService.baseUrl}/synastry'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({
              'profile_a': profileA,
              'profile_b': profileB,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      debugPrint('synastry http error: $e');
      throw AstroServiceException(
        code: 'NETWORK_ERROR',
        message: 'Sunucuya bağlanılamadı.',
      );
    }
    if (r.statusCode != 200) {
      debugPrint(
        'synastry non-200 status=${r.statusCode} body=${r.body}',
      );
      throw AstroServiceException(
        code: 'HTTP_${r.statusCode}',
        message: 'Sunucu hatası: ${r.statusCode}',
      );
    }
    try {
      final raw = jsonDecode(utf8.decode(r.bodyBytes));
      final m = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final tA = m['time_known_a'] as bool? ?? false;
      final tB = m['time_known_b'] as bool? ?? false;
      final aspects = <MatchAspect>[];
      final list = m['aspects'] as List? ?? const [];
      for (final a in list) {
        if (a is! Map) continue;
        final bA = _toInt(a['body_a_id'] ?? a['bodyAId']);
        final bB = _toInt(a['body_b_id'] ?? a['bodyBId']);
        final at = _toInt(a['aspect_type_id'] ?? a['aspectTypeId']);
        final orb = _toDouble(a['orb']);
        final ti = _toDouble(a['tightness']);
        aspects.add(MatchAspect(
          bodyAId: bA,
          bodyBId: bB,
          aspectTypeId: at,
          orb: orb,
          tightness: ti,
        ));
      }
      return MatchResult(
        timeKnownA: tA,
        timeKnownB: tB,
        aspects: aspects,
      );
    } catch (e, st) {
      debugPrint('synastry parse error: $e\n$st');
      rethrow;
    }
  }
}
