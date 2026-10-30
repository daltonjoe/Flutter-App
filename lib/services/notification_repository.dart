import 'package:supabase_flutter/supabase_flutter.dart';

String? _sn(dynamic v) {
  if (v == null) return null;
  final s = '$v';
  return s.isEmpty ? null : s;
}

String _s(dynamic v) => v == null ? '' : '$v';

int _i(dynamic v, [int def = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? def;
}

double? _d(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

bool _b(dynamic v) => v == true || v == 'true';

DateTime? _dt(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse('$v')?.toUtc();
}

List<Map<String, dynamic>> _rows(dynamic r) {
  if (r is List) {
    return r
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (r is Map) return [Map<String, dynamic>.from(r)];
  return const [];
}

/// Row of cosmic_notifications (TEKNIK 2.1). [day] is 'yyyy-MM-dd'.
class CosmicNotification {
  final String? id;
  final String day;
  final String locale;
  final String slot;
  final String kind;
  final String? eventType;
  final DateTime? eventAt;
  final double? eventLon;
  final String title;
  final String? titleNamed;
  final String body;
  final String? bodyHard;
  final String? qSelf;
  final String? qLove;
  final String? qWork;
  final String target;

  const CosmicNotification({
    this.id,
    required this.day,
    required this.locale,
    required this.slot,
    required this.kind,
    this.eventType,
    this.eventAt,
    this.eventLon,
    required this.title,
    this.titleNamed,
    required this.body,
    this.bodyHard,
    this.qSelf,
    this.qLove,
    this.qWork,
    required this.target,
  });

  factory CosmicNotification.fromJson(Map<String, dynamic> j) =>
      CosmicNotification(
        id: _sn(j['id']),
        day: _s(j['day']),
        locale: _s(j['locale']),
        slot: _s(j['slot']),
        kind: _s(j['kind']),
        eventType: _sn(j['event_type']),
        eventAt: _dt(j['event_at']),
        eventLon: _d(j['event_lon']),
        title: _s(j['title']),
        titleNamed: _sn(j['title_named']),
        body: _s(j['body']),
        bodyHard: _sn(j['body_hard']),
        qSelf: _sn(j['q_self']),
        qLove: _sn(j['q_love']),
        qWork: _sn(j['q_work']),
        target: _s(j['target']).isEmpty ? 'ask' : _s(j['target']),
      );
}

class HouseLine {
  final String eventType;
  final int house;
  final String line;
  const HouseLine(
      {required this.eventType, required this.house, required this.line});

  factory HouseLine.fromJson(Map<String, dynamic> j) => HouseLine(
        eventType: _s(j['event_type']),
        house: _i(j['house']),
        line: _s(j['line']),
      );
}

class InboxItem {
  final String day;
  final String slot;
  final DateTime? scheduledAt;
  final String title;
  final String body;
  final String? question;
  final String target;
  final bool isRead;
  const InboxItem({
    required this.day,
    required this.slot,
    this.scheduledAt,
    required this.title,
    required this.body,
    this.question,
    required this.target,
    required this.isRead,
  });

  factory InboxItem.fromJson(Map<String, dynamic> j) => InboxItem(
        day: _s(j['day']),
        slot: _s(j['slot']),
        scheduledAt: _dt(j['scheduled_at']),
        title: _s(j['title']),
        body: _s(j['body']),
        question: _sn(j['question']),
        target: _s(j['target']).isEmpty ? 'ask' : _s(j['target']),
        isRead: _b(j['is_read']),
      );
}

/// Result of notification_tap.
class TapResult {
  final bool ok;
  final bool recorded;
  final int streak;
  final int awarded;
  final String? reason;
  const TapResult({
    required this.ok,
    required this.recorded,
    required this.streak,
    required this.awarded,
    this.reason,
  });

  factory TapResult.fromJson(Map<String, dynamic> j) => TapResult(
        ok: _b(j['ok']),
        recorded: j['recorded'] is bool ? j['recorded'] as bool : _i(j['recorded']) > 0,
        streak: _i(j['streak']),
        awarded: _i(j['awarded']),
        reason: _sn(j['reason']),
      );
}

/// Thin wrapper over the 7 notification RPCs (TEKNIK 2.3).
class NotificationRepository {
  static SupabaseClient get _c => Supabase.instance.client;

  static String fmtDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<List<CosmicNotification>> content(
      DateTime from, DateTime to, String locale) async {
    final r = await _c.rpc('notification_content', params: {
      'p_from': fmtDay(from),
      'p_to': fmtDay(to),
      'p_locale': locale,
    });
    return _rows(r).map(CosmicNotification.fromJson).toList();
  }

  static Future<List<HouseLine>> houseLines(String locale) async {
    final r = await _c.rpc('notification_house_lines', params: {
      'p_locale': locale,
    });
    return _rows(r).map(HouseLine.fromJson).toList();
  }

  /// 'self' | 'love' | 'work'
  static Future<String> topic() async {
    final r = await _c.rpc('notification_topic');
    final s = '$r';
    return (s == 'love' || s == 'work') ? s : 'self';
  }

  /// Replaces the user's future rows. Max 64 items (server enforces).
  static Future<int> schedule(List<Map<String, dynamic>> items) async {
    final r = await _c.rpc('notification_schedule', params: {
      'p_items': items,
    });
    return _i(r);
  }

  static Future<List<InboxItem>> inbox({int days = 14}) async {
    final r = await _c.rpc('notification_inbox', params: {'p_days': days});
    return _rows(r).map(InboxItem.fromJson).toList();
  }

  /// No args = mark all as read. Returns number of rows updated.
  static Future<int> markRead({DateTime? day, String? slot}) async {
    final params = <String, dynamic>{};
    if (day != null) {
      params['p_day'] = fmtDay(day);
      params['p_slot'] = slot;
    }
    final r = await _c.rpc('notification_mark_read', params: params);
    return _i(r);
  }

  static Future<TapResult> tap(DateTime day, String slot) async {
    final r = await _c.rpc('notification_tap', params: {
      'p_day': fmtDay(day),
      'p_slot': slot,
    });
    final rows = _rows(r);
    return TapResult.fromJson(rows.isEmpty ? <String, dynamic>{} : rows.first);
  }
}
