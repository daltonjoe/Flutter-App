import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/language_provider.dart';
import '../../models/onboarding_data.dart';
import 'onboarding_name_page.dart';
import 'onboarding_birthtime_page.dart';
import 'onboarding_city_page.dart';
import 'onboarding_gender_page.dart';
import 'onboarding_relationship_page.dart';
import '../../presentation/widgets/components/onboarding_progress_bar.dart';
import 'onboarding_birthdate_page.dart';
import 'onboarding_language_page.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show ImageFilter, TileMode, lerpDouble;
import '../../core/motion/app_motion.dart';
import '../../core/motion/resolution_controller.dart';
import 'onboarding_welcome_page.dart';



class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key, required this.isFirstProfile, this.skipLanguage = false});

  final bool isFirstProfile;
  final bool skipLanguage;

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  late final PageController _controller;
  final OnboardingData data = OnboardingData();
  final ResolutionController _res = ResolutionController();
  late int _step;

  static const int totalSteps = 8;

  /// Adım indeksine göre onboarding çözünürlüğü (plan Bölüm 3.2).
  static const List<double> _resolutionByStep = [
    0.0, 0.05, 0.18, 0.34, 0.48, 0.62, 0.70, 0.78,
  ];

  int get _minStep => (widget.isFirstProfile && !widget.skipLanguage) ? 0 : 2;

  @override
  void initState() {
    super.initState();
    _step = _minStep;
    _res.setTarget(_resolutionByStep[_step]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
    });
    _controller = PageController(initialPage: _minStep);
    if (!widget.isFirstProfile || widget.skipLanguage) {
      data.languageCode = context.read<LanguageProvider>().locale.languageCode;
    }
  }

  @override
  void dispose() {
    _res.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < totalSteps - 1) {
      setState(() => _step++);
      _res.setTarget(_resolutionByStep[_step]);
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _back() {
    if (_step > _minStep) {
      setState(() => _step--);
      _res.setTarget(_resolutionByStep[_step]);
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
  onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
      backgroundColor: AppColors.bgVoid, // background.png yüklenemezse siyah kalsın
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Statik yedek arka plan
          Positioned.fill(
            child: ListenableBuilder(
              listenable: _res,
              builder: (context, _) => TweenAnimationBuilder<double>(
                tween: Tween<double>(end: _res.value),
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.resolution,
                curve: AppMotion.resolutionCurve,
                builder: (context, v, child) {
                  final sigma = lerpDouble(18, 0, v)!;
                  if (sigma < 0.1) return child!;
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(
                        sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.mirror),
                    child: child,
                  );
                },
                child: RepaintBoundary(child: Image.asset('assets/images/logo/background.jpg', fit: BoxFit.cover)),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                OnboardingProgressBar(
                  currentStep: _step,
                  totalSteps: totalSteps,
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (index) {
                      if (_step != index) {
                        setState(() => _step = index);
                      }
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      OnboardingLanguagePage(
                          data: data, onNext: _next, onBack: _back),
                      OnboardingWelcomePage(onNext: _next),
                      OnboardingNamePage(
                          data: data, onNext: _next, onBack: _back),
                      OnboardingBirthdatePage(
                          data: data, onNext: _next, onBack: _back),
                      OnboardingBirthtimePage(
                          data: data, onNext: _next, onBack: _back),
                      OnboardingCityPage(
                          data: data, onNext: _next, onBack: _back),
                      OnboardingGenderPage(
                          data: data, onNext: _next, onBack: _back),
                      OnboardingRelationshipPage(
                        data: data,
                        onNext: _next,
                        onBack: _back,
                        isLast: true,
                        isFirstProfile: widget.isFirstProfile,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}