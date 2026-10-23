// test/ask_error_map_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/services/ask_service.dart';

void main() {
  group('AskService.mapAskError', () {
    const cases = <(int, String?, String?)>[
      (429, 'credits_empty', 'CREDITS_EMPTY'),
      (429, 'daily_limit_trial', 'DAILY_LIMIT_TRIAL'),
      (429, 'daily_limit_pro', 'DAILY_LIMIT_PRO'),
      (429, 'quota', 'QUOTA'),
      (429, 'Busy.', 'RATE_LIMITED'),
      (429, '', 'RATE_LIMITED'),
      (429, null, 'RATE_LIMITED'),
      (503, 'credit_unavailable', 'CREDIT_UNAVAILABLE'),
      (503, 'Supabase config missing.', null),
      (403, 'consent', 'CONSENT'),
      (403, 'forbidden', null),
      (502, 'Upstream error.', null),
      (400, 'Bad request.', null),
      (200, null, null),
    ];
    for (final (status, detail, want) in cases) {
      test('$status / $detail -> $want', () {
        expect(AskService.mapAskError(status, detail), want);
      });
    }
  });

  group('AskService.errKeyFor', () {
    const cases = <(String, String)>[
      ('RATE_LIMITED', 'ask.error.rate'),
      ('QUOTA', 'ask.error.quota'),
      ('CREDITS_EMPTY', 'ask.error.credits'),
      ('DAILY_LIMIT_TRIAL', 'ask.error.daily_trial'),
      ('DAILY_LIMIT_PRO', 'ask.error.daily_pro'),
      ('CREDIT_UNAVAILABLE', 'ask.error.credit_unavailable'),
      ('NETWORK_ERROR', 'ask.error'),
      ('', 'ask.error'),
    ];
    for (final (code, want) in cases) {
      test('"$code" -> $want', () {
        expect(AskService.errKeyFor(code), want);
      });
    }

    test('errKeyFor anahtarlari 8 dilde tanimli', () {
      const langs = ['ar', 'de', 'en', 'es', 'fr', 'it', 'pt', 'tr'];
      final keys = {for (final c in cases) AskService.errKeyFor(c.$1)};
      for (final l in langs) {
        final m =
            jsonDecode(File('locales/$l.json').readAsStringSync()) as Map;
        for (final k in keys) {
          expect(m.containsKey(k), isTrue, reason: '$l.json eksik: $k');
        }
      }
    });
  });
}
