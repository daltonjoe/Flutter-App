// Gezegen glyph şeridi (Faz 3): yatay seçim şeridi.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../models/natal_chart_response.dart';
import '../../presentation/widgets/components/planet_glyph_icon.dart';
import '../../services/reference_names_service.dart';
import '../data/planet_card_view_model.dart';

/// Gezegen glyph'lerinden oluşan yatay seçim şeridi.
///
/// Seçili öğe altın çerçeve/dolgu ile vurgulanır ve şeritte görünür tutulur.
class PlanetGlyphStrip extends StatefulWidget {
  const PlanetGlyphStrip({
    super.key,
    required this.chartData,
    required this.selected,
  });

  final NatalChartResponse chartData;

  final ValueNotifier<int> selected;

  @override
  State<PlanetGlyphStrip> createState() => _PlanetGlyphStripState();
}

class _PlanetGlyphStripState extends State<PlanetGlyphStrip> {
  static const double _dotSize = 36.0;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.selected.addListener(_keepSelectedVisible);
  }

  @override
  void didUpdateWidget(covariant PlanetGlyphStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      oldWidget.selected.removeListener(_keepSelectedVisible);
      widget.selected.addListener(_keepSelectedVisible);
    }
  }

  @override
  void dispose() {
    widget.selected.removeListener(_keepSelectedVisible);
    _scroll.dispose();
    super.dispose();
  }

  /// Seçili öğeyi şeridin ortasına getirir (dış sayfayı kaydırmaz).
  void _keepSelectedVisible() {
    if (!mounted || !_scroll.hasClients) return;
    final i = widget.selected.value;
    final viewport = _scroll.position.viewportDimension;
    final itemStart = AppSpacing.screenH + i * (_dotSize + AppSpacing.sm);
    final target = (itemStart - (viewport - _dotSize) / 2).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = context.watch<ReferenceNamesService>();
    final items = PlanetCardViewModel.fromChart(widget.chartData, names);
    if (items.isEmpty) return const SizedBox.shrink();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return ValueListenableBuilder<int>(
      valueListenable: widget.selected,
      builder: (context, active, _) {
        return SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.screenH,
          ),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                _GlyphDot(
                  item: items[i],
                  selected: i == active,
                  reduceMotion: reduceMotion,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.selected.value = i;
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Şeritteki tek gezegen glyph dairesi.
class _GlyphDot extends StatelessWidget {
  const _GlyphDot({
    required this.item,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
  });

  final PlanetCardViewModel item;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? AppColors.navyRaised : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.hairline,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: PlanetGlyphIcon(
              name: item.key.toLowerCase(),
              size: 20,
              color: selected ? AppColors.gold : AppColors.mist,
              decorative: true,
            ),
          ),
        ),
      ),
    );
  }
}
