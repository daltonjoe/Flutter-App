import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/services/cusp_parser.dart';
import 'package:flutter_application/services/house_lookup.dart';

List<Map<String, dynamic>> _rows({int skip = 0}) => [
      for (var i = 12; i >= 1; i--)
        if (i != skip) {'house_id': i, 'cusp_degree': (i - 1) * 30.0},
    ];

void main() {
  test('rows (unordered) -> 12 cusps ordered by house', () {
    final c = CuspParser.fromRows(_rows());
    expect(c, isNotNull);
    expect(c!.length, 12);
    expect(c[0], 0.0);
    expect(c[11], 330.0);
  });

  test('numeric strings are parsed', () {
    final rows = [
      for (var i = 1; i <= 12; i++) {'house_id': '$i', 'cusp_degree': '${(i - 1) * 30}.5'},
    ];
    final c = CuspParser.fromRows(rows);
    expect(c, isNotNull);
    expect(c![1], 30.5);
  });

  test('incomplete or null -> null', () {
    expect(CuspParser.fromRows(_rows(skip: 5)), isNull);
    expect(CuspParser.fromRows(null), isNull);
    expect(CuspParser.fromRows(<Map<String, dynamic>>[]), isNull);
    expect(CuspParser.fromLongitudes({1: 0.0}), isNull);
  });

  test('encode/decode roundtrip and invalid decode', () {
    final c = CuspParser.fromRows(_rows())!;
    expect(CuspParser.decode(CuspParser.encode(c)), c);
    expect(CuspParser.decode(null), isNull);
    expect(CuspParser.decode('1,2,3'), isNull);
    expect(CuspParser.decode('a,b,c,d,e,f,g,h,i,j,k,l'), isNull);
  });

  test('rows + HouseLookup: lon 226.891 -> house 8, missing cusps -> null', () {
    final c = CuspParser.fromRows(_rows());
    expect(HouseLookup.houseOf(226.891, c), 8);
    expect(HouseLookup.houseOf(226.891, CuspParser.fromRows(_rows(skip: 3))), isNull);
  });
}
