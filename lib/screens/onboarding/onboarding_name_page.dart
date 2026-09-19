import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../presentation/widgets/components/cosmic_input_field.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../i18n/app_localizations.dart';
import 'dart:math' as math;
import '../../presentation/widgets/components/cosmic_alert_dialog.dart';


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

class _OnboardingNamePageState extends State<OnboardingNamePage>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _shake;
  bool _warned = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.data.name);
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _controller.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    if ((widget.data.name ?? '').trim().isNotEmpty) {
      widget.onNext();
      return;
    }
    if (_warned) {
      _shake.forward(from: 0);
      return;
    }
    _warned = true;
    FocusScope.of(context).unfocus();
    await showCosmicAlert(
      context,
      message: t(context, 'onboarding.name.required'),
      actions: [CosmicAlertAction(label: t(context, 'common.ok'))],
    );
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


                          AnimatedBuilder(
                            animation: _shake,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(
                                  math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 12, 0),
                              child: child,
                            ),
                            child: CosmicInputField(
                            label: t(context, 'onboarding.name.label'),
                            icon: Icons.person_outline,
                            controller: _controller,
                            hint: t(context, 'onboarding.name.hint'),
                            onChanged: (value) => widget.data.name = value,
                          ),
                          ),



                        ],
                      ),
                    ),
                  ),
                ),
                CosmicCtaButton(label: t(context, 'common.next'), onTap: _onNext),
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