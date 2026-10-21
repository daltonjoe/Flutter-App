import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/onboarding_data.dart';
import '../../presentation/widgets/components/cosmic_card.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../i18n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

class OnboardingGenderPage extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isLast;

  const OnboardingGenderPage({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
    this.isLast = false,
  });

  @override
  State<OnboardingGenderPage> createState() => _OnboardingGenderPageState();
}

class _OnboardingGenderPageState extends State<OnboardingGenderPage> {
  static const List<String> _options = ['female', 'male', 'prefer_not_to_say'];

  static const Map<String, String> _images = {
    'female': 'assets/images/onboarding/gender_female.png',
    'male': 'assets/images/onboarding/gender_male.png',
    'prefer_not_to_say': 'assets/images/onboarding/gender_neutral.png',
  };

  late final PageController _controller;
  String? _selected;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final fromData = widget.data.gender;
    _selected = _options.contains(fromData) ? fromData : _options.first;
    widget.data.gender = _selected;
    _index = _options.indexOf(_selected!);
    _controller = PageController(viewportFraction: 0.62, initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(String value) {
    setState(() {
      _selected = value;
      widget.data.gender = value;
    });
  }

  void _onPageChanged(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    _index = index;
    _select(_options[index]);
  }

  void _onCardTap(int index) {
    if (index == _index) return;
    _controller.animateToPage(
      index,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final descColor = Theme.of(context).textTheme.bodyMedium?.color;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final cardDuration = reduce
        ? Duration.zero
        : const Duration(milliseconds: 220);

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
                t(context, 'onboarding.gender.title'),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: descColor),
              ),
              const SizedBox(height: 8),
              Text(
                t(context, 'onboarding.gender.subtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd(color: AppColors.mist),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: _onPageChanged,
                  itemCount: _options.length,
                  itemBuilder: (context, i) {
                    final value = _options[i];
                    final isSelected = i == _index;
                    final label = t(context, 'onboarding.gender.$value');
                    return Semantics(
                      selected: isSelected,
                      button: true,
                      label: label,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.lg,
                        ),
                        child: AnimatedScale(
                          scale: isSelected ? 1.0 : 0.88,
                          duration: cardDuration,
                          curve: Curves.easeInOutCubic,
                          child: AnimatedOpacity(
                            opacity: isSelected ? 1.0 : 0.6,
                            duration: cardDuration,
                            curve: Curves.easeInOutCubic,
                            child: CosmicCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              borderColor: isSelected ? AppColors.gold : null,
                              onTap: () => _onCardTap(i),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      _images[value]!,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const SizedBox.shrink(),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMd(
                                      color: AppColors.starlight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _options.length; i++)
                    AnimatedContainer(
                      duration: cardDuration,
                      curve: Curves.easeInOutCubic,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      width: i == _index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.gold : AppColors.mist,
                        borderRadius: AppRadius.pillBr,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CosmicCtaButton(
                label: t(context, 'common.next'),
                onTap: () {
                  widget.data.gender ??= 'prefer_not_to_say';
                  widget.onNext();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
