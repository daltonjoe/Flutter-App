/// Pure cusp parsing (no Flutter imports).
class CuspParser {
  /// rows: user_chart_houses rows {house_id, cusp_degree}.
  /// Returns 12 cusps (index 0 = house 1) or null if incomplete.
  static List<double>? fromRows(List<Map<String, dynamic>>? rows) {
    if (rows == null) return null;
    final byHouse = <int, double>{};
    for (final r in rows) {
      final h = _toInt(r['house_id']);
      final d = _toDouble(r['cusp_degree']);
      if (h == null || d == null || h < 1 || h > 12) continue;
      byHouse[h] = d;
    }
    return _assemble(byHouse);
  }

  static List<double>? fromLongitudes(Map<int, double>? byHouse) {
    if (byHouse == null) return null;
    return _assemble(byHouse);
  }

  static List<double>? _assemble(Map<int, double> m) {
    if (m.length != 12) return null;
    final out = <double>[];
    for (var i = 1; i <= 12; i++) {
      final v = m[i];
      if (v == null) return null;
      out.add(v);
    }
    return out;
  }

  static String encode(List<double> cusps) => cusps.join(',');

  static List<double>? decode(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(',');
    if (parts.length != 12) return null;
    final out = <double>[];
    for (final p in parts) {
      final v = double.tryParse(p);
      if (v == null) return null;
      out.add(v);
    }
    return out;
  }

  static int? _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
  static double? _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
}
