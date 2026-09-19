import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_wheel_picker.dart';

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
    if (_selected == 'prefer_not_to_say') return 'assets/images/logo/prefernottosay.png';
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
                Text(
                t(context, 'onboarding.gender.title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: descColor),
                ),
                const SizedBox(height: 12),
                SizedBox(
                height: 260,
                child: _imagePath != null
                    ? Image.asset(_imagePath!, fit: BoxFit.contain)
                    : null,
                ),
                const SizedBox(height: 8),
                Text(
                t(context, 'onboarding.gender.subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(color: descColor),
                ),
                Expanded(
                child: CosmicWheelPicker(
                    options: _options
                        .map((o) => WheelOption(
                            o,
                            t(context, 'onboarding.gender.$o'),
                            o == 'female'
                                ? WheelTone.female
                                : o == 'male'
                                    ? WheelTone.male
                                    : WheelTone.neutral,
                            ))
                        .toList(),
                    selected: _selected,
                    onSelected: _select,
                ),
                ),
                CosmicCtaButton(label: t(context, 'common.next'), onTap: widget.onNext),
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