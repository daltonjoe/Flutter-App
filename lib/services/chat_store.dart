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
    this.pv,
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

  /// V4c: gorulen profil dogum bilgisi surumu (null = eski kayit).
  final String? pv;
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
        pv: m['pv'] as String?,
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
          'pv': r.pv,
        }),
      );
    } catch (e) {
      debugPrint('ChatStore save failed: $e');
    }
  }

  /// V9a: kayda mesaj ekler (aktif kayit ve varsa arsiv); kayit yoksa null.
  static Future<ChatRecord?> appendMsg(
    String k,
    String uid,
    String mode,
    Map<String, dynamic> msg,
  ) async {
    final rec = await load(k);
    if (rec == null) return null;
    final n = ChatRecord(
      msgs: [...rec.msgs, msg],
      loc: rec.loc,
      updated: DateTime.now().millisecondsSinceEpoch,
      month: rec.month,
      sid: rec.sid,
      title: rec.title,
      pa: rec.pa,
      pb: rec.pb,
      pn: rec.pn,
      pv: rec.pv,
    );
    await save(k, n);
    final sid = rec.sid;
    if (sid != null) await save(archKey(uid, mode, sid), n);
    return n;
  }

  static Future<void> remove(String k) async {
    try {
      await (await SharedPreferences.getInstance()).remove(k);
    } catch (e) {
      debugPrint('ChatStore remove failed: $e');
    }
  }

  /// V4b: bir moda ait arsiv kayitlari, son mesaj tarihine gore yeni once.
  static Future<List<MapEntry<String, ChatRecord>>> listArch(
    String uid,
    String mode,
  ) async {
    final out = <MapEntry<String, ChatRecord>>[];
    try {
      final p = await SharedPreferences.getInstance();
      final pre = key(uid, mode, 'arch.');
      for (final k in p.getKeys().toList()) {
        if (!k.startsWith(pre)) continue;
        final r = await load(k);
        if (r != null) out.add(MapEntry(k, r));
      }
    } catch (e) {
      debugPrint('ChatStore listArch failed: $e');
    }
    out.sort((a, b) => b.value.updated.compareTo(a.value.updated));
    return out;
  }

  /// V4b: kayitli sohbetin ayni sid ile tutulan aktif kaydinin anahtari, yoksa null.
  static Future<String?> _activeOf(
    String uid,
    String mode,
    String sid,
    ChatRecord r,
  ) async {
    final pa = r.pa;
    if (pa == null) return null;
    final k = key(uid, mode, r.pb == null ? pa : '${pa}_${r.pb}');
    final a = await load(k);
    return (a != null && a.sid == sid) ? k : null;
  }

  static ChatRecord _titled(ChatRecord r, String title) {
    return ChatRecord(
      msgs: r.msgs,
      loc: r.loc,
      updated: r.updated,
      month: r.month,
      sid: r.sid,
      title: title,
      pa: r.pa,
      pb: r.pb,
      pn: r.pn,
      pv: r.pv,
    );
  }

  /// V4b: arsiv kaydini ve ayni sid li aktif kaydi siler (geri alinamaz).
  static Future<void> deleteSaved(String uid, String mode, String sid) async {
    final ak = archKey(uid, mode, sid);
    final r = await load(ak);
    await remove(ak);
    if (r == null) return;
    final k = await _activeOf(uid, mode, sid, r);
    if (k != null) await remove(k);
  }

  /// V4b: basligi arsivde ve ayni sid li aktif kayitta gunceller; tarih degismez.
  static Future<void> rename(
    String uid,
    String mode,
    String sid,
    String title,
  ) async {
    final ak = archKey(uid, mode, sid);
    final r = await load(ak);
    if (r == null) return;
    final k = await _activeOf(uid, mode, sid, r);
    final a = k == null ? null : await load(k);
    await save(ak, _titled(r, title));
    if (k != null && a != null) await save(k, _titled(a, title));
  }

  /// V4c: gorulen profil surumunu yazar; tarih ve mesajlar degismez, sid eslesmezse yazmaz.
  static Future<void> setPv(String k, String pv, String? sid) async {
    final r = await load(k);
    if (r == null || r.sid != sid) return;
    await save(
      k,
      ChatRecord(
        msgs: r.msgs,
        loc: r.loc,
        updated: r.updated,
        month: r.month,
        sid: r.sid,
        title: r.title,
        pa: r.pa,
        pb: r.pb,
        pn: r.pn,
        pv: pv,
      ),
    );
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
