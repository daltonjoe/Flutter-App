import 'notification_repository.dart';
import 'notification_template.dart';

/// One planned notification (TEKNIK 4). Pure data, no Flutter imports.
class PlannedItem {
  final String day;
  final String slot;
  final DateTime scheduledAt;
  final String source;
  final String? notificationId;
  final bool named;
  final bool hard;
  final String topic;
  final int? house;
  final String title;
  final String body;
  final String? question;
  final String target;

  const PlannedItem({
    required this.day,
    required this.slot,
    required this.scheduledAt,
    required this.source,
    this.notificationId,
    required this.named,
    required this.hard,
    required this.topic,
    this.house,
    required this.title,
    required this.body,
    this.question,
    required this.target,
  });

  /// OS notification id = yyyyMMdd*10 + (0 morning | 1 evening).
  int get osId =>
      int.parse(day.replaceAll('-', '')) * 10 + (slot == 'evening' ? 1 : 0);

  /// Payload carried by the OS notification: "yyyy-MM-dd|slot".
  String get payload => '$day|$slot';

  Map<String, dynamic> toScheduleJson() => {
        'day': day,
        'slot': slot,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'source': source,
        'notification_id': notificationId,
        'named': named,
        'hard': hard,
        'topic': topic,
        'house': house,
        'title': title,
        'body': body,
        'question': question,
        'target': target,
      };
}

/// Pure planner (TEKNIK 4): content + house lines + profile + mood + slot
/// times -> planned items. Time zone and house lookup are injected.
class NotificationPlanner {
  static const int maxItems = 64;
  static const int defaultWindowDays = 30;
  static const int lowMoodMax = 2;
  static const int lowMoodCount = 2;

  /// Low mood: the newest [lowMoodCount] check-ins are all <= [lowMoodMax].
  static bool isLowMood(List<int> moodsNewestFirst) {
    if (moodsNewestFirst.length < lowMoodCount) return false;
    for (var i = 0; i < lowMoodCount; i++) {
      if (moodsNewestFirst[i] > lowMoodMax) return false;
    }
    return true;
  }

  static String fmtDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// [today] is the user's local date. [at] turns (local date, hour, minute)
  /// into an absolute instant. [houseOf] maps an event longitude to 1-12.
  static List<PlannedItem> plan({
    required List<CosmicNotification> content,
    required List<HouseLine> houseLines,
    required String locale,
    required DateTime now,
    required DateTime today,
    required int morningHour,
    required int morningMinute,
    required int eveningHour,
    required int eveningMinute,
    required DateTime Function(DateTime day, int hour, int minute) at,
    String? firstName,
    String topic = 'self',
    bool lowMood = false,
    int? Function(double lon)? houseOf,
    DateTime Function(DateTime utc)? toLocal,
    int windowDays = defaultWindowDays,
    Map<String, String>? transitTexts,
  }) {
    final byKey = <String, CosmicNotification>{};
    for (final r in content) {
      byKey['${r.day}|${r.slot}'] = r;
    }
    final lines = <String, String>{};
    for (final h in houseLines) {
      lines['${h.eventType}|${h.house}'] = h.line;
    }
    final name = (firstName ?? '').trim();
    final out = <PlannedItem>[];

    for (var i = 0; i < windowDays; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final dayStr = fmtDay(day);
      for (final slot in const ['morning', 'evening']) {
        final row = byKey['$dayStr|$slot'];
        if (row == null) continue; // D10: no content, no notification
        final isMorning = slot == 'morning';
        final when = at(day, isMorning ? morningHour : eveningHour,
            isMorning ? morningMinute : eveningMinute);
        if (!when.isAfter(now)) continue;

        int? house;
        String? houseLine;
        if (houseOf != null && row.eventType != null && row.eventLon != null) {
          final h = houseOf(row.eventLon!);
          final l = h == null ? null : lines['${row.eventType}|$h'];
          if (h != null && l != null) {
            house = h;
            houseLine = l;
          }
        }

        final named = name.isNotEmpty && row.titleNamed != null;
        final hard = lowMood &&
            slot == 'evening' &&
            (row.bodyHard ?? '').trim().isNotEmpty;

        final r = NotificationTemplate.render(
          row: row,
          locale: locale,
          firstName: name.isEmpty ? null : name,
          house: house,
          houseLine: houseLine,
          hard: hard,
          topic: topic,
          toLocal: toLocal,
        );

        final tTrim = ((transitTexts ?? const <String, String>{})[dayStr] ?? '').trim();
        final useTransit =
            isMorning && row.kind == 'evergreen' && tTrim.isNotEmpty;
        final transitBody = tTrim.length <= NotificationTemplate.maxBody
            ? tTrim
            : '${tTrim.substring(0, NotificationTemplate.maxBody - 1)}\u2026';
        out.add(PlannedItem(
          day: dayStr,
          slot: slot,
          scheduledAt: when.toUtc(),
          source: useTransit ? 'transit' : 'cosmic',
          notificationId: row.id,
          named: named,
          hard: hard,
          topic: topic,
          house: house,
          title: r.title,
          body: useTransit ? transitBody : r.body,
          question: r.question,
          target: r.target,
        ));
      }
    }

    out.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return out.length > maxItems ? out.sublist(0, maxItems) : out;
  }
}
