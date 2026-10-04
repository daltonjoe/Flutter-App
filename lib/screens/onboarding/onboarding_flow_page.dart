import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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



class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key, required this.isFirstProfile});

  final bool isFirstProfile;

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  late final PageController _controller;
  final OnboardingData data = OnboardingData();
  late int _step;

  static const int totalSteps = 7;

  int get _minStep => widget.isFirstProfile ? 0 : 1;

  @override
  void initState() {
    super.initState();
    _step = _minStep;
    _controller = PageController(initialPage: _minStep);
    if (!widget.isFirstProfile) {
      data.languageCode = context.read<LanguageProvider>().locale.languageCode;
    }
  }

  void _next() {
    if (_step < totalSteps - 1) {
      setState(() => _step++);
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _back() {
    if (_step > _minStep) {
      setState(() => _step--);
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
      backgroundColor: Colors.black, // background.png yüklenemezse siyah kalsın
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) Statik yedek arka plan
          Positioned.fill(
            child: Image.asset(
              'assets/images/logo/background.png',
              fit: BoxFit.cover,
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