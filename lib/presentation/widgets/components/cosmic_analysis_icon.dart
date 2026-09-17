// lib/presentation/widgets/components/cosmic_analysis_icon.dart
// SoulBound Cosmic Sanctum — animated floating icon badge
//
// Replaces FloatingAnalysisIcon. Used inside AnalysisSectionCard and
// planet header cards.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A circular badge that displays an emoji/glyph with a subtle float + rotate
/// animation and a coloured ambient glow.
class CosmicAnalysisIcon extends StatefulWidget {
  const CosmicAnalysisIcon({
    super.key,
    required this.icon,
    this.size = 44,
    this.color,
    this.animate = true,
  });

  final String icon;
  final double size;

  /// Tint colour for the background and glow (defaults to violet).
  final Color? color;

  /// Set false for static rendering (e.g. in list thumbnails).
  final bool animate;

  @override
  State<CosmicAnalysisIcon> createState() => _CosmicAnalysisIconState();
}

class _CosmicAnalysisIconState extends State<CosmicAnalysisIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _float = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _rotate = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.violetPrimary;

    final badge = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.icon,
          style: TextStyle(
            fontSize: widget.size * 0.6,
            color: Colors.white,
          ),
        ),
      ),
    );

    if (!widget.animate) return badge;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _float.value),
        child: Transform.rotate(
          angle: _rotate.value,
          child: badge,
        ),
      ),
    );
  }
}
