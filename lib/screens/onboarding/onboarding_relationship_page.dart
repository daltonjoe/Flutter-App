import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../services/astro_service.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_wheel_picker.dart';

class OnboardingRelationshipPage extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isLast;

  const OnboardingRelationshipPage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
    this.isLast = false,
  });

  @override
  State<OnboardingRelationshipPage> createState() =>
      _OnboardingRelationshipPageState();
}

class _OnboardingRelationshipPageState
    extends State<OnboardingRelationshipPage> {
  String? _selected;
  bool _isLoading = false;
  String? _generalError;

  static const List<String> _options = [
    'single', 'dating', 'engaged', 'married', 'divorced', 'separated'
  ];

  List<String> get _optionKeys =>
      _options.map((o) => 'onboarding.relationship.$o').toList();

  static const Map<String, WheelTone> _tones = {
    'single': WheelTone.neutral,
    'dating': WheelTone.female,
    'engaged': WheelTone.male,
    'married': WheelTone.gold,
    'divorced': WheelTone.purple,
    'separated': WheelTone.indigo,
  };

  String? get _imagePath => _selected != null
      ? 'assets/images/relationship/${_selected == 'separated' ? 'seperated' : _selected}.png'
      : null;

  @override
  void initState() {
    super.initState();
    _selected = widget.data.relationshipStatus;
  }

  void _select(String value) {
    setState(() {
      _selected = value;
      widget.data.relationshipStatus = value;
    });
  }

  Future<void> _onSubmit() async {
    setState(() => _generalError = null);

    final d = widget.data;
    debugPrint('date=${d.birthDate} time=${d.birthTime} city=${d.city}');
    if (d.birthDate == null || d.birthTime == null || d.city == null) {
      setState(() => _generalError = t(context, 'common.unknown_error'));
      return;
    }

    final date = DateFormat('yyyy-MM-dd').format(d.birthDate!);
    final time =
        '${d.birthTime!.hour.toString().padLeft(2, '0')}:${d.birthTime!.minute.toString().padLeft(2, '0')}';

    setState(() => _isLoading = true);

    try {
      final result = await AstroService.generateNatalChart(
        birthDate: date,
        birthTime: time,
        city: d.city!.display,
        latitude: d.city!.latitude,
        longitude: d.city!.longitude,
        timezone: d.city!.timezone,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        Navigator.pushNamed(
          context,
          '/chart',
          arguments: {'chartData': result, 'userName': d.name ?? ''},
        );
      } else {
        setState(() {
          _generalError = result.message ?? t(context, 'common.unknown_error');
        });
      }
    } on AstroServiceException catch (e) {
    if (!mounted) return;
    setState(() => _generalError = e.message);
    } catch (e) {
  debugPrint('Natal chart error: $e');
  if (!mounted) return;
  setState(() => _generalError = t(context, 'common.unknown_error'));
} finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    t(context, 'onboarding.relationship.title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: descColor),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: _imagePath != null
                        ? Image.asset(
                            _imagePath!,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          )
                        : null,
                  ),
                  Expanded(
                    child: CosmicWheelPicker(
                      options: List.generate(_options.length, (i) => WheelOption(
                          _options[i],
                          t(context, _optionKeys[i]),
                          _tones[_options[i]]!,
                      )),
                      selected: _selected,
                      onSelected: _select,
                    ),
                  ),
                  if (_generalError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _generalError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CosmicCtaButton(
                      label: t(context, 'common.next'), // diğer sayfalarda kullandığınız Next key'i neyse onu yazın
                      disabled: _selected == null,
                      onTap: widget.isLast ? _onSubmit : widget.onNext,
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