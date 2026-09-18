import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../utils/zodiac_utils.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../models/zodiac_sign.dart';
import '../../i18n/app_localizations.dart';

class OnboardingBirthdatePage extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isLast;

  const OnboardingBirthdatePage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
    this.isLast = false,
  });

  @override
  State<OnboardingBirthdatePage> createState() => _OnboardingBirthdatePageState();
}

class _OnboardingBirthdatePageState extends State<OnboardingBirthdatePage> {
  late DateTime _selectedDate;
  late ZodiacSign _sign;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.data.birthDate ?? DateTime(2000, 1, 1);
    _sign = ZodiacSign.fromString(ZodiacUtils.getSignKey(_selectedDate));
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _sign = ZodiacSign.fromString(ZodiacUtils.getSignKey(date));
      widget.data.birthDate = date;
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
                          const SizedBox(height: 28),
                          Image.asset(_sign.assetPath, width: 200, height: 200),
                          Text(
                            t(context, 'signs.${_sign.name}').toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                              color: descColor,
                            ),
                          ),
                         
                          Text(
                            t(context, 'onboarding.birthdate.subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: descColor),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                              initialDateTime: _selectedDate,
                              maximumDate: DateTime.now(),
                              minimumDate: DateTime(1900),
                              onDateTimeChanged: _onDateChanged,
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