/// Pure house lookup (no Flutter imports).
class HouseLookup {
  static double _norm(double v) => ((v % 360) + 360) % 360;

  /// [cusps]: 12 absolute longitudes (0-360), index 0 = house 1 cusp.
  /// Returns 1..12, or null if cusps are missing/invalid.
  /// House i covers cusp[i] <= lon < cusp[i+1] (wraps at 360).
  static int? houseOf(double eventLon, List<double>? cusps) {
    if (cusps == null || cusps.length != 12) return null;
    final lon = _norm(eventLon);
    for (var i = 0; i < 12; i++) {
      final start = _norm(cusps[i]);
      final end = _norm(cusps[(i + 1) % 12]);
      var span = _norm(end - start);
      if (span == 0) span = 360;
      final off = _norm(lon - start);
      if (off < span) return i + 1;
    }
    return null;
  }
}
