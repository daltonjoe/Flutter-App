import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart'; // gerçek path'ini kontrol et

class _LangOption {
  final String code;
  final String name;
  final String nativeName;
  final Color color;
  const _LangOption(this.code, this.name, this.nativeName, this.color);
}

const List<_LangOption> _languages = [
  _LangOption('en', 'English', 'English', Color(0xFF3B82F6)),
  _LangOption('tr', 'Turkish', 'Türkçe', Color(0xFFE53935)),
  _LangOption('de', 'German', 'Deutsch', Color(0xFFF59E0B)),
  _LangOption('es', 'Spanish', 'Español', Color(0xFFFBC02D)),
  _LangOption('fr', 'French', 'Français', Color(0xFF3F51B5)),
  _LangOption('pt', 'Portuguese', 'Português', Color(0xFF2E7D32)),
  _LangOption('ar', 'Arabic', 'العربية', Color(0xFF009688)),
];

const Map<String, String> _continueLabels = {
  'en': 'Continue with English',
  'tr': 'Türkçe ile Devam Et',
  'de': 'Weiter mit Deutsch',
  'es': 'Continuar con Español',
  'fr': 'Continuer en Français',
  'pt': 'Continuar em Português',
  'ar': 'المتابعة بالعربية',
};

class OnboardingLanguagePage extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isLast;

  const OnboardingLanguagePage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
    this.isLast = false,
  });

  @override
  State<OnboardingLanguagePage> createState() => _OnboardingLanguagePageState();
}

class _OnboardingLanguagePageState extends State<OnboardingLanguagePage> {
  late FixedExtentScrollController _controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final code = widget.data.languageCode ?? 'en';
    _selectedIndex = _languages.indexWhere((l) => l.code == code);
    if (_selectedIndex < 0) _selectedIndex = 0;
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
    widget.data.languageCode = _languages[_selectedIndex].code;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LanguageProvider>(context, listen: false).setLocale(_languages[_selectedIndex].code);;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

void _onSelected(int index) {
    setState(() {
      _selectedIndex = index;
      widget.data.languageCode = _languages[index].code;
    });
    Provider.of<LanguageProvider>(context, listen: false).setLocale(_languages[index].code);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _languages[_selectedIndex];
    final continueLabel = _continueLabels[selected.code] ??
        'Continue with ${selected.nativeName}';

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
                  const SizedBox(height: 24),
                  const Text(
                    'Choose Your Language',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Align your natal cosmic frequency & daily celestial readings',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '⌃ SWIPE WHEEL',
                    style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: Colors.white38),
                  ),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: _controller,
                      itemExtent: 88,
                      diameterRatio: 2.2,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: _onSelected,
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _languages.length,
                        builder: (context, index) {
                          final lang = _languages[index];
                          final isSelected = index == _selectedIndex;
                          return Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white.withOpacity(isSelected ? 0.06 : 0.02),
                                border: Border.all(
                                  color: isSelected
                                      ? lang.color
                                      : lang.color.withOpacity(0.25),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: lang.color.withOpacity(0.5), blurRadius: 16, spreadRadius: 1)]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: lang.color.withOpacity(0.2),
                                    child: Text(
                                      lang.code.toUpperCase(),
                                      style: TextStyle(color: lang.color, fontWeight: FontWeight.w700, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              lang.nativeName,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                fontSize: isSelected ? 17 : 15,
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: lang.color,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Text('ACTIVE',
                                                    style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.w700)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(lang.name, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: lang.color,
                                        boxShadow: [BoxShadow(color: lang.color.withOpacity(0.7), blurRadius: 8)],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  CosmicCtaButton(label: continueLabel, onTap: widget.onNext),
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