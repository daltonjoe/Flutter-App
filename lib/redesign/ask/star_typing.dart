// lib/redesign/ask/star_typing.dart
// Ask — "yazıyor" göstergesi (üç altın yıldız) ve paylaşılan yıldız işareti.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';

/// Küçük altın yıldız işareti (✦).
class AskStar extends StatelessWidget {
  const AskStar({super.key, this.size = 14, this.color = AppColors.gold});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '\u2726',
      textScaler: TextScaler.noScaling,
      style: TextStyle(fontSize: size, height: 1.0, color: color),
    );
  }
}

/// Asistan yanıtı beklenirken gösterilen üç yıldızlı animasyon.
///
/// Hareket azaltma açıkken statik [ask.typing] metnine düşer.
class StarTyping extends StatefulWidget {
  const StarTyping({super.key});

  @override
  State<StarTyping> createState() => _StarTypingState();
}

class _StarTypingState extends State<StarTyping>
    with SingleTickerProviderStateMixin {
  static const Duration _cycle = Duration(milliseconds: 900);
  // Yıldızlar arası 150 ms kayma (döngünün 1/6'sı).
  static const double _shift = 150 / 900;

  AnimationController? _c;

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  double _opacity(int i) {
    final v = (_c!.value + i * _shift) % 1.0;
    final s = (math.sin(v * 2 * math.pi - math.pi / 2) + 1) / 2;
    return 0.30 + 0.70 * s;
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
          child: Text(t(context, 'ask.typing'), style: AppTextStyles.bodySm()),
        ),
      );
    }
    _c ??= AnimationController(vsync: this, duration: _cycle)..repeat();
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        child: AnimatedBuilder(
          animation: _c!,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                Opacity(opacity: _opacity(i), child: const AskStar(size: 8)),
                if (i < 2) const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
