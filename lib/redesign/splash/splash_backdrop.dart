import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../assets_map.dart';
import 'splash_clock.dart';

// Onboarding ekranlarının arkasında kayan Earth katmanı.
class SplashBackdrop extends StatefulWidget {
  const SplashBackdrop({super.key, this.showTexts = false});

  final bool showTexts;

  @override
  State<SplashBackdrop> createState() => _SplashBackdropState();
}

class _SplashBackdropState extends State<SplashBackdrop>
    with SingleTickerProviderStateMixin {
  // Saatten kalan süreye göre başlar: sayfalar arası geçişte asla sıfırlanmaz.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: SplashClock.durationMs),
    value: SplashClock.progress,
  );

  late final Animation<double> _eased =
      _c.drive(CurveTween(curve: Curves.easeInOut));

  // Metinler 2100 ms'e kadar görünür, 2500 ms'te kaybolur.
  late final Animation<double> _textsFade = _c.drive(
    Tween<double>(begin: 1, end: 0).chain(
      CurveTween(curve: const Interval(0.84, 1.0)),
    ),
  );

  @override
  void initState() {
    super.initState();
    if (_c.value < 1.0) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, c) {
          // Klavye açılınca gövde küçülse de Earth sabit kalsın.
          final double w = c.maxWidth;
          final double screenH = MediaQuery.sizeOf(context).height;
          final double h = c.maxHeight > screenH ? c.maxHeight : screenH;
          return OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: w,
            maxWidth: w,
            minHeight: h,
            maxHeight: h,
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: AppColors.bgDeep)),
                  AnimatedBuilder(
                    animation: _eased,
                    child: RepaintBoundary(
                      child: Image.asset(
                        RdAssets.earthHome,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => const _EarthFallback(),
                      ),
                    ),
                    builder: (context, child) {
                      final double side = h * 1.375;
                      final double top = h * -0.1875;
                      final double rightEdge =
                          (0.77 + (1.15 - 0.77) * _eased.value) * w;
                      // Fiziksel sol/top: RTL'de de Earth aynı tarafta kalır.
                      return Positioned(
                        left: rightEdge - side,
                        top: top,
                        width: side,
                        height: side,
                        child: child!,
                      );
                    },
                  ),
                  if (widget.showTexts) _texts(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _texts(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: FadeTransition(
            opacity: _textsFade,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  t(context, 'rd.splash.title'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppTextStyles.heroTitle(),
                ),
                const Spacer(),
                Text(
                  t(context, 'rd.splash.tagline'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTextStyles.h1(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Yedek: earth_home.jpg yoksa gösterilen gradyan daire.
class _EarthFallback extends StatelessWidget {
  const _EarthFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.violetSoft.withValues(alpha: 0.55),
            AppColors.violetDark,
            AppColors.bgDeep,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
    );
  }
}
