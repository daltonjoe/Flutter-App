import 'package:flutter_application/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildEvent PostHog batch bicimi', () {
    final e = AnalyticsService.buildEvent(
      AnalyticsEvents.questionAsked,
      'uid-1',
      {'n': 2, 'ok': true},
      DateTime.utc(2026, 10, 30, 12),
    );
    expect(e['event'], 'onboarding_question_asked');
    expect(e['distinct_id'], 'uid-1');
    expect(e['timestamp'], '2026-10-30T12:00:00.000Z');
    final p = e['properties'] as Map<String, dynamic>;
    expect(p['n'], 2);
    expect(p['ok'], true);
    expect(p[r'$lib'], 'soulbound-flutter');
    expect(p.containsKey('platform'), true);
  });

  test('debug surumunde kapali (yalniz log)', () {
    expect(AnalyticsService.enabled, false);
  });
}
