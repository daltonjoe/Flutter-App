import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';

/// Reusable Zodiac Orbital Animation Widget.
/// Simulates a planetary system where zodiac icons orbit a central point.
class ZodiacOrbitalAnimation extends StatefulWidget {
  final double size;
  final bool isStatic; // If true, only one sign is highlighted (useful for specific analysis)
  final String? highlightedSign;

  const ZodiacOrbitalAnimation({
    super.key,
    this.size = 300,
    this.isStatic = false,
    this.highlightedSign,
  });

  @override
  State<ZodiacOrbitalAnimation> createState() => _ZodiacOrbitalAnimationState();
}

class _ZodiacOrbitalAnimationState extends State<ZodiacOrbitalAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<String> _zodiacIcons = [
    '♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓'
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Central Glow (The Sun) ───────────────────────────
          Container(
            width: widget.size * 0.2,
            height: widget.size * 0.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.violet.withOpacity(0.5),
                  AppTheme.violet.withOpacity(0.0),
                ],
              ),
            ),
          ),

          // ── Background Stars/Particles ───────────────────────
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _BackgroundParticlePainter(),
          ),

          // ── Zodiac Orbits ────────────────────────────────────
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: List.generate(_zodiacIcons.length, (index) {
                  // Unique orbit for each icon
                  final double baseRadius = widget.size * 0.35;
                  final double radiusVar = (index % 3) * (widget.size * 0.05);
                  final double radius = baseRadius + radiusVar;
                  
                  // Varying speeds
                  final double speedFactor = 1.0 + (index * 0.1);
                  final double angle = (_controller.value * 2 * math.pi * speedFactor) + 
                                     (index * (2 * math.pi / _zodiacIcons.length));

                  final double x = math.cos(angle) * radius;
                  final double y = math.sin(angle) * radius * 0.6; // Elliptical

                  return Transform.translate(
                    offset: Offset(x, y),
                    child: Opacity(
                      opacity: 0.8,
                      child: Text(
                        _zodiacIcons[index],
                        style: TextStyle(
                          fontSize: widget.size * 0.06,
                          color: AppTheme.textPrimary.withOpacity(0.9),
                          shadows: [
                            Shadow(
                              color: AppTheme.violet.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BackgroundParticlePainter extends CustomPainter {
  final List<Offset> _stars = List.generate(50, (index) => 
    Offset(math.Random().nextDouble(), math.Random().nextDouble()));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    for (var star in _stars) {
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        math.Random().nextDouble() * 1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
