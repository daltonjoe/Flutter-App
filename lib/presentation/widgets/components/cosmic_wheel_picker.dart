import 'package:flutter/material.dart';

enum WheelTone {
  female, male, neutral,
  single, dating, engaged, married, divorced, separated,
  gold, purple, indigo,
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

const _pal = {
  WheelTone.female: _P(Color(0x14FF4D94), Color(0x4DFF65A8), Color(0xFFFDE2EE),
      Color(0xFFFF4D94), [Color(0xFFFF65A8), Color(0xFFA855F7)]),
  WheelTone.male: _P(Color(0x1455E6FC), Color(0x4D3FA6F8), Color(0xFFE0F2FE),
      Color(0xFF38BDF8), [Color(0xFF38BDF8), Color(0xFF4F46E5)]),
  WheelTone.neutral: _P(Color(0xFF1A1030), Color(0x408B5CF6), Color(0xFFC4B5FD),
      Color(0xFF8B5CF6), [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
  WheelTone.gold: _P(Color(0x14F59E0B), Color(0x4DF59E0B), Color(0xFFFDE68A),
      Color(0xFFF59E0B), [Color(0xFFF59E0B), Color(0xFFEA580C)]),
  WheelTone.purple: _P(Color(0x149333EA), Color(0x4DC026D3), Color(0xFFE879F9),
      Color(0xFF9333EA), [Color(0xFF9333EA), Color(0xFF4F46E5)]),
  WheelTone.indigo: _P(Color(0x146366F1), Color(0x4D6366F1), Color(0xFFC7D2FE),
      Color(0xFF6366F1), [Color(0xFF4338CA), Color(0xFF0EA5E9)]),
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
                    ? [BoxShadow(color: p.glow.withOpacity(0.6), blurRadius: 16)]
                    : null,
              ),
              child: Text(
                o.label,
                style: TextStyle(
                  fontSize: sel ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : p.text.withOpacity(1.0),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}