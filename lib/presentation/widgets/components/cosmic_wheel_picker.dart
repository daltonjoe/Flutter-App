import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum WheelTone {
  female,
  male,
  neutral,
  single,
  dating,
  engaged,
  married,
  divorced,
  separated,
  gold,
  purple,
  indigo,
}

class WheelOption {
  final String key, label;
  final WheelTone tone;
  const WheelOption(this.key, this.label, [this.tone = WheelTone.neutral]);
}

class _P {
  final Color bg, border, text, glow;
  final List<Color> grad;
  const _P(this.bg, this.border, this.text, this.glow, this.grad);
}

final _pal = <WheelTone, _P>{
  WheelTone.female: _P(
    AppColors.themeLove.withValues(alpha: 0.08),
    AppColors.themeLove.withValues(alpha: 0.30),
    AppColors.themeLove,
    AppColors.themeLove,
    [AppColors.themeLove, AppColors.gold],
  ),
  WheelTone.male: _P(
    AppColors.themeCareer.withValues(alpha: 0.08),
    AppColors.themeCareer.withValues(alpha: 0.30),
    AppColors.starlight,
    AppColors.themeCareer,
    [AppColors.themeCareer, AppColors.info],
  ),
  WheelTone.neutral: _P(
    AppColors.navyDeep,
    AppColors.info.withValues(alpha: 0.25),
    AppColors.mist,
    AppColors.info,
    [AppColors.info, AppColors.elementWater],
  ),
  WheelTone.gold: _P(
    AppColors.gold.withValues(alpha: 0.08),
    AppColors.gold.withValues(alpha: 0.30),
    AppColors.goldSoft,
    AppColors.gold,
    [AppColors.statusChallenging, AppColors.goldDeep],
  ),
  WheelTone.purple: _P(
    AppColors.themeIdentity.withValues(alpha: 0.08),
    AppColors.themeIdentity.withValues(alpha: 0.30),
    AppColors.themeIdentity,
    AppColors.themeIdentity,
    [AppColors.gold, AppColors.elementWater],
  ),
  WheelTone.indigo: _P(
    AppColors.elementWater.withValues(alpha: 0.08),
    AppColors.elementWater.withValues(alpha: 0.30),
    AppColors.mist,
    AppColors.elementWater,
    [AppColors.elementWater, AppColors.info],
  ),
};

class CosmicWheelPicker extends StatefulWidget {
  final List<WheelOption> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  const CosmicWheelPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<CosmicWheelPicker> createState() => _CosmicWheelPickerState();
}

class _CosmicWheelPickerState extends State<CosmicWheelPicker> {
  late FixedExtentScrollController _c;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    final idx = widget.options.indexWhere((o) => o.key == widget.selected);
    _i = idx < 0 ? 0 : idx;
    _c = FixedExtentScrollController(initialItem: _i);
    if (idx < 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSelected(widget.options[_i].key);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: _c,
      itemExtent: 72,
      diameterRatio: 2.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (i) {
        setState(() => _i = i);
        widget.onSelected(widget.options[i].key);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.options.length,
        builder: (context, i) {
          final o = widget.options[i];
          final p = _pal[o.tone]!;
          final sel = i == _i;
          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? null : p.bg,
                gradient: sel ? LinearGradient(colors: p.grad) : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? Colors.transparent : p.border),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: p.glow.withValues(alpha: 0.6),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                o.label,
                style: TextStyle(
                  fontSize: sel ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: sel ? AppColors.starlight : p.text,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
