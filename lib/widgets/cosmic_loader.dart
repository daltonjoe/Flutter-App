// lib/widgets/cosmic_loader.dart
// Moonly-style animated loading widget

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../i18n/app_localizations.dart';
import '../core/widgets/app_loader.dart';
import './animations/zodiac_orbital_animation.dart';

class CosmicLoader extends StatefulWidget {
  final String? message;
  final bool useLottie;

  const CosmicLoader({super.key, this.message, this.useLottie = false});

  @override
  State<CosmicLoader> createState() => _CosmicLoaderState();
}

class _CosmicLoaderState extends State<CosmicLoader>
    with TickerProviderStateMixin {
  static const List<String> _messageKeys = [
    'loader.msg_1',
    'loader.msg_2',
    'loader.msg_3',
    'loader.msg_4',
    'loader.msg_5',
    'loader.msg_6',
    'loader.msg_7',
  ];

  int _msgIndex = 0;
  Timer? _msgTimer;

  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _orbitCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _orbitAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _pulseAnim = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _rotateAnim = Tween<double>(begin: 0, end: 1).animate(_rotateCtrl);
    _orbitAnim = Tween<double>(begin: 0, end: 1).animate(_orbitCtrl);
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn));

    if (widget.message == null) {
      _msgTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _fadeCtrl.reverse().then((_) {
          if (!mounted) return;
          setState(() => _msgIndex = (_msgIndex + 1) % _messageKeys.length);
          _fadeCtrl.forward();
        });
      });
    }
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _orbitCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message ?? t(context, _messageKeys[_msgIndex]);

    return Container(
      color: AppTheme.bgDeep,
      child: SafeArea(
        child: Column(
          children: [
            // ── Animasyon Bölümü (Flex 7) ─────────────────────────────
            Expanded(
              flex: 7,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: widget.useLottie
                        ? const AppLoader()
                        : const ZodiacOrbitalAnimation(size: 400),
                  ),
                ),
              ),
            ),

            // ── Metin ve Progress (Flex 3) ─────────────────────────────
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // ── Dönen mesaj ───────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Progress bar ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        backgroundColor: AppTheme.violet.withOpacity(0.12),
                        valueColor: const AlwaysStoppedAnimation(
                          AppTheme.violet,
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRingPainter extends CustomPainter {
  final int count;
  final double radius;
  final bool small;

  const _StarRingPainter({
    required this.count,
    required this.radius,
    this.small = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final isMain = i % 3 == 0;
      if (isMain) {
        paint.color = AppTheme.gold.withOpacity(0.9);
        canvas.drawCircle(Offset(x, y), small ? 2.5 : 3.5, paint);
      } else {
        paint.color = AppTheme.violet.withOpacity(0.5);
        canvas.drawCircle(Offset(x, y), small ? 1.5 : 2.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ── Full-screen loading scaffold ─────────────────────────────────────
class CosmicLoadingScreen extends StatelessWidget {
  final String? message;
  final bool useLottie;

  const CosmicLoadingScreen({super.key, this.message, this.useLottie = false});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgDeep,
    body: CosmicLoader(message: message, useLottie: useLottie),
  );
}
