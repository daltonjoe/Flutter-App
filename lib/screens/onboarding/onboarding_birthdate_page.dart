import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../utils/zodiac_utils.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../presentation/widgets/components/cosmic_outline_button.dart';
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
              // Zodiac icon + name — sabit unicode sembol, isim localized
              Center(
                child: Column(
                  children: [
                    Image.asset(_sign.assetPath, width: 64, height: 64),
                    Text(
                    t(context, 'signs.${_sign.name}').toUpperCase(),
                    style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(t(context, 'onboarding.birthdate.subtitle')),
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
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: CosmicOutlineButton(label: 'Skip!', onTap: widget.onNext),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CosmicCtaButton(label: 'Next', onTap: widget.onNext),
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