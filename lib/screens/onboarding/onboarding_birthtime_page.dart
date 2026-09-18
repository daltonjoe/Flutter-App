import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../i18n/app_localizations.dart';
import 'package:flutter/cupertino.dart';

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
    late DateTime _selectedTime;
    bool _unknown = false;

    @override
    void initState() {
      super.initState();
      final t = widget.data.birthTime;
      _selectedTime = DateTime(2000, 1, 1, t?.hour ?? 12, t?.minute ?? 0);
    }

    void _onTimeChanged(DateTime time) {
      setState(() {
        _selectedTime = time;
        _unknown = false;
        widget.data.birthTime = TimeOfDay(hour: time.hour, minute: time.minute);
      });
    }

    void _markUnknown() {
      setState(() {
        _unknown = true;
        _selectedTime = DateTime(2000, 1, 1, 12, 0);
        widget.data.birthTime = const TimeOfDay(hour: 12, minute: 0);
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
                            t(context, 'onboarding.birthtime.title'),
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
                          SizedBox(
                            height: 200,
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              use24hFormat: true,
                              initialDateTime: _selectedTime,
                              onDateTimeChanged: _onTimeChanged,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _markUnknown,
                            child: Text(_unknown ? t(context, 'onboarding.birthtime.unknown') : t(context, 'onboarding.birthtime.unknown')),
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