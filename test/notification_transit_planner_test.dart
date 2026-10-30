import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/services/notification_planner.dart';
import 'package:flutter_application/services/notification_repository.dart';
import 'package:flutter_application/services/notification_transit_service.dart';

CosmicNotification row(String slot, String kind, {String? eventType}) =>
    CosmicNotification(
      id: '$slot-$kind',
      day: '2026-11-12',
      locale: 'tr',
      slot: slot,
      kind: kind,
      eventType: eventType,
      title: 'Title',
      body: 'Body "{q}"',
      qSelf: 'Q one?',
      target: 'ask',
    );

List<PlannedItem> run(List<CosmicNotification> c, Map<String, String>? t) =>
    NotificationPlanner.plan(
      content: c,
      houseLines: const [],
      locale: 'tr',
      now: DateTime(2026, 11, 11, 12),
      today: DateTime(2026, 11, 12),
      morningHour: 9,
      morningMinute: 0,
      eveningHour: 20,
      eveningMinute: 0,
      at: (d, h, m) => DateTime(d.year, d.month, d.day, h, m),
      windowDays: 1,
      transitTexts: t,
    );

void main() {
  test('transit replaces morning evergreen body only', () {
    final r = run([row('morning', 'evergreen'), row('evening', 'evergreen')],
        {'2026-11-12': 'Transit text'});
    expect(r.length, 2);
    expect(r[0].source, 'transit');
    expect(r[0].body, 'Transit text');
    expect(r[0].title, 'Title');
    expect(r[0].question, 'Q one?');
    expect(r[1].source, 'cosmic');
    expect(r[1].body, 'Body "Q one?"');
  });

  test('event morning row keeps shared text', () {
    final r = run([row('morning', 'event', eventType: 'new_moon')],
        {'2026-11-12': 'Transit text'});
    expect(r.single.source, 'cosmic');
  });

  test('no transit or blank text keeps shared text', () {
    expect(run([row('morning', 'evergreen')], null).single.source, 'cosmic');
    expect(run([row('morning', 'evergreen')], {'2026-11-12': '  '}).single.source,
        'cosmic');
    expect(run([row('morning', 'evergreen')], {'2026-11-13': 'x'}).single.source,
        'cosmic');
  });

  test('transit body is cut to 400', () {
    final r = run([row('morning', 'evergreen')], {'2026-11-12': 'x' * 500});
    expect(r.single.body.length, 400);
  });

  test('parseTransits', () {
    final m = NotificationTransitService.parseTransits({
      'items': [
        {'day': '2026-11-12', 'notification': ' Hi '},
        {'day': '2026-11-13', 'notification': null},
        {'day': '2026-11-14', 'notification': ''},
        {'notification': 'no day'},
      ]
    });
    expect(m, {'2026-11-12': 'Hi'});
    expect(NotificationTransitService.parseTransits(null), isEmpty);
  });
}
