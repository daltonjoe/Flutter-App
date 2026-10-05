import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../i18n/app_localizations.dart';
import '../providers/active_profile_provider.dart';
import '../providers/language_provider.dart';
import '../services/reference_names_service.dart';
import '../services/today_service.dart';
import '../widgets/feedback_vote.dart';
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
  DateTime _selected = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final Map<String, Map<String, dynamic>> _week = {};

  String _t(String k) => AppLocalizations.of(context)?.translate(k) ?? k;

  static String _dkey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DateTime> _weekDates() {
    final today = _stripTime(DateTime.now());
    return List.generate(7, (i) => today.add(Duration(days: i)));
  }

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
      _week.clear();
      _selected = _stripTime(DateTime.now());
      _load(pid, loc);
    }
  }

  Future<void> _loadWeekBackground(
    String pid,
    String loc,
    String expectedKey,
  ) async {
    final dates = _weekDates();
    for (var i = 1; i < dates.length; i++) {
      final d = dates[i];
      final k = _dkey(d);
      if (_week.containsKey(k)) continue;
      try {
        final r = await TodayService.fetch(
          profileId: pid,
          locale: loc,
          date: d,
          persist: false,
        );
        if (!mounted) return;
        if (_key != expectedKey) return;
 setState(() => _week[k] = r);
      } catch (e) {
        debugPrint('week fetch $k error: $e');
      }
    }
  }

  Future<void> _load(String pid, String loc) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final expectedKey = _key;
    try {
      final d = await TodayService.fetch(profileId: pid, locale: loc);
      if (!mounted) return;
      setState(() {
         _data = d;
        _cachedAt = null;
   
      });
      unawaited(_loadWeekBackground(pid, loc, expectedKey!));
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

  Map<String, dynamic>? _selectedData() {
    final today = _stripTime(DateTime.now());
    if (_selected == today) return _data;
    return _week[_dkey(_selected)];
  }

  Color _dotColorFor(Map<String, dynamic>? data) {
    if (data == null) return AppColors.textMuted;
    final cats = data['categories'] as List? ?? const [];
    double? maxP;
    String? maxLevel;
    for (final c in cats) {
      final m = c as Map;
      final pr = m['percentile'];
      final sc = m['score'];
      double v = 0;
      if (pr is num) {
        v = pr.toDouble();
        if (v > 1) v = v / 100;
      } else if (sc is num) {
        v = sc.toDouble();
      }
      if (maxP == null || v > maxP) {
        maxP = v;
        maxLevel = m['level']?.toString();
      }
    }
    return _valenceColor(maxLevel);
  }

  Widget _dayChip(DateTime d, {required String wd, required String mloc}) {
    final k = _dkey(d);
    final selected = _selected == d;
    final data = _stripTime(DateTime.now()) == d ? _data : _week[k];
    final dotColor = _dotColorFor(data);
    final today = _stripTime(DateTime.now()) == d;
    return InkWell(
      onTap: () {
        setState(() => _selected = d);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.violetPrimary : Colors.transparent,
            width: selected ? 2 : 1,
          ),
          color: selected
                   ? AppColors.violetPrimary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              wd,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: today
                    ? AppColors.violetPrimary
                    : (selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              d.day.toString(),
              style: TextStyle(
                fontSize: 17,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: today
                    ? AppColors.violetPrimary
                    : (selected
                          ? AppColors.textPrimary
                          : AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekStrip(String mloc) {
    final dates = _weekDates();
    final wds = MaterialLocalizations.of(context).narrowWeekdays;
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        itemCount: dates.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = dates[i];
          final idx = (d.weekday - 1) % 7;
          return _dayChip(d, wd: wds[idx], mloc: mloc);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ReferenceNamesService>();
    final pid = context.watch<ActiveProfileProvider>().activeProfileId;
    final loc = context.read<LanguageProvider>().locale.languageCode;
    final selectedData = _selectedData();
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
        child: _content(selectedData, loc),
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

  Widget _content(Map<String, dynamic>? d, String loc) {
    final isToday = _selected == _stripTime(DateTime.now());
    if (d == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [_weekStrip(loc)],
      );
    }
    final head = d['headline'] as Map?;
    final tag = head?['tag'] as Map?;
    final text = head?['text']?.toString();
    final cats = (d['categories'] as List?) ?? const [];
    final events = (d['events'] as List?) ?? const [];
    final rate = (d['rarity'] as Map?)?['event_rate_pct'];
    final known = (_data ?? d)['time_known'] != false;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _weekStrip(loc),
        const SizedBox(height: 8),
        if (isToday && _cachedAt != null) ...[
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
            if (_id(head['template_id']) != null &&
                context.read<ActiveProfileProvider>().activeProfileId !=
                    null)
              FeedbackVote(
                key: ValueKey(
                  '${context.read<ActiveProfileProvider>().activeProfileId}|'
                  '${_dkey(_selected)}|${_id(head['template_id'])}',
                ),
                profileId:
                    context.read<ActiveProfileProvider>().activeProfileId!,
                day: _dkey(_selected),
               templateId: _id(head['template_id'])!,
                // Snippet şu an yalnız EN+TR; diğer dillerde metin en'e düşüyor.
                locale: (loc == 'tr' || loc == 'en') ? loc : 'en',
              ),
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
              isToday
                ? _t('today.events')
                : AppLocalizations.of(context)!.translate(
                    'today.events_on',
                    args: {
                      'date':
                          '${_selected.day.toString().padLeft(2, '0')}.${_selected.month.toString().padLeft(2, '0')}',
                    },
                  ),
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
                    profileId: context
                        .read<ActiveProfileProvider>()
                        .activeProfileId,
                    day: _dkey(_selected),
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
        if (isToday && !known) ...[
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
  final color = avg > 0.7 ? AppColors.tealSuccess : AppColors.textMuted;
    final valenceKey = avg > 0.7 ? 'valence.power' : 'valence.neutral';
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
