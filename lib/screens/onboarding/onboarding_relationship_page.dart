import '../../services/ai_consent_service.dart';
import '../../services/ask_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../models/onboarding_data.dart';
import '../../services/astro_service.dart';
import '../../services/chart_persistence_service.dart';
import '../../presentation/widgets/components/cosmic_card.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../i18n/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../../providers/active_profile_provider.dart';
import 'onboarding_chat_page.dart';

class OnboardingRelationshipPage extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isLast;
  final bool isFirstProfile;

  const OnboardingRelationshipPage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
    this.isLast = false,
    required this.isFirstProfile,
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
    'single',
    'in_relationship',
    'engaged',
    'married',
    'divorced',
    'separated',
    'prefer_not_to_say',
  ];

  static const Map<String, String> _images = {
    'single': 'assets/images/onboarding/rel_single.png',
    'in_relationship': 'assets/images/onboarding/rel_in_relationship.png',
    'engaged': 'assets/images/onboarding/rel_engaged.png',
    'married': 'assets/images/onboarding/rel_married.png',
    'divorced': 'assets/images/onboarding/rel_divorced.png',
    'separated': 'assets/images/onboarding/rel_separated.png',
    'prefer_not_to_say': 'assets/images/onboarding/rel_prefer_not_to_say.png',
  };

  @override
  void initState() {
    super.initState();
    final fromData = widget.data.relationshipStatus == 'dating'
        ? 'in_relationship'
        : widget.data.relationshipStatus;
    _selected = _options.contains(fromData) ? fromData : _options.first;
    widget.data.relationshipStatus = _selected;
  }

  void _select(String value) {
    if (_selected == value) return;
    HapticFeedback.selectionClick();
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

    final locale = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).locale.languageCode;
    final activeProfileProvider = context.read<ActiveProfileProvider>();

    final setupFactory = () => _generateAndSaveChart(
      d: d,
      date: date,
      time: time,
      locale: locale,
      activeProfileProvider: activeProfileProvider,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    // S10 çıkışı → S10c sohbeti. İlk profilde notlar boş değilse araya S10d
    // Notlarım tanıtımı girer; ardından hesaplama adımına geçilir.
    final navigator = Navigator.of(context);
    void openCalculating() {
      navigator.pushReplacementNamed(
        '/onboarding/calculating',
        arguments: {
          'setupFactory': setupFactory,
          'isFirstProfile': widget.isFirstProfile,
        },
      );
    }

    if (!widget.isFirstProfile) {
      openCalculating();
      return;
    }

    final relStatus = widget.data.relationshipStatus;
    final String? relNote =
        (relStatus == null || relStatus == 'prefer_not_to_say')
            ? null
            : t(
                context,
                'onboarding.relationship.note',
                args: {
                  'status': t(context, 'onboarding.relationship.$relStatus'),
                },
              );
    List<String> notes = const [];
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingChatPage(
          onNotes: (n) => notes = n,
          onDone: () {
            final all = <String>[if (relNote != null) relNote, ...notes];
            if (all.isNotEmpty) _saveNotes(all).ignore();
            openCalculating();
          },
        ),
      ),
    );
  }

  /// Y5: onboarding notlari Notlarim a yazilir; hata sessiz, limit asilirsa durur.
  Future<void> _saveNotes(List<String> notes) async {
    await AiConsentService.grantAi();
    for (final n in notes) {
      try {
        await AskService.memoryAdd(n);
      } catch (e) {
        debugPrint('onboarding note save failed: $e');
        if (AskService.memoryErrKey(e) == 'notes.limit') break;
      }
    }
  }

  Future<void> _generateAndSaveChart({
    required OnboardingData d,
    required String date,
    required String time,
    required String locale,
    required ActiveProfileProvider activeProfileProvider,
  }) async {
    final result = await AstroService.generateNatalChart(
      birthDate: date,
      birthTime: time,
      city: d.city!.display,
      latitude: d.city!.latitude,
      longitude: d.city!.longitude,
      timezone: d.city!.timezone,
    );

    if (!result.isSuccess) {
      throw Exception(result.message ?? 'unknown_error');
    }

    final profileId = await ChartPersistenceService.saveChart(
      data: d,
      chart: result,
      locale: locale,
    );
    await activeProfileProvider.setActive(profileId);
  }

  @override
  Widget build(BuildContext context) {
    final descColor = Theme.of(context).textTheme.bodyMedium?.color;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final imageHeight = (MediaQuery.sizeOf(context).height * 0.24)
        .clamp(130.0, 220.0)
        .toDouble();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
              ),
              Text(
                t(context, 'onboarding.relationship.title'),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: descColor),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  child: _selected == null
                      ? const SizedBox.shrink()
                      : Image.asset(
                          _images[_selected]!,
                          key: ValueKey(_selected),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final value = _options[i];
                    final isSelected = value == _selected;
                    final label = t(context, 'onboarding.relationship.$value');
                    return Semantics(
                      selected: isSelected,
                      button: true,
                      label: label,
                      child: CosmicCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        borderColor: isSelected ? AppColors.gold : null,
                        onTap: () => _select(value),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMd(
                                    color: AppColors.starlight,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: AppSpacing.sm),
                                const Icon(
                                  Icons.check,
                                  size: 20,
                                  color: AppColors.gold,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_generalError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _generalError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.statusDanger),
                  ),
                ),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : CosmicCtaButton(
                      label: t(context, 'common.next'),
                      disabled: _selected == null,
                      onTap: widget.isLast ? _onSubmit : widget.onNext,
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
