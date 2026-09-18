import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import 'onboarding_name_page.dart';
import 'onboarding_birthdate_page.dart';
import 'onboarding_city_page.dart';
import 'onboarding_gender_page.dart';
import 'onboarding_relationship_page.dart';
import '../../presentation/widgets/components/onboarding_progress_bar.dart';


class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final PageController _controller = PageController();
  final OnboardingData data = OnboardingData();
  int _step = 0;

  static const int totalSteps = 6;

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
    if (_step > 0) {
      setState(() => _step--);
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingProgressBar(currentStep: _step, totalSteps: totalSteps),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  OnboardingNamePage(data: data, onNext: _next, onBack: _back),
                  OnboardingBirthdatePage(data: data, onNext: _next, onBack: _back),
                  OnboardingBirthtimePage(data: data, onNext: _next, onBack: _back),
                  OnboardingCityPage(data: data, onNext: _next, onBack: _back),
                  OnboardingGenderPage(data: data, onNext: _next, onBack: _back),
                  OnboardingRelationshipPage(data: data, onNext: _next, onBack: _back, isLast: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}