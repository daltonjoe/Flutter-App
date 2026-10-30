import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/services/notification_inbox_grouping.dart';
import 'package:flutter_application/services/notification_repository.dart';

InboxItem _i(String day, String slot, {bool read = false}) => InboxItem(
      day: day,
      slot: slot,
      title: 't',
      body: 'b',
      target: 'ask',
      isRead: read,
    );

void main() {
  final now = DateTime(2026, 11, 10, 12, 0);

  test('groups today / yesterday / older, newest first', () {
    final g = groupInbox([
      _i('2026-11-08', 'morning'),
      _i('2026-11-10', 'morning'),
      _i('2026-11-09', 'evening'),
      _i('2026-11-10', 'evening'),
      _i('2026-11-09', 'morning'),
    ], now);
    expect(g.map((e) => e.kind).toList(), ['today', 'yesterday', 'date']);
    expect(g.map((e) => e.dayKey).toList(),
        ['2026-11-10', '2026-11-09', '2026-11-08']);
    expect(g[0].items.map((e) => e.slot).toList(), ['evening', 'morning']);
  });

  test('month boundary yesterday', () {
    final g = groupInbox([_i('2026-10-31', 'morning')], DateTime(2026, 11, 1));
    expect(g.single.kind, 'yesterday');
  });

  test('date label dd.MM.yyyy', () {
    expect(inboxDateLabel('2026-11-08'), '08.11.2026');
  });

  test('empty list', () {
    expect(groupInbox(const [], now), isEmpty);
  });
}
