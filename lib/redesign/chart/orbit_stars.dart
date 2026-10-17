import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Yörünge halkalarının çapları (dp). Merkez ortak olduğu için yarıçaplar
/// 100 / 125 / 150 dp olur; halka ressamı ve yıldızlar bu listeyi paylaşır.
const List<double> kRingDiameters = <double>[200, 250, 300];

/// Halka başına yıldız sayısı (iç → dış): 4 + 5 + 6 = 15.
const List<int> _kStarCounts = <int>[4, 5, 6];

/// Halka başına kayma süresi (ms) ve yönü.
const List<int> _kMoveDurationsMs = <int>[1200, 1500, 1800];
const List<double> _kMoveDirs = <double>[1, -1, 1];

/// Halka başına kayma miktarı (derece, 40–80 aralığında).
const List<double> _kMoveSweepDeg = <double>[48, 62, 76];

/// Yörünge halkaları üzerinde yavaşça parlayan yıldızlar.
///
/// [trigger] (gezegen anahtarının kendisi) değişince her halka kendi süresi,
/// yönü ve küçük açısıyla yumuşakça kayar; ambient parlama tek bir 6 sn'lik
/// döngüdür. [reduceMotion] true iken hiçbir hareket/parlama çalışmaz ve
/// yıldızlar sabit görünür. Sayfa görünmezken (TickerMode kapalı) ticker'lar
/// [TickerProviderStateMixin] sayesinde askıya alınır.
class OrbitStars extends StatefulWidget {
  const OrbitStars({
    super.key,
    required this.trigger,
    required this.reduceMotion,
  });

  /// Her değişimde yıldızları kaydıran tetik (gezegen anahtarı).
  final Object? trigger;

  /// true ise hareket ve parlama kapalı.
  final bool reduceMotion;

  @override
  State<OrbitStars> createState() => _OrbitStarsState();
}

class _OrbitStarsState extends State<OrbitStars> with TickerProviderStateMixin {
  late final List<AnimationController> _move = <AnimationController>[
    for (final ms in _kMoveDurationsMs)
      AnimationController(
        vsync: this,
        duration: Duration(milliseconds: ms),
        value: 1,
      ),
  ];

  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  final List<double> _from = <double>[0, 0, 0];
  final List<double> _to = <double>[0, 0, 0];

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _twinkle.repeat();
  }

  @override
  void didUpdateWidget(covariant OrbitStars old) {
    super.didUpdateWidget(old);
    if (old.reduceMotion != widget.reduceMotion) {
      if (widget.reduceMotion) {
        _twinkle.stop();
        for (var i = 0; i < _move.length; i++) {
          _from[i] = _to[i];
          _move[i].value = 1;
        }
      } else {
        _twinkle.repeat();
      }
    }
    if (old.trigger != widget.trigger) {
      for (var i = 0; i < _move.length; i++) {
        _from[i] = _rot(i);
        _to[i] = _from[i] + _kMoveDirs[i] * _kMoveSweepDeg[i] * math.pi / 180.0;
        if (widget.reduceMotion) {
          _from[i] = _to[i];
          _move[i].value = 1;
        } else {
          _move[i].forward(from: 0);
        }
      }
    }
  }

  double _rot(int i) =>
      _from[i] +
      (_to[i] - _from[i]) * Curves.easeInOutCubic.transform(_move[i].value);

  @override
  void dispose() {
    for (final c in _move) {
      c.dispose();
    }
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth.isFinite ? box.maxWidth : 320.0;
          final h = box.maxHeight.isFinite ? box.maxHeight : 280.0;
          return SizedBox(
            width: w,
            height: h,
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[..._move, _twinkle]),
              builder: (_, _) => CustomPaint(
                painter: _StarsPainter(
                  rot: <double>[for (var i = 0; i < _move.length; i++) _rot(i)],
                  twinkle: _twinkle.value,
                  reduceMotion: widget.reduceMotion,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Halkalar üzerine küçük 4 köşeli parıltıları çizen ressam.
///
/// Yarıçaplar [kRingDiameters]'tan okunur; merkez, halka ressamıyla aynı
/// kutunun merkezidir.
class _StarsPainter extends CustomPainter {
  _StarsPainter({
    required this.rot,
    required this.twinkle,
    required this.reduceMotion,
  });

  /// Halka başına dönüş açısı (radyan).
  final List<double> rot;

  /// 0–1 ambient parlama fazı.
  final double twinkle;

  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size s) {
    final center = s.center(Offset.zero);
    for (var i = 0; i < kRingDiameters.length; i++) {
      final radius = kRingDiameters[i] / 2;
      final n = _kStarCounts[i % _kStarCounts.length];
      final spin = i < rot.length ? rot[i] : 0.0;
      for (var j = 0; j < n; j++) {
        final a = (j / n) * 2 * math.pi + i * 0.9 + spin;
        final p = center + Offset(math.cos(a) * radius, math.sin(a) * radius);
        final phase = (twinkle + (i * 7 + j * 3) / 17.0) % 1.0;
        final alpha = reduceMotion
            ? 0.70
            : 0.40 + 0.35 * math.sin(phase * 2 * math.pi);
        final color = (j % 2 == 0) ? AppColors.gold : AppColors.starlight;
        final size = (j == 0 ? 4.6 : 3.2) + (i == 1 ? 0.4 : 0.0);
        _drawStar(
          canvas,
          p,
          size,
          color.withValues(alpha: alpha.clamp(0.15, 0.95)),
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset p, double r, Color color) {
    canvas.drawCircle(
      p,
      r * 1.7,
      Paint()..color = color.withValues(alpha: color.a * 0.18),
    );
    final path = Path()
      ..moveTo(p.dx, p.dy - r)
      ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
      ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) =>
      old.twinkle != twinkle ||
      old.reduceMotion != reduceMotion ||
      !listEquals(old.rot, rot);
}
