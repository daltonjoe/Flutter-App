import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../services/ai_consent_service.dart';
import '../../services/consent_service.dart';
import '../legal_agreements_page.dart';

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
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => _openLegal('settings.privacy.terms', 'legal.terms.body');
    _privacyTap = TapGestureRecognizer()
      ..onTap = () =>
          _openLegal('settings.privacy.policy', 'legal.privacy.body');
    _scene = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
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
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  /// Ilerle: privacy, terms ve ai (not) rizasi sessizce yazilir; UI beklemez.
  Future<void> _accept() async {
    await ConsentService.recordAccept();
    await AiConsentService.grantAi();
  }

  void _pickLanguage() {
    final lp = context.read<LanguageProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgVoid,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final l in LanguageProvider.supportedLanguages)
              ListTile(
                leading: Text(l['flag']!, style: const TextStyle(fontSize: 22)),
                title: Text(
                  l['label']!,
                  style: AppTextStyles.bodyMd(color: AppColors.starlight),
                ),
                trailing: lp.locale.languageCode == l['code']
                    ? const Icon(Icons.check, color: AppColors.gold)
                    : null,
                onTap: () {
                  unawaited(lp.setLocale(l['code']!));
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openLegal(String titleKey, String bodyKey) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalTextPage(titleKey: titleKey, bodyKey: bodyKey),
      ),
    );
  }

  void _skip() {
    if (_scene.value < 1) _scene.value = 1;
  }

  Widget _reveal(double a, double b, Widget child) {
    return AnimatedBuilder(
      animation: _scene,
      child: child,
      builder: (context, child) {
        final v = AppMotion.enterCurve.transform(
          ((_scene.value - a) / (b - a)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - v)),
            child: child,
          ),
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
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    icon: const Icon(Icons.language, color: AppColors.mist),
                    onPressed: _pickLanguage,
                  ),
                ),
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
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.gold.withValues(alpha: 0.9),
                                        AppColors.gold.withValues(alpha: 0.0),
                                      ],
                                    ),
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
                              style: AppTextStyles.bodyMd(
                                color: AppColors.mist,
                              ),
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
                        onTap: () {
                          // "İleri" = privacy + terms onayı; UI beklemez.
                          unawaited(_accept());
                          widget.onNext();
                        },
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/signin'),
                        child: Text(
                          t(context, 'onboarding.welcome.sign_in'),
                          style: AppTextStyles.ctaSecondary(),
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          style: AppTextStyles.bodyXs(color: AppColors.mist),
                          children: [
                            TextSpan(
                              text: t(context, 'onboarding.welcome.legal_a'),
                            ),
                            TextSpan(
                              text: t(
                                context,
                                'onboarding.welcome.legal_terms',
                              ),
                              style: AppTextStyles.bodyXs(
                                color: AppColors.starlight,
                              ).copyWith(decoration: TextDecoration.underline),
                              recognizer: _termsTap,
                            ),
                            TextSpan(
                              text: t(context, 'onboarding.welcome.legal_b'),
                            ),
                            TextSpan(
                              text: t(
                                context,
                                'onboarding.welcome.legal_privacy',
                              ),
                              style: AppTextStyles.bodyXs(
                                color: AppColors.starlight,
                              ).copyWith(decoration: TextDecoration.underline),
                              recognizer: _privacyTap,
                            ),
                            TextSpan(
                              text: t(context, 'onboarding.welcome.legal_c'),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t(context, 'onboarding.welcome.memory'),
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
