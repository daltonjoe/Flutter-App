import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A widget that displays a zodiac or planet icon with a subtle floating and rotating animation.
class FloatingAnalysisIcon extends StatefulWidget {
  final String icon;
  final double size;
  final Color? color;

  const FloatingAnalysisIcon({
    super.key,
    required this.icon,
    this.size = 40,
    this.color,
  });

  @override
  State<FloatingAnalysisIcon> createState() => _FloatingAnalysisIconState();
}

class _FloatingAnalysisIconState extends State<FloatingAnalysisIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatingAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatingAnim = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateAnim = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnim.value),
          child: Transform.rotate(
            angle: _rotateAnim.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (widget.color ?? AppTheme.violet).withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: (widget.color ?? AppTheme.violet).withOpacity(0.2),
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
            ),
          ),
        );
      },
    );
  }
}
