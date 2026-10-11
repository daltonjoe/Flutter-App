class MatchMeta {
  final String valence;
  final int intensity;
  const MatchMeta(this.valence, this.intensity);
}

class WeightedAspect {
  final int a, b, asp;
  final double w;
  final String theme;
  const WeightedAspect(this.a, this.b, this.asp, this.w, this.theme);
}

const _imp = {1: 3, 2: 3, 4: 3, 5: 3, 3: 2, 6: 2, 7: 2, 8: 1, 9: 1, 10: 1};
const _ang = {1: 1.0, 5: 0.9, 3: 0.9, 4: 0.8, 2: 0.6};

/// orbRatio = orb/maxOrb (0..1) [? tightness bu mu, doğrulanacak]
double aspectWeight(int a, int b, int asp, double orbRatio, int intensity) {
  final imp = (_imp[a] ?? 1) + (_imp[b] ?? 1);
  final r = orbRatio.clamp(0.0, 1.0);
  return imp * (_ang[asp] ?? 0.5) * (1 - r) * intensity / 4;
}

String themeOf(int a, int b) {
  bool has(int x) => a == x || b == x;
  if (has(2)) return 'feel';
  if (has(3)) return 'talk';
  if (has(4) || has(5)) return 'pull';
  if ((a == 1 && b == 1) || (has(1) && has(7))) return 'pace';
  return 'grow';
}

List<WeightedAspect> rankAspects(List<WeightedAspect> l) =>
    ([...l]..sort((x, y) => y.w.compareTo(x.w)));

List<WeightedAspect> top3(List<WeightedAspect> l) =>
    rankAspects(l).take(3).toList();

/// En yüksek w'li iki FARKLI tema (varsa)
List<String> topThemes(List<WeightedAspect> l) {
  final out = <String>[];
  for (final x in rankAspects(l)) {
    if (!out.contains(x.theme)) out.add(x.theme);
    if (out.length == 2) break;
  }
  return out;
}