import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/services/notification_planner.dart';
import 'package:flutter_application/services/notification_repository.dart';

CosmicNotification mk(
  String day,
  String slot, {
  String title = 'T',
  String? titleNamed,
  String body = 'B',
  String? bodyHard,
  String? eventType,
  double? eventLon,
}) =>
    CosmicNotification(
      id: 'id-$day-$slot',
      day: day,
      locale: 'tr',
      slot: slot,
      kind: eventType == null ? 'evergreen' : 'event',
      eventType: eventType,
      eventLon: eventLon,
      title: title,
      titleNamed: titleNamed,
      body: body,
      bodyHard: bodyHard,
      target: 'ask',
    );

// Local zone = UTC+3.
DateTime at3(DateTime d, int h, int m) =>
    DateTime.utc(d.year, d.month, d.day, h - 3, m);

List<PlannedItem> run(
  List<CosmicNotification> content, {
  DateTime? now,
  bool lowMood = false,
  String? name,
  List<HouseLine> lines = const [],
  int? Function(double)? houseOf,
  int windowDays = 30,
}) =>
    NotificationPlanner.plan(
      content: content,
      houseLines: lines,
      locale: 'tr',
      now: now ?? DateTime.utc(2026, 11, 1, 0, 0),
      today: DateTime(2026, 11, 1),
      morningHour: 9,
      morningMinute: 0,
      eveningHour: 20,
      eveningMinute: 0,
      at: at3,
      firstName: name,
      lowMood: lowMood,
      houseOf: houseOf,
      windowDays: windowDays,
    );

void main() {
  test('isLowMood: newest two <= 2', () {
    expect(NotificationPlanner.isLowMood([2, 1, 5]), true);
    expect(NotificationPlanner.isLowMood([2, 3, 1]), false);
    expect(NotificationPlanner.isLowMood([1]), false);
  });

  test('no content -> nothing planned', () {
    expect(run(const []), isEmpty);
  });

  test('past slots are skipped', () {
    final items = run(
      [mk('2026-11-01', 'morning'), mk('2026-11-01', 'evening')],
      now: DateTime.utc(2026, 11, 1, 10, 0),
    );
    expect(items.length, 1);
    expect(items.first.slot, 'evening');
  });

  test('hard only for evening on low mood', () {
    final items = run(
      [
        mk('2026-11-01', 'morning', bodyHard: 'H'),
        mk('2026-11-01', 'evening', bodyHard: 'H'),
      ],
      lowMood: true,
    );
    expect(items[0].slot, 'morning');
    expect(items[0].hard, false);
    expect(items[0].body, 'B');
    expect(items[1].hard, true);
    expect(items[1].body, 'H');
  });

  test('house sentence and named title', () {
    final items = run(
      [
        mk('2026-11-09', 'morning',
            titleNamed: '{name}, T',
            body: 'A {house}',
            eventType: 'new_moon',
            eventLon: 226.9),
      ],
      name: 'Talha',
      lines: const [HouseLine(eventType: 'new_moon', house: 7, line: 'X')],
      houseOf: (lon) => 7,
    );
    expect(items.length, 1);
    expect(items.first.house, 7);
    expect(items.first.named, true);
    expect(items.first.title, 'Talha, T');
    expect(items.first.body, 'A Senin 7. evinde: X');
  });

  test('cap at 64, earliest kept, sorted', () {
    final rows = <CosmicNotification>[];
    for (var i = 0; i < 40; i++) {
      final d = NotificationPlanner.fmtDay(DateTime(2026, 11, 1 + i));
      rows.add(mk(d, 'morning'));
      rows.add(mk(d, 'evening'));
    }
    final items = run(rows, windowDays: 40);
    expect(items.length, 64);
    expect(items.first.day, '2026-11-01');
    expect(items.first.slot, 'morning');
    for (var i = 1; i < items.length; i++) {
      expect(items[i].scheduledAt.isAfter(items[i - 1].scheduledAt), true);
    }
  });

  test('osId, payload and schedule json', () {
    final items = run(
        [mk('2026-11-01', 'morning'), mk('2026-11-01', 'evening')]);
    expect(items[0].osId, 202611010);
    expect(items[1].osId, 202611011);
    expect(items[1].payload, '2026-11-01|evening');
    final j = items[1].toScheduleJson();
    expect((j['scheduled_at'] as String).endsWith('Z'), true);
    expect(j['source'], 'cosmic');
    expect(j['slot'], 'evening');
  });
}
