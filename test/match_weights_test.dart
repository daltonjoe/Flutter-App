import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/core/match_weights.dart';

void main() {
  test('tema önceliği', () {
    expect(themeOf(2, 4), 'feel');
    expect(themeOf(3, 5), 'talk');
    expect(themeOf(1, 4), 'pull');
    expect(themeOf(1, 7), 'pace');
    expect(themeOf(6, 9), 'grow');
  });
  test('ağırlık', () {
    expect(aspectWeight(1, 2, 1, 1.0, 4), 0);
    expect(aspectWeight(1, 2, 1, 0, 4), 6.0);
    expect(aspectWeight(1, 2, 1, 0, 1), closeTo(1.5, 1e-9));
  });
  test('iki farklı tema', () {
    final l = [
      const WeightedAspect(2, 4, 1, 5, 'feel'),
      const WeightedAspect(2, 5, 1, 4, 'feel'),
      const WeightedAspect(4, 5, 1, 3, 'pull'),
    ];
    expect(topThemes(l), ['feel', 'pull']);
  });
  test('yon korunur', () {
    const x = WeightedAspect(1, 4, 1, 2, 'pull', fromA: 4, fromB: 1);
    expect(x.fromA, 4);
    expect(x.fromB, 1);
    expect(const WeightedAspect(1, 4, 1, 2, 'pull').fromA, 0);
  });
}