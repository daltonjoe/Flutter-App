import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../models/city_model.dart';
import '../../presentation/widgets/components/cosmic_input_field.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_alert_dialog.dart';

class OnboardingCityPage extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isLast;

  const OnboardingCityPage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
    this.isLast = false,
  });

  @override
  State<OnboardingCityPage> createState() => _OnboardingCityPageState();
}

class _OnboardingCityPageState extends State<OnboardingCityPage> {
  late TextEditingController _controller;
  List<CityModel> _allCities = [];
  List<CityModel> _results = [];
  CityModel? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.data.city;
    _controller = TextEditingController(text: _selected?.display ?? '');
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await CityModel.loadAll();
    if (mounted) setState(() => _allCities = cities);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _selected = null;
    widget.data.city = null;
      if (value.trim().isEmpty) {
        _results = [];
      } else {
        _results = _allCities
            .where((c) => c.display.toLowerCase().contains(value.toLowerCase()))
            .take(6)
            .toList();
      }
    });
  }

  void _selectCity(CityModel city) {
    setState(() {
      _selected = city;
      _controller.text = city.display;
      _results = [];
      widget.data.city = city;
    });
  }

    Future<void> _onNext() async {
    if (_selected != null) {
      widget.onNext();
      return;
    }
    FocusScope.of(context).unfocus();
    await showCosmicAlert(
      context,
      message: t(context, 'onboarding.city.required'),
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
                            t(context, 'onboarding.city.title'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: descColor),
                          ),
                          const SizedBox(height: 24),
                          CosmicInputField(
                            label: t(context, 'create_profile.city_hint'),
                            icon: Icons.location_on_outlined,
                            controller: _controller,
                            hint: t(context, 'onboarding.city.hint'),
                            onChanged: _onSearch,
                          ),
                          if (_results.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              constraints: const BoxConstraints(maxHeight: 220),
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final city = _results[index];
                                  return ListTile(
                                    title: Text(city.display),
                                    onTap: () => _selectCity(city),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                CosmicCtaButton(
                  label: t(context, 'common.next'),
                  onTap: _onNext,
                ),
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