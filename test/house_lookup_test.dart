import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/services/house_lookup.dart';

void main() {
  final cusps = <double>[20, 50, 80, 110, 140, 170, 200, 230, 260, 290, 320, 350];

  test('lon 226.891 falls in house 7', () {
    expect(HouseLookup.houseOf(226.891, cusps), 7);
  });

  test('wrap: lon 5 with cusp 12 = 350 is house 12', () {
    expect(HouseLookup.houseOf(5, cusps), 12);
    expect(HouseLookup.houseOf(19.9, cusps), 12);
    expect(HouseLookup.houseOf(350, cusps), 12);
  });

  test('boundaries: cusp itself belongs to its house', () {
    expect(HouseLookup.houseOf(20, cusps), 1);
    expect(HouseLookup.houseOf(230, cusps), 8);
    expect(HouseLookup.houseOf(380, cusps), 1);
  });

  test('missing or invalid cusps -> null', () {
    expect(HouseLookup.houseOf(100, null), isNull);
    expect(HouseLookup.houseOf(100, const []), isNull);
    expect(HouseLookup.houseOf(100, [1, 2, 3]), isNull);
  });
}
