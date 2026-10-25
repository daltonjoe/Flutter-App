import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// V3: aktif sohbetin cihazda saklanan kaydi (K3, K10).
class ChatRecord {
  const ChatRecord({
    required this.msgs,
    required this.loc,
    required this.updated,
    this.month,
    this.sid,
    this.title,
    this.pa,
    this.pb,
    this.pn,
  });

  /// Her mesaj: m (benim mi), t (metin), b (balonlar), s (sistem).
  final List<Map<String, dynamic>> msgs;
  final String loc;
  final int updated;
  final String? month;

  /// V4: kayitli sohbet kimligi (null = kaydedilmemis), baslik, profil kimlikleri, gorunen ad.
  final String? sid;
  final String? title;
  final String? pa;
  final String? pb;
  final String? pn;
}

/// Anahtar: chat.v1.UID.MOD.PROFIL (iliskide PROFIL = a_b). Hata olursa sessizce null doner.
class ChatStore {
  static String key(String uid, String mode, String scope) =>
      'chat.v1.$uid.$mode.$scope';

  static String _partnerKey(String uid, String act) =>
      'chat.v1.$uid.synastry.last.$act';

  /// V4: kayitli sohbetin arsiv anahtari.
  static String archKey(String uid, String mode, String sid) =>
      key(uid, mode, 'arch.$sid');

  /// V4: kaydedilmemis ve onceki gunden kalan aktif sohbetleri siler.
  static Future<void> purgeStale(String uid, DateTime now) async {
    try {
      final p = await SharedPreferences.getInstance();
      final pre = 'chat.v1.$uid.';
      for (final k in p.getKeys().toList()) {
        if (!k.startsWith(pre) || k.contains('.arch.') || k.contains('.last.')) {
          continue;
        }
        final r = await load(k);
        if (r == null || r.sid != null) continue;
        final d = DateTime.fromMillisecondsSinceEpoch(r.updated);
        if (d.year != now.year || d.month != now.month || d.day != now.day) {
          await p.remove(k);
        }
      }
    } catch (e) {
      debugPrint('ChatStore purgeStale failed: $e');
    }
  }

  static Future<ChatRecord?> load(String k) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(k);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return ChatRecord(
        msgs: [
          for (final e in m['msgs'] as List)
            Map<String, dynamic>.from(e as Map),
        ],
        loc: '${m['loc'] ?? ''}',
        updated: (m['updated'] as num?)?.toInt() ?? 0,
        month: m['month'] as String?,
        sid: m['sid'] as String?,
        title: m['title'] as String?,
        pa: m['pa'] as String?,
        pb: m['pb'] as String?,
        pn: m['pn'] as String?,
      );
    } catch (e) {
      debugPrint('ChatStore load failed: $e');
      return null;
    }
  }

  static Future<void> save(String k, ChatRecord r) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        k,
        jsonEncode({
          'msgs': r.msgs,
          'loc': r.loc,
          'updated': r.updated,
          'month': r.month,
          'sid': r.sid,
          'title': r.title,
          'pa': r.pa,
          'pb': r.pb,
          'pn': r.pn,
        }),
      );
    } catch (e) {
      debugPrint('ChatStore save failed: $e');
    }
  }

  static Future<void> remove(String k) async {
    try {
      await (await SharedPreferences.getInstance()).remove(k);
    } catch (e) {
      debugPrint('ChatStore remove failed: $e');
    }
  }

  static Future<String?> lastPartner(String uid, String act) async {
    try {
      return (await SharedPreferences.getInstance())
          .getString(_partnerKey(uid, act));
    } catch (e) {
      debugPrint('ChatStore lastPartner failed: $e');
      return null;
    }
  }

  static Future<void> setLastPartner(String uid, String act, String id) async {
    try {
      await (await SharedPreferences.getInstance())
          .setString(_partnerKey(uid, act), id);
    } catch (e) {
      debugPrint('ChatStore setLastPartner failed: $e');
    }
  }
}
