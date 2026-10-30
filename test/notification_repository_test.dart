import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/services/notification_repository.dart';

void main() {
  test('CosmicNotification parses row with NULLs', () {
    final n = CosmicNotification.fromJson({
      'id': 'a1',
      'day': '2026-11-10',
      'locale': 'tr',
      'slot': 'morning',
      'kind': 'special',
      'event_type': null,
      'event_at': null,
      'event_lon': null,
      'title': 'T',
      'title_named': null,
      'body': 'B',
      'body_hard': null,
      'q_self': null,
      'q_love': null,
      'q_work': null,
      'target': 'today',
      'status': 'published',
    });
    expect(n.day, '2026-11-10');
    expect(n.eventType, isNull);
    expect(n.eventAt, isNull);
    expect(n.eventLon, isNull);
    expect(n.titleNamed, isNull);
    expect(n.qSelf, isNull);
    expect(n.target, 'today');
  });

  test('CosmicNotification parses event row', () {
    final n = CosmicNotification.fromJson({
      'day': '2026-11-09',
      'locale': 'tr',
      'slot': 'morning',
      'kind': 'event',
      'event_type': 'new_moon',
      'event_at': '2026-11-09T07:02:00+00:00',
      'event_lon': '226.891',
      'title': 'T',
      'title_named': '{name}, T',
      'body': 'B {house} {time} {q}',
      'q_self': 'Q1',
      'target': 'ask',
    });
    expect(n.eventType, 'new_moon');
    expect(n.eventAt!.hour, 7);
    expect(n.eventAt!.minute, 2);
    expect(n.eventLon, closeTo(226.891, 1e-9));
    expect(n.titleNamed, '{name}, T');
    expect(n.qSelf, 'Q1');
  });

  test('HouseLine, InboxItem, TapResult parse', () {
    final h = HouseLine.fromJson(
        {'event_type': 'full_moon', 'house': 7, 'line': 'x'});
    expect(h.house, 7);
    final i = InboxItem.fromJson({
      'day': '2026-11-09',
      'slot': 'evening',
      'scheduled_at': '2026-11-09T17:00:00+00:00',
      'title': 'T',
      'body': 'B',
      'question': null,
      'target': 'match',
      'is_read': false,
    });
    expect(i.question, isNull);
    expect(i.isRead, false);
    expect(i.target, 'match');
    final t = TapResult.fromJson(
        {'ok': true, 'recorded': 1, 'streak': 3, 'awarded': 10});
    expect(t.ok, true);
    expect(t.recorded, true);
    expect(t.awarded, 10);
    final u = TapResult.fromJson({'ok': false, 'reason': 'unknown_notification'});
    expect(u.ok, false);
    expect(u.reason, 'unknown_notification');
  });

  test('fmtDay pads', () {
    expect(NotificationRepository.fmtDay(DateTime(2026, 1, 5)), '2026-01-05');
  });
}
