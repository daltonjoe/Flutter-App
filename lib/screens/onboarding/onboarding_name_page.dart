import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../presentation/widgets/components/cosmic_input_field.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../i18n/app_localizations.dart';

class OnboardingNamePage extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isLast;

  const OnboardingNamePage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
    this.isLast = false,
  });

  @override
  State<OnboardingNamePage> createState() => _OnboardingNamePageState();
}

class _OnboardingNamePageState extends State<OnboardingNamePage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.data.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                            t(context, 'onboarding.name.subtitle'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: descColor),
                          ),
                          const SizedBox(height: 24),
                          CosmicInputField(
                            label: t(context, 'onboarding.name.label'),
                            icon: Icons.person_outline,
                            controller: _controller,
                            hint: t(context, 'onboarding.name.hint'),
                            onChanged: (value) => widget.data.name = value,
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