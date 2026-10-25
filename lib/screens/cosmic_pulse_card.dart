import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../presentation/widgets/components/cosmic_card.dart';
import '../presentation/widgets/components/overline_text.dart';
import '../providers/language_provider.dart';
import '../services/cosmic_service.dart';
import '../services/reference_names_service.dart';

/// Cosmic Pulse: collective sky text (4 blocks) or, when text is null,
/// a short list built from the layer data.
class CosmicPulseCard extends StatefulWidget {
  const CosmicPulseCard({super.key});

  @override
  State<CosmicPulseCard> createState() => _CosmicPulseCardState();
}

class _CosmicPulseCardState extends State<CosmicPulseCard> {
  Map<String, dynamic>? _data;
  DateTime? _fetched;
  String? _loc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = context.watch<LanguageProvider>().locale.languageCode;
    if (loc != _loc) {
      _loc = loc;
      _data = null;
      _load(loc);
    }
  }

  Future<void> _load(String loc) async {
    Map<String, dynamic>? d;
    DateTime? at;
    try {
      d = await CosmicService.fetch(loc);
      at = DateTime.now();
    } catch (e) {
      debugPrint('cosmic fetch: $e');
      final c = await CosmicService.cached(loc);
      if (c != null) {
        d = c['data'] as Map<String, dynamic>;
        at = c['saved_at'] as DateTime;
      }
    }
    if (!mounted || _loc != loc) return;
    setState(() {
      _data = d;
      _fetched = at;
    });
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static int _i(dynamic v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

  DateTime? _when(Map d) {
    final a = d['at'];
    DateTime? t;
    if (a is String) {
      t = DateTime.tryParse(a);
    } else if (a is num) {
      t = DateTime.fromMillisecondsSinceEpoch((a < 100000000000 ? a * 1000 : a).toInt());
    }
    return (t ?? _fetched)?.toLocal();
  }

  List<String> _fallback(Map d, ReferenceNamesService n) {
    String asp(dynamic x) {
      final m = x as Map;
      return '${n.planet(_i(m['a']))} ${n.aspect(_i(m['aspect']))} ${n.planet(_i(m['b']))}';
    }

    final l1 = (d['layer1'] as Map?) ?? const {};
    final l2 = (d['layer2'] as Map?) ?? const {};
    final l3 = (d['layer3'] as Map?) ?? const {};
    final out = <String>[];
    for (final x in (l1['aspects'] as List?) ?? const []) {
      out.add(asp(x));
    }
    if (l2['moon_sign'] != null) {
      out.add('${n.planet(2)} - ${n.sign(_i(l2['moon_sign']) + 1)}');
    }
    for (final x in (l2['conjunctions'] as List?) ?? const []) {
      out.add(asp(x));
    }
    for (final x in (l3['aspects'] as List?) ?? const []) {
      out.add(asp(x));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (d == null) return const SizedBox.shrink();
    final names = context.watch<ReferenceNamesService>();
    String tr(String k) => AppLocalizations.of(context)?.translate(k) ?? k;
    final when = _when(d);
    final now = tr('cosmic.now');
    final stamp =
        when == null ? now : '$now ${_two(when.hour)}:${_two(when.minute)}';
    final text = d['text'];
    final blocks = text is String
        ? text
            .split(RegExp(r'\n\s*\n'))
            .map((b) => b.trim())
            .where((b) => b.isNotEmpty)
            .toList()
        : <String>[];
    final lines = blocks.isEmpty ? _fallback(d, names) : <String>[];

    return CosmicCard(
      blur: true,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: OverlineText(tr('cosmic.title'))),
              Text(stamp, style: AppTextStyles.bodyXs(color: AppColors.mist)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (blocks.isNotEmpty) ...[
            Text(
              blocks.first,
              style: AppTextStyles.h1(color: AppColors.starlight)
                  .copyWith(fontSize: 20, height: 26 / 20),
            ),
            for (final b in blocks.skip(1)) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(b, style: AppTextStyles.bodyMd(color: AppColors.starlight)),
            ],
          ] else if (lines.isNotEmpty) ...[
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(l, style: AppTextStyles.bodyMd(color: AppColors.starlight)),
              ),
          ] else
            Text(tr('cosmic.quiet'), style: AppTextStyles.bodyMd(color: AppColors.mist)),
        ],
      ),
    );
  }
}
