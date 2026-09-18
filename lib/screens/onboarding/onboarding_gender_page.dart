import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../i18n/app_localizations.dart';

class OnboardingGenderPage extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isLast;

  const OnboardingGenderPage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
    this.isLast = false,
  });

  @override
  State<OnboardingGenderPage> createState() => _OnboardingGenderPageState();
}

class _OnboardingGenderPageState extends State<OnboardingGenderPage> {
  String? _selected;

  static const List<String> _options = ['female', 'male', 'prefer_not_to_say'];

  String? get _imagePath {
    if (_selected == 'male') return 'assets/images/logo/male.png';
    if (_selected == 'female') return 'assets/images/logo/female.png';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.data.gender;
  }

  void _select(String value) {
    setState(() {
      _selected = value;
      widget.data.gender = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final descColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/logo/background.png', fit: BoxFit.cover),
          ),
          SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            t(context, 'onboarding.gender.title'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: descColor),
                          ),
                          const SizedBox(height: 16),
                          if (_imagePath != null)
                            Image.asset(_imagePath!, width: 200, height: 200),
                          const SizedBox(height: 16),
                          Text(
                            t(context, 'onboarding.gender.subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: descColor),
                          ),
                          const SizedBox(height: 16),
                          ..._options.map(
                            (option) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => _select(option),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _selected == option
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).dividerColor,
                                      width: _selected == option ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    t(context, 'onboarding.gender.$option'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                CosmicCtaButton(label: 'Next', onTap: widget.onNext),
                const SizedBox(height: 24),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}