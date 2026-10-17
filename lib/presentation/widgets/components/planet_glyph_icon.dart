import 'dart:math' as math;
import 'package:flutter/material.dart';

const Set<String> kPlanetGlyphNames = {
  'sun', 'moon', 'mercury', 'venus', 'mars',
  'jupiter', 'saturn', 'uranus', 'neptune', 'pluto',
};

/// Tek aile, düz çizgi gezegen glyph seti. Çizim sınırlarından otomatik
/// ortalanır; kutu içinde her zaman tam ortadadır.
class PlanetGlyphIcon extends StatelessWidget {
  const PlanetGlyphIcon({
    super.key,
    required this.name,
    this.size = 24,
    this.color,
    this.decorative = false,
    this.semanticLabel,
  });

  final String name;
  final double size;
  final Color? color;
  final bool decorative;
  final String? semanticLabel;

  static bool supports(String n) => kPlanetGlyphNames.contains(n.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF9AA6C7);
    final w = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _PlanetGlyphPainter(name.toLowerCase(), c)),
    );
    if (decorative) return ExcludeSemantics(child: w);
    return Semantics(
      label: semanticLabel ?? name,
      image: true,
      child: ExcludeSemantics(child: w),
    );
  }
}

void _circle(Path p, double x, double y, double r) =>
    p.addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

void _line(Path p, double x1, double y1, double x2, double y2) {
  p.moveTo(x1, y1);
  p.lineTo(x2, y2);
}

class _PlanetGlyphPainter extends CustomPainter {
  _PlanetGlyphPainter(this.name, this.color);
  final String name;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final path = Path();
    var dot = false;
    switch (name) {
      case 'sun':
        _circle(path, 0, 0, 7.5);
        dot = true;
        break;
      case 'moon':
        {
          final a = Path()..addOval(Rect.fromCircle(center: const Offset(0, 0), radius: 8));
          final b = Path()..addOval(Rect.fromCircle(center: const Offset(4.4, 0), radius: 7));
          path.addPath(Path.combine(PathOperation.difference, a, b), Offset.zero);
        }
        break;
      case 'mercury':
        _circle(path, 0, 0, 3.2);
        path.addArc(Rect.fromCircle(center: const Offset(0, -6.2), radius: 3.0), 0, math.pi);
        _line(path, 0, 3.2, 0, 9);
        _line(path, -2.8, 6.2, 2.8, 6.2);
        break;
      case 'venus':
        _circle(path, 0, 0, 4.2);
        _line(path, 0, 4.2, 0, 10.5);
        _line(path, -3, 7.6, 3, 7.6);
        break;
      case 'mars':
        _circle(path, -1.2, 1.2, 4.4);
        _line(path, 1.91, -1.91, 7, -7);
        _line(path, 7, -7, 3.4, -7);
        _line(path, 7, -7, 7, -3.4);
        break;
      case 'jupiter':
        path.moveTo(-5.5, -5.5);
        path.cubicTo(-5.5, -9, 0, -9, 1, -4.5);
        path.cubicTo(1.8, -1.5, -1.5, 1.5, -6.5, 2);
        path.lineTo(6.5, 2);
        _line(path, 2.5, -2, 2.5, 8.5);
        break;
      case 'saturn':
        _line(path, -1, -9, -1, 5);
        _line(path, -4, -6.5, 2, -6.5);
        path.moveTo(-1, -2);
        path.cubicTo(3.5, -5, 6.5, 0.5, 3, 5);
        path.cubicTo(1.8, 6.5, 1.5, 8.5, 3.5, 9);
        break;
      case 'uranus':
        _line(path, -5, -8, -5, 2);
        _line(path, 5, -8, 5, 2);
        _line(path, -5, -3, 5, -3);
        _line(path, 0, -8, 0, 5.2);
        _circle(path, 0, 7.5, 2.3);
        break;
      case 'neptune':
        path.addArc(Rect.fromCircle(center: const Offset(0, -3), radius: 4.5), 0, math.pi);
        _line(path, -4.5, -3, -4.5, -8);
        _line(path, 4.5, -3, 4.5, -8);
        _line(path, 0, -8, 0, 9);
        _line(path, -3.5, 5, 3.5, 5);
        path.moveTo(-6.7, -5.8);
        path.lineTo(-4.5, -8);
        path.lineTo(-2.3, -5.8);
        path.moveTo(2.3, -5.8);
        path.lineTo(4.5, -8);
        path.lineTo(6.7, -5.8);
        path.moveTo(-2.2, -5.8);
        path.lineTo(0, -8);
        path.lineTo(2.2, -5.8);
        break;
      case 'pluto':
        path.addArc(Rect.fromCircle(center: const Offset(0, -3), radius: 5), 0, math.pi);
        _line(path, -5, -3, -5, -5.5);
        _line(path, 5, -3, 5, -5.5);
        _circle(path, 0, -3.5, 2.2);
        _line(path, 0, 2, 0, 9);
        _line(path, -3, 6, 3, 6);
        break;
      default:
        return;
    }
    final b = path.getBounds();
    final fit = s.shortestSide * 0.64;
    final k = fit / math.max(math.max(b.width, b.height), 0.0001);
    canvas.save();
    canvas.translate(s.width / 2, s.height / 2);
    canvas.scale(k);
    canvas.translate(-b.center.dx, -b.center.dy);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.075 / k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = color;
    canvas.drawPath(path, stroke);
    if (dot) {
      canvas.drawCircle(Offset.zero, 1.3, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlanetGlyphPainter old) =>
      old.name != name || old.color != color;
}
