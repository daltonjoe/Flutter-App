// Ev anlamı paneli (Faz 6). Metin yer tutucu servisten gelir.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../models/natal_chart_response.dart';
import '../../presentation/widgets/components/cosmic_card.dart';
import '../../providers/language_provider.dart';
import '../../services/reference_names_service.dart';
import '../data/house_meaning_service.dart';
import '../data/planet_card_view_model.dart';

class HouseMeaningPanel extends StatefulWidget {
  const HouseMeaningPanel({
    super.key,
    required this.chartData,
    required this.selected,
  });

  final NatalChartResponse chartData;

  final ValueListenable<int> selected;

  @override
  State<HouseMeaningPanel> createState() => _HouseMeaningPanelState();
}

class _HouseMeaningPanelState extends State<HouseMeaningPanel> {
  int _token = 0;
  String? _text;
  String? _textKey;
  String? _loc;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    widget.selected.addListener(_onSelected);
  }

  @override
  void didUpdateWidget(covariant HouseMeaningPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      oldWidget.selected.removeListener(_onSelected);
      widget.selected.addListener(_onSelected);
      _request();
    }
  }

  @override
  void dispose() {
    widget.selected.removeListener(_onSelected);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = context.watch<LanguageProvider>().locale.languageCode;
    context.watch<ReferenceNamesService>();
    if (_loc != loc) {
      _loc = loc;
      _request();
    }
  }

  void _onSelected() => _request();

  PlanetCardViewModel? _current(ReferenceNamesService names) {
    final items = PlanetCardViewModel.fromChart(widget.chartData, names);
    if (items.isEmpty) return null;
    final index = widget.selected.value.clamp(0, items.length - 1);
    return items[index];
  }

  Future<void> _request() async {
    final item = _current(context.read<ReferenceNamesService>());
    final houseNumber = item?.houseNumber;
    if (item == null || houseNumber == null) return;
    final key = '${item.key}-$houseNumber';
    final myToken = ++_token;
    final r = await HouseMeaningService.fetch(
      house: houseNumber,
      locale: _loc ?? 'en',
    );
    if (!mounted || myToken != _token) return;
    setState(() {
      _text = r;
      _textKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.selected,
      builder: (context, _, _) {
        final item = _current(context.watch<ReferenceNamesService>());
        if (item == null) return const SizedBox.shrink();

        final houseNumber = item.houseNumber;
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        final rotateDuration = reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 200);
        final sizeDuration = reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 250);
        final switchDuration = reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 350);

        const padding = EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.screenH,
        );

        // Doğum saati yoksa: açılmayan tek satır bilgi.
        if (houseNumber == null) {
          return Padding(
            padding: padding,
            child: CosmicCard(
              blur: false,
              compact: true,
              radius: AppRadius.md,
              child: Text(
                t(context, 'planet_report.time_unknown'),
                style: AppTextStyles.bodyMd(color: AppColors.mist),
              ),
            ),
          );
        }

        final key = '${item.key}-$houseNumber';
        final String? body;
        if (_textKey == key) {
          body =
              _text ??
              t(
                context,
                'rd.house.meaning_placeholder',
                args: {
                  'planet': item.name,
                  'house': '${item.houseName} ${t(context, 'chart.house')}',
                },
              );
        } else {
          body = null;
        }

        final title = t(
          context,
          'rd.house.what_is',
          args: {'number': '$houseNumber'},
        );

        return Padding(
          padding: padding,
          child: Semantics(
            button: true,
            expanded: _open,
            label: title,
            child: CosmicCard(
              blur: false,
              compact: true,
              radius: AppRadius.md,
              onTap: () => setState(() => _open = !_open),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.bodyMd(
                            color: AppColors.starlight,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0.0,
                        duration: rotateDuration,
                        curve: Curves.easeOutCubic,
                        child: const Icon(
                          Icons.expand_more_rounded,
                          size: 20,
                          color: AppColors.mist,
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: sizeDuration,
                    curve: Curves.easeOutCubic,
                    alignment: AlignmentDirectional.topStart,
                    child: _open
                        ? Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: AppSpacing.sm,
                            ),
                            child: AnimatedSwitcher(
                              duration: switchDuration,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                              child: SizedBox(
                                key: ValueKey(
                                  '$key-${body == null ? 'l' : 'r'}',
                                ),
                                width: double.infinity,
                                child: body == null
                                    ? const SizedBox.shrink()
                                    : Text(body, style: AppTextStyles.bodyMd()),
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
