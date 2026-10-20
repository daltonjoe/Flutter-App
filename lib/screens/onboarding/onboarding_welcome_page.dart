import 'package:flutter/material.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';

/// S02 — Karşılama. Marka konseptini kısa bir sahneyle kurar.
/// Ekrana dokunmak sahneyi son duruma geçirir; reduce motion açıkken statik.
class OnboardingWelcomePage extends StatefulWidget {
  const OnboardingWelcomePage({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _scene;
  late final AnimationController _breath;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _scene = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3600));
    _breath = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scene.value = 1;
      _breath.value = 0.5;
    } else {
      _scene.forward();
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scene.dispose();
    _breath.dispose();
    super.dispose();
  }

  void _skip() {
    if (_scene.value < 1) _scene.value = 1;
  }

  Widget _reveal(double a, double b, Widget child) {
    return AnimatedBuilder(
      animation: _scene,
      child: child,
      builder: (context, child) {
        final v = AppMotion.enterCurve
            .transform(((_scene.value - a) / (b - a)).clamp(0.0, 1.0));
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _skip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _reveal(
                            0.0,
                            0.17,
                            AnimatedBuilder(
                              animation: _breath,
                              builder: (context, _) => Transform.scale(
                                scale: 0.85 + 0.3 * _breath.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(colors: [
                                      AppColors.gold.withValues(alpha: 0.9),
                                      AppColors.gold.withValues(alpha: 0.0),
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          _reveal(
                            0.28,
                            0.40,
                            Text(
                              t(context, 'onboarding.welcome.title'),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.heroTitle(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _reveal(
                            0.67,
                            0.78,
                            Text(
                              t(context, 'onboarding.welcome.subtitle'),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd(color: AppColors.mist),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _reveal(
                  0.9,
                  1.0,
                  Column(
                    children: [
                      CosmicCtaButton(
                        label: t(context, 'onboarding.welcome.cta'),
                        onTap: widget.onNext,
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/signin'),
                        child: Text(
                          t(context, 'onboarding.welcome.sign_in'),
                          style: AppTextStyles.ctaSecondary(),
                        ),
                      ),
                      Text(
                        t(context, 'onboarding.welcome.legal'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyXs(color: AppColors.mist),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}