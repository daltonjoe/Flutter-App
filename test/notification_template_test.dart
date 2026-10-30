import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/services/notification_repository.dart';
import 'package:flutter_application/services/notification_template.dart';

CosmicNotification mk({
  String slot = 'morning',
  String kind = 'event',
  String locale = 'tr',
  String title = 'T',
  String? titleNamed,
  String body = 'B',
  String? bodyHard,
  String? qSelf,
  String? qLove,
  String? qWork,
  String target = 'ask',
  DateTime? eventAt,
}) =>
    CosmicNotification(
      day: '2026-11-09',
      locale: locale,
      slot: slot,
      kind: kind,
      eventAt: eventAt,
      title: title,
      titleNamed: titleNamed,
      body: body,
      bodyHard: bodyHard,
      qSelf: qSelf,
      qLove: qLove,
      qWork: qWork,
      target: target,
    );

DateTime ist(DateTime d) => d.add(const Duration(hours: 3));

void main() {
  test('tr event: name, house prefix, time, question', () {
    final r = NotificationTemplate.render(
      row: mk(
        titleNamed: '{name}, Baslik',
        body: 'Yeni ay {time}. {house} "{q}"',
        qSelf: 'Soru?',
        eventAt: DateTime.utc(2026, 11, 9, 7, 2),
      ),
      locale: 'tr',
      firstName: 'Talha',
      house: 7,
      houseLine: 'LINE.',
      toLocal: ist,
    );
    expect(r.title.startsWith('Talha, '), true);
    expect(r.body, contains('Senin 7. evinde: LINE.'));
    expect(r.body, contains('10:02'));
    expect(r.body, contains('"Soru?"'));
    expect(r.question, 'Soru?');
  });

  test('house null: no placeholder, no double space', () {
    final r = NotificationTemplate.render(
      row: mk(body: 'A {house} B'),
      locale: 'tr',
      house: null,
      houseLine: null,
    );
    expect(r.body, 'A B');
    expect(r.body.contains('{house}'), false);
    expect(r.body.contains('  '), false);
  });

  test('en ordinals', () {
    final exp = {1: '1st', 2: '2nd', 3: '3rd', 4: '4th', 11: '11th', 12: '12th'};
    exp.forEach((h, o) {
      final r = NotificationTemplate.render(
        row: mk(locale: 'en', body: 'X {house}'),
        locale: 'en',
        house: h,
        houseLine: 'L',
      );
      expect(r.body, contains('In your $o house: L'));
    });
  });

  test('hard: evening uses body_hard, morning uses body', () {
    final ev = NotificationTemplate.render(
      row: mk(slot: 'evening', body: 'soft', bodyHard: 'hard'),
      locale: 'tr',
      hard: true,
    );
    expect(ev.body, 'hard');
    final mo = NotificationTemplate.render(
      row: mk(slot: 'morning', body: 'soft', bodyHard: 'hard'),
      locale: 'tr',
      hard: true,
    );
    expect(mo.body, 'soft');
  });

  test('special without q: question null, body unchanged, target today', () {
    final r = NotificationTemplate.render(
      row: mk(kind: 'special', body: 'Ozel gun.', target: 'today'),
      locale: 'tr',
    );
    expect(r.question, isNull);
    expect(r.body, 'Ozel gun.');
    expect(r.target, 'today');
  });

  test('topic picks q_love, falls back to q_self', () {
    final a = NotificationTemplate.render(
      row: mk(qSelf: 'S', qLove: 'L', qWork: 'W'),
      locale: 'tr',
      topic: 'love',
    );
    expect(a.question, 'L');
    final b = NotificationTemplate.render(
      row: mk(qSelf: 'S', qLove: '', qWork: 'W'),
      locale: 'tr',
      topic: 'love',
    );
    expect(b.question, 'S');
  });

  test('no name -> plain title', () {
    final row = mk(title: 'Plain', titleNamed: '{name}, Named');
    expect(NotificationTemplate.render(row: row, locale: 'tr').title, 'Plain');
    expect(
        NotificationTemplate.render(row: row, locale: 'tr', firstName: '  ')
            .title,
        'Plain');
  });

  test('length guard drops house sentence first', () {
    final longBody = '${'a' * 380} {house}';
    final r = NotificationTemplate.render(
      row: mk(body: longBody),
      locale: 'tr',
      house: 7,
      houseLine: 'b' * 60,
    );
    expect(r.body.length <= 400, true);
    expect(r.body.contains('Senin'), false);
  });
}
