import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../i18n/app_localizations.dart';

class OnboardingBirthtimePage extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isLast;

  const OnboardingBirthtimePage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
    this.isLast = false,
  });

  @override
  State<OnboardingBirthtimePage> createState() => _OnboardingBirthtimePageState();
}

class _OnboardingBirthtimePageState extends State<OnboardingBirthtimePage> {
  TimeOfDay? _selectedTime;
  bool _unknown = false;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.data.birthTime;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _unknown = false;
        widget.data.birthTime = picked;
      });
    }
  }

  void _markUnknown() {
    setState(() {
      _unknown = true;
      _selectedTime = const TimeOfDay(hour: 12, minute: 0);
      widget.data.birthTime = _selectedTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final descColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/logo/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
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
                            'What time were you born?',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: descColor),
                          ),
                          const SizedBox(height: 16),
                          Image.asset(
                            'assets/images/logo/frame13.png',
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t(context, 'onboarding.birthtime.subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: descColor),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _unknown
                                    ? "I don't know"
                                    : (_selectedTime?.format(context) ?? '--:--'),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _markUnknown,
                            child: const Text("I don't know"),
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
      ),
    );
  }
}