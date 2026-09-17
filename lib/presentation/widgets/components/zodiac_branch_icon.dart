// lib/presentation/widgets/components/zodiac_branch_icon.dart
// SoulBound Cosmic Sanctum — multi-layer zodiac icon component
//
// IMPORTANT: The multi-layer structure is intentional and must NOT be flattened.
// Each layer serves a distinct visual role in the Cosmic Sanctum design language.
//
// Layer 1 — Background radial halo (ambient colour field)
// Layer 2 — Constellation web (CustomPaint star lines)
// Layer 3 — Orbital ring (the rotating glyph orbit)
// Layer 4 — Astrological glyph (the sign character, centred)

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';

// ── Size presets ──────────────────────────────────────────────────────────────
enum ZodiacIconSize {
  /// 72×72 — hero display (header card, create profile)
  hero,

  /// 44×44 — list / planet card
  card,

  /// 32×32 — mini badge (retrograde chips, inline labels)
  mini,
}

extension _ZodiacIconSizeValue on ZodiacIconSize {
  double get dimension => switch (this) {
        ZodiacIconSize.hero => 72,
        ZodiacIconSize.card => 44,
        ZodiacIconSize.mini => 32,
      };

  double get glyphSize => switch (this) {
        ZodiacIconSize.hero => 28,
        ZodiacIconSize.card => 18,
        ZodiacIconSize.mini => 13,
      };

  int get webPoints => switch (this) {
        ZodiacIconSize.hero => 8,
        ZodiacIconSize.card => 5,
        ZodiacIconSize.mini => 4,
      };

  bool get showOrbit => this != ZodiacIconSize.mini;
}

/// A multi-layer zodiac icon.
///
/// Pass the astrological [glyph] (e.g. '♈'), an optional [accentColor] for
/// the halo and glow, and a [size] preset. All layers can be individually
/// suppressed via boolean flags.
class ZodiacBranchIcon extends StatefulWidget {
  const ZodiacBranchIcon({
    super.key,
    required this.glyph,
    this.size = ZodiacIconSize.card,
    this.accentColor,
    this.animate = true,
    this.showHalo = true,
    this.showWeb = true,
    this.showOrbit = true,
  });

  final String glyph;
  final ZodiacIconSize size;

  /// Accent colour for halo, web lines and glow (defaults to violetPrimary).
  final Color? accentColor;

  /// Animate the orbital ring. Set false for static thumbnails.
  final bool animate;

  // ── Per-layer overrides ──────────────────────────────────────────────
  final bool showHalo;
  final bool showWeb;

  /// Orbital ring is hidden for [ZodiacIconSize.mini] automatically,
  /// unless explicitly overridden to true here.
  final bool showOrbit;

  @override
  State<ZodiacBranchIcon> createState() => _ZodiacBranchIconState();
}

class _ZodiacBranchIconState extends State<ZodiacBranchIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.animate) _orbit.repeat();
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.violetPrimary;
    final dim = widget.size.dimension;
    final showOrbit = widget.showOrbit && widget.size.showOrbit;

    return SizedBox(
      width: dim,
      height: dim,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Layer 1: Background radial halo ───────────────────────────
          if (widget.showHalo)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.22),
                      accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

          // ── Layer 2: Constellation web ────────────────────────────────
          if (widget.showWeb)
            CustomPaint(
              size: Size(dim, dim),
              painter: _ConstellationWebPainter(
                color: accent,
                points: widget.size.webPoints,
              ),
            ),

          // ── Layer 3: Orbital ring (animated) ─────────────────────────
          if (showOrbit)
            AnimatedBuilder(
              animation: _orbit,
              builder: (context, child) => CustomPaint(
                size: Size(dim, dim),
                painter: _OrbitalRingPainter(
                  color: accent,
                  progress: _orbit.value,
                ),
              ),
            ),

          // ── Layer 4: Astrological glyph ──────────────────────────────
          Container(
            width: dim * 0.5,
            height: dim * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.06),
                ],
              ),
            ),
            child: Center(
              child: Text(
                widget.glyph,
                style: TextStyle(
                  fontSize: widget.size.glyphSize,
                  color: AppColors.textPrimary,
                  shadows: [
                    Shadow(
                      color: accent.withValues(alpha: 0.7),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Layer 2 painter: constellation web ───────────────────────────────────────
class _ConstellationWebPainter extends CustomPainter {
  const _ConstellationWebPainter({required this.color, required this.points});

  final Color color;
  final int points;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final offsets = List.generate(points, (i) {
      final angle = (i / points) * 2 * math.pi - math.pi / 2;
      return Offset(center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle));
    });

    // Draw connecting lines (every other node to create a star polygon feel)
    for (int i = 0; i < offsets.length; i++) {
      canvas.drawLine(offsets[i], offsets[(i + 2) % offsets.length], paint);
    }

    // Draw dots at each node
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    for (final o in offsets) {
      canvas.drawCircle(o, 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ConstellationWebPainter old) =>
      old.color != color || old.points != points;
}

// ── Layer 3 painter: orbital ring ────────────────────────────────────────────
class _OrbitalRingPainter extends CustomPainter {
  const _OrbitalRingPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.44;

    // Static orbit circle
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    // Moving dot on the orbit
    final angle = progress * 2 * math.pi;
    final dotPos = Offset(
      center.dx + r * math.cos(angle),
      center.dy + r * math.sin(angle),
    );
    canvas.drawCircle(
      dotPos,
      2.0,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_OrbitalRingPainter old) => old.progress != progress;
}
