import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import '../../services/astro_service.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../i18n/app_localizations.dart';

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

List<String> get _optionKeys => [
  'onboarding.relationship.single',
  'onboarding.relationship.in_relationship',
  'onboarding.relationship.married',
  'onboarding.relationship.complicated',
];

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
      setState(() => _generalError = e.message);
    } catch (_) {
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
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "What's your relationship status?",
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: descColor),
                          ),
                          const SizedBox(height: 24),
                          _optionKeys.map(
                            (optionKey) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => _select(option),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _selected == option
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).dividerColor,
                                      width: _selected == option ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    option,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_generalError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _generalError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CosmicCtaButton(label: 'Continue', onTap: _onSubmit),
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