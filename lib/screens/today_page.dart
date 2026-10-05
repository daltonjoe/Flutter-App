import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../i18n/app_localizations.dart';
import '../providers/active_profile_provider.dart';
import '../providers/language_provider.dart';
import '../services/reference_names_service.dart';
import '../services/today_service.dart';
import 'edit_birth_time_page.dart';
import 'transit_detail_page.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});
  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = false;
  String? _key;
  DateTime? _cachedAt;

  String _t(String k) => AppLocalizations.of(context)?.translate(k) ?? k;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<ActiveProfileProvider>();
    final pid = provider.activeProfileId;
    final loc = context.watch<LanguageProvider>().locale.languageCode;
    final key = '$pid|$loc|${provider.revision}';
    if (pid != null && key != _key) {
      _key = key;
      _data = null;
      _cachedAt = null;
      _load(pid, loc);
    }
  }

  Future<void> _load(String pid, String loc) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await TodayService.fetch(profileId: pid, locale: loc);
      if (!mounted) return;
      setState(() {
        _data = d;
        _cachedAt = null;
      });
    } catch (e) {
      final c = _data == null ? await TodayService.cached(pid, loc) : null;
      if (!mounted) return;
      setState(() {
        if (c != null) {
          _data = c['data'] as Map<String, dynamic>;
          _cachedAt = c['saved_at'] as DateTime;
        } else if (_data != null) {
          _cachedAt ??= DateTime.now();
        } else {
          _error = e.toString();
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  int? _id(dynamic v) => v is num ? v.toInt() : null;

  Color _valenceColor(String? v) {
    switch (v) {
      case 'power':
        return AppColors.tealSuccess;
      case 'pressure':
        return AppColors.amberTransit;
      case 'trouble':
        return AppColors.roseAccent;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _valenceIcon(String? v) {
    switch (v) {
      case 'power':
        return Icons.trending_up;
      case 'pressure':
        return Icons.compress;
      case 'trouble':
        return Icons.warning_amber_rounded;
      default:
        return Icons.remove;
    }
  }

  String _label(int? tb, int? asp, int? nb) {
    final n = ReferenceNamesService.instance;
    return '${tb == null ? '?' : n.planet(tb)} · ${asp == null ? '?' : n.aspect(asp)} · ${nb == null ? '?' : n.planet(nb)}';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ReferenceNamesService>();
    final pid = context.watch<ActiveProfileProvider>().activeProfileId;
    final loc = context.read<LanguageProvider>().locale.languageCode;
    Widget body;
    if (_loading && _data == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _data == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_t('today.error')),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: pid == null ? null : () => _load(pid, loc),
              child: Text(_t('today.retry')),
            ),
          ],
        ),
      );
    } else if (_data == null) {
      body = Center(child: Text(_t('today.empty')));
    } else {
      body = RefreshIndicator(
        onRefresh: () => pid == null ? Future.value() : _load(pid, loc),
        child: _content(_data!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('today.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: pid == null || _loading ? null : () => _load(pid, loc),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _content(Map<String, dynamic> d) {
    final head = d['headline'] as Map?;
    final tag = head?['tag'] as Map?;
    final text = head?['text']?.toString();
    final cats = (d['categories'] as List?) ?? const [];
    final events = (d['events'] as List?) ?? const [];
    final rate = (d['rarity'] as Map?)?['event_rate_pct'];
    final known = d['time_known'] != false;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (_cachedAt != null) ...[
          Text(
            AppLocalizations.of(
              context,
            )!.translate('today.offline', args: {'time': _fmt(_cachedAt!)}),
            style: const TextStyle(color: AppColors.amberTransit, fontSize: 12),
          ),
          const SizedBox(height: 12),
        ],
        if (head != null) ...[
          Text(
            _label(
              _id(tag?['transit']),
              _id(tag?['aspect']),
              _id(tag?['natal']),
            ),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (text != null && text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(text),
          ],
          if (rate is num) ...[
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.translate(
                'today.rarity',
                args: {'pct': rate.toStringAsFixed(1)},
              ),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
        ],
        _ring(cats),
        for (final c in cats) _catRow(c as Map),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            _t('today.events'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final e in events.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                _label(
                  _id((e as Map)['transit_body_id']),
                  _id(e['aspect_type_id']),
                  _id(e['natal_body_id']),
                ),
              ),
              subtitle: e['orb'] is num
                  ? Text(
                      '${(e['orb'] as num).toStringAsFixed(1)}°',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    )
                  : null,
              trailing: e['applying'] is bool
                  ? Icon(
                      (e['applying'] as bool)
                          ? Icons.north_east
                          : Icons.south_east,
                      size: 16,
                      color: AppColors.textSecondary,
                    )
                  : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TransitDetailPage(
                    event: Map<String, dynamic>.from(e),
                    locale: context
                        .read<LanguageProvider>()
                        .locale
                        .languageCode,
                    title: _label(
                      _id(e['transit_body_id']),
                      _id(e['aspect_type_id']),
                      _id(e['natal_body_id']),
                    ),
                  ),
                ),
              ),
            ),
        ],
        if (!known) ...[
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final pid = context
                    .read<ActiveProfileProvider>()
                    .activeProfileId;
                if (pid == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditBirthTimePage(profileId: pid),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _t('today.unknown_time_hint'),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _ring(List cats) {
    final ps = <double>[];
    for (final c in cats) {
      final pr = (c as Map)['percentile'];
      if (pr is num) {
        final v = pr.toDouble();
        ps.add(v > 1 ? v / 100 : v);
      }
    }
    if (ps.isEmpty) return const SizedBox.shrink();
    final avg = ps.reduce((a, b) => a + b) / ps.length;
    final color = avg > 0.7
        ? AppColors.tealSuccess
        : (avg < 0.3 ? AppColors.amberTransit : AppColors.textMuted);
    final valenceKey = avg > 0.7
        ? 'valence.power'
        : (avg < 0.3 ? 'valence.pressure' : 'valence.neutral');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EnergyRing(value: avg, color: color),
            const SizedBox(height: 6),
            Text(_t(valenceKey), style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  static const _themes = {1: 'love', 2: 'career', 3: 'identity', 4: 'health'};

  Widget _catRow(Map c) {
    final lvl = c['level']?.toString();
    final tid = _id(c['theme_id']);
    final score = c['score'] is num ? (c['score'] as num).toDouble() : 0.0;
    final pr = c['percentile'] is num
        ? (c['percentile'] as num).toDouble()
        : null;
    final p = pr == null ? score : (pr > 1 ? pr / 100 : pr);
    final color = _valenceColor(lvl);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(_t('theme.${_themes[tid] ?? tid}'))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p.clamp(0.04, 1.0),
                color: color,
                backgroundColor: Colors.white12,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(_valenceIcon(lvl), size: 16, color: color),
          const SizedBox(width: 4),
          SizedBox(
            width: 56,
            child: Text(
              _t('valence.${lvl ?? 'neutral'}'),
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyRing extends StatelessWidget {
  final double value;
  final Color color;
  const _EnergyRing({required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              color: Colors.white12,
            ),
          ),
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: value.clamp(0.04, 1.0),
              strokeWidth: 8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
