// Ev anlamı paneli (Faz 6). Metin yer tutucu servisten gelir.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../models/natal_chart_response.dart';
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
        final key = '${item.key}-$houseNumber';
        final String? body;
        if (houseNumber == null) {
          body = t(context, 'planet_report.time_unknown');
        } else if (_textKey == key) {
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

        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.screenH,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bgCard.withValues(alpha: 0.8),
              borderRadius: AppRadius.lgBr,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: AlignmentDirectional.topStart,
                children: [...previousChildren, ?currentChild],
              ),
              child: Column(
                key: ValueKey('$key-${body == null ? 'l' : 'r'}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t(context, 'rd.house.meaning_title'),
                    style: AppTextStyles.h3(),
                  ),
                  if (body != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(body, style: AppTextStyles.bodyMd()),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
