import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/models/natal_chart_response.dart';

Map<String, dynamic> _group(Map<String, List<int>> v) => {
      for (final e in v.entries)
        e.key: {'raw': e.value[0], 'pct': e.value[1]},
    };

Map<String, dynamic> _sample() => {
      'elements': _group({'fire': [4, 29], 'earth': [2, 14], 'air': [5, 36], 'water': [3, 21]}),
      'modalities': _group({'cardinal': [6, 43], 'fixed': [4, 29], 'mutable': [4, 28]}),
      'polarity': _group({'active': [9, 64], 'passive': [5, 36]}),
      'birth_time_known': true,
    };

void main() {
  test('tryParse reads raw and pct', () {
    final d = ChartDistribution.tryParse(_sample())!;
    expect(d.elements['air']!.raw, 5);
    expect(d.elements['air']!.pct, 36);
    expect(d.polarity['passive']!.pct, 36);
    expect(d.birthTimeKnown, true);
  });
  test('tryParse returns null for missing group or non-map', () {
    final bad = _sample()..remove('modalities');
    expect(ChartDistribution.tryParse(bad), isNull);
    expect(ChartDistribution.tryParse(null), isNull);
  });
  test('tryParse keeps birth_time_known false', () {
    final s = _sample()..['birth_time_known'] = false;
    expect(ChartDistribution.tryParse(s)!.birthTimeKnown, false);
  });
}
