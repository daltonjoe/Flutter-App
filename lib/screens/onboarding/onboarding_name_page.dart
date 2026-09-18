import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../presentation/widgets/components/cosmic_input_field.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../presentation/widgets/components/cosmic_outline_button.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              // Title, subtitle, progress bar burada
              CosmicInputField(
                label: 'Name',
                icon: Icons.person_outline,
                controller: _controller,
                hint: 'Enter your name',
                onChanged: (value) => widget.data.name = value,
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: CosmicOutlineButton(
                            label: 'Skip!',
                            onTap: widget.onNext,
                            ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CosmicCtaButton(
                        label: 'Next',
                        onTap: widget.onNext,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}