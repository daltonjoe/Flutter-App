import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../providers/active_profile_provider.dart';
import '../providers/language_provider.dart';
import '../services/checkin_service.dart';
import '../services/reference_names_service.dart';
import '../services/user_settings_service.dart';
import '../services/today_service.dart';
import '../widgets/feedback_vote.dart';
import 'edit_birth_time_page.dart';
import 'transit_detail_page.dart';
import '../models/ask_context.dart';
import '../providers/ask_context_provider.dart';
import '../widgets/ask_add.dart';

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
  static const String _kRitualDismissed = 'today_ritual_dismissed';
  bool _ritualDismissed = false;
  bool _notificationsFlagEnabled = false;
  UserSettings? _ritualSettings;
  bool _ritualLoading = true;
  bool _streakFlagEnabled = false;
  bool _streakFlagLoading = true;
  final Map<String, int> _checkinsByDay = {};
  int? _checkinLoadSerial;
  bool _checkinSaving = false;
  bool _checkinChangeMode = false;

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
  void initState() {
    super.initState();
    unawaited(_loadRitualState());
    unawaited(_loadStreakFlag());
  }

  Future<void> _loadStreakFlag() async {
    try {
      final v = await UserSettingsService.isFlagEnabled('streak');
      if (!mounted) return;
      setState(() {
        _streakFlagEnabled = v;
        _streakFlagLoading = false;
      });
    } catch (e) {
      debugPrint('streak flag init failed: $e');
      if (mounted) {
        setState(() {
          _streakFlagEnabled = false;
          _streakFlagLoading = false;
        });
      }
    }
  }

  Future<void> _loadCheckins(String pid, int serial) async {
    try {
      final list = await CheckinService.loadRecent(pid, days: 60);
      if (!mounted) return;
      if (serial != _checkinLoadSerial) return;
      final map = <String, int>{};
      for (final c in list) {
        map[c.day] = c.mood;
      }
      setState(() {
        _checkinsByDay
          ..clear()
          ..addAll(map);
      });
    } catch (e) {
      debugPrint('checkins load failed: $e');
    }
  }

  Future<void> _saveMood(String pid, String day, int mood) async {
    if (_checkinSaving) return;
    final prev = _checkinsByDay[day];
    HapticFeedback.selectionClick();
    setState(() {
      _checkinSaving = true;
      _checkinsByDay[day] = mood;
      _checkinChangeMode = false;
    });
    try {
      await CheckinService.setMood(profileId: pid, day: day, mood: mood);
    } catch (e) {
      debugPrint('checkins save failed: $e');
      if (!mounted) return;
      setState(() {
        if (prev == null) {
          _checkinsByDay.remove(day);
        } else {
          _checkinsByDay[day] = prev;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(context, 'streak.error.save'))));
    } finally {
      if (mounted) setState(() => _checkinSaving = false);
    }
  }

  Future<void> _loadRitualState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_kRitualDismissed) ?? false;
      final flag = await UserSettingsService.isFlagEnabled(
        'settings_notifications',
      );
      UserSettings? settings;
      if (flag && !dismissed) {
        settings = await UserSettingsService.load();
      }
      if (!mounted) return;
      setState(() {
        _ritualDismissed = dismissed;
        _notificationsFlagEnabled = flag;
        _ritualSettings = settings;
        _ritualLoading = false;
      });
    } catch (e) {
      debugPrint('ritual init failed: $e');
      if (mounted) setState(() => _ritualLoading = false);
    }
  }

  Future<void> _dismissRitual() async {
    HapticFeedback.selectionClick();
    setState(() => _ritualDismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRitualDismissed, true);
    } catch (e) {
      debugPrint('ritual dismiss persist failed: $e');
    }
  }

  Future<void> _pickRitualTime() async {
    final initialParts = (_ritualSettings?.notificationTime ?? '09:00').split(
      ':',
    );
    final initial = TimeOfDay(
      hour: int.tryParse(initialParts[0]) ?? 9,
      minute: int.tryParse(initialParts[1]) ?? 0,
    );
    TimeOfDay? picked = initial;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 180,
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: DateTime(
                        2000,
                        1,
                        1,
                        initial.hour,
                        initial.minute,
                      ),
                      backgroundColor: AppColors.bgCard,
                      onDateTimeChanged: (dt) {
                        picked = TimeOfDay(hour: dt.hour, minute: dt.minute);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.ctaHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.violetPrimary,
                      borderRadius: AppRadius.mdBr,
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        t(context, 'settings.save'),
                        style: AppTextStyles.ctaPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || picked == null || !mounted) return;
    HapticFeedback.selectionClick();
    final hh = picked!.hour.toString().padLeft(2, '0');
    final mm = picked!.minute.toString().padLeft(2, '0');
    final newTime = '$hh:$mm';
    final prevSettings = _ritualSettings;
    setState(() {
      _ritualSettings =
          (prevSettings ??
                  UserSettings(
                    notificationsEnabled: true,
                    notificationTime: null,
                  ))
              .copyWith(notificationTime: newTime);
    });
    try {
      await UserSettingsService.save(notificationTime: newTime);
    } catch (e) {
      debugPrint('ritual save notificationTime failed: $e');
      if (!mounted) return;
      setState(() {
        _ritualSettings = prevSettings;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, 'settings.error.save'))),
      );
    }
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
      _checkinsByDay.clear();
      _checkinChangeMode = false;
      final serial = (_checkinLoadSerial ?? 0) + 1;
      _checkinLoadSerial = serial;
      unawaited(_loadCheckins(pid, serial));
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

  void _addEvent(Map e) {
    final pid = context.read<ActiveProfileProvider>().activeProfileId;
    if (pid == null) return;
    addToAsk(
      context,
      AskContext.todayEvent(
        profileId: pid,
        day: _dkey(_selected),
        event: e,
        label: _label(
          _id(e['transit_body_id']),
          _id(e['aspect_type_id']),
          _id(e['natal_body_id']),
        ),
      ),
    );
  }

    void _addHeadline(Map head) {
    final pid = context.read<ActiveProfileProvider>().activeProfileId;
    if (pid == null) return;
    final tag = head['tag'] as Map?;
    addToAsk(
      context,
      AskContext.todayHeadline(
        profileId: pid,
        day: _dkey(_selected),
        tag: tag,
        label: _label(
          _id(tag?['transit']),
          _id(tag?['aspect']),
          _id(tag?['natal']),
        ),
      ),
    );
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
          final idx = d.weekday % 7;
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
        _RitualCard(
          loading: _ritualLoading,
          visible: !_ritualDismissed && _notificationsFlagEnabled,
          settings: _ritualSettings,
          headline: (isToday && head != null)
              ? Map<String, dynamic>.from(head)
              : null,
          locale: loc,
          onDismiss: _dismissRitual,
          onPickTime: _pickRitualTime,
        ),
        if (!_ritualDismissed && _notificationsFlagEnabled && !_ritualLoading)
          const SizedBox(height: 12),
        _CheckinCard(
          flagEnabled: _streakFlagEnabled,
          flagLoading: _streakFlagLoading,
          isToday: isToday,
          profileId: context.watch<ActiveProfileProvider>().activeProfileId,
          checkinsByDay: _checkinsByDay,
          saving: _checkinSaving,
          changeMode: _checkinChangeMode,
          onToggleChangeMode: () {
            setState(() => _checkinChangeMode = !_checkinChangeMode);
          },
          onPickMood: (m) {
            final pid = context.read<ActiveProfileProvider>().activeProfileId;
            if (pid == null) return;
            final day = CheckinService.dayKey(DateTime.now());
            unawaited(_saveMood(pid, day, m));
          },
          onOpenStreak: () {
            final pid = context.read<ActiveProfileProvider>().activeProfileId;
            if (pid == null) return;
            Navigator.of(context).pushNamed('/streak', arguments: pid);
          },
        ),
        if (isToday &&
            _streakFlagEnabled &&
            !_streakFlagLoading &&
            context.watch<ActiveProfileProvider>().activeProfileId != null)
          const SizedBox(height: 12),
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
            if (context.read<ActiveProfileProvider>().activeProfileId != null)
            Align(
              alignment: Alignment.centerLeft,
              child: AskAddButton(onPressed: () => _addHeadline(head)),
            ),
          if (text != null && text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(text),
            if (_id(head['template_id']) != null &&
                context.read<ActiveProfileProvider>().activeProfileId != null)
              FeedbackVote(
                key: ValueKey(
                  '${context.read<ActiveProfileProvider>().activeProfileId}|'
                  '${_dkey(_selected)}|${_id(head['template_id'])}',
                ),
                profileId: context
                    .read<ActiveProfileProvider>()
                    .activeProfileId!,
                day: _dkey(_selected),
                templateId: _id(head['template_id'])!,
                // K15 geçici: snippet yalnız EN+TR; diğer dillerde metin en'e düşüyor,
                // oy gösterilen metnin diliyle kaydedilir. Transcreation sonrası `loc`.
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
             trailing: ValueListenableBuilder<bool>(
                valueListenable: askEnabled,
                builder: (ctx, on, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (on)
                      IconButton(
                        tooltip: t(ctx, 'ask.add'),
                        icon: const Icon(Icons.auto_awesome_outlined,
                            size: 18, color: AppColors.violetPrimary),
                        onPressed: () => _addEvent(e),
                      ),
                    if (e['applying'] is bool)
                      Icon(
                        (e['applying'] as bool)
                            ? Icons.north_east
                            : Icons.south_east,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
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

class _CheckinCard extends StatelessWidget {
  final bool flagEnabled;
  final bool flagLoading;
  final bool isToday;
  final String? profileId;
  final Map<String, int> checkinsByDay;
  final bool saving;
  final bool changeMode;
  final VoidCallback onToggleChangeMode;
  final void Function(int mood) onPickMood;
  final VoidCallback onOpenStreak;

  const _CheckinCard({
    required this.flagEnabled,
    required this.flagLoading,
    required this.isToday,
    required this.profileId,
    required this.checkinsByDay,
    required this.saving,
    required this.changeMode,
    required this.onToggleChangeMode,
    required this.onPickMood,
    required this.onOpenStreak,
  });

  static const List<IconData> _icons = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];

  static const Map<int, Color> _moodColors = {
    1: AppColors.roseAccent,
    2: AppColors.amberTransit,
    3: AppColors.textMuted,
    4: AppColors.tealSuccess,
    5: AppColors.goldAccent,
  };

  @override
  Widget build(BuildContext context) {
    if (flagLoading || !flagEnabled || !isToday || profileId == null) {
      return const SizedBox.shrink();
    }
    final todayKey = CheckinService.dayKey(DateTime.now());
    final todayMood = checkinsByDay[todayKey];
    final checkedIn = todayMood != null;
    final showPicker = !checkedIn || changeMode;
    if (showPicker) {
      return _pickerCard(context, todayMood);
    }
    final streak = CheckinService.currentStreak(
      checkinsByDay.keys.toSet(),
      DateTime.now(),
    );
    final color = _moodColors[todayMood] ?? AppColors.textMuted;
    return Container(
      key: const ValueKey('checkin-checked'),
      decoration: AppDecorations.cosmicCard(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            child: Center(
               child: Icon(_icons[todayMood - 1], size: 28, color: color),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        t(context, 'streak.checked_in'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h3(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Flexible(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppRadius.mdBr,
                          onTap: onOpenStreak,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                              horizontal: AppSpacing.xs,
                            ),
                            child: Text(
                              t(
                                context,
                                'streak.days',
                                args: {'n': streak.toString()},
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMd(
                                color: streak > 0
                                    ? AppColors.violetPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            height: AppSizes.ctaHeight,
            child: TextButton(
              onPressed: saving ? null : onToggleChangeMode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      t(context, 'streak.change'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.ctaSecondary(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerCard(BuildContext context, int? selected) {
    return Container(
      key: const ValueKey('checkin-picker'),
      decoration: AppDecorations.cosmicCard(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  t(context, 'streak.checkin.title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h2(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Flexible(
                child: Text(
                  t(context, 'streak.checkin.body'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(5, (i) {
              final mood = i + 1;
              final isSel = selected == mood;
              final color = _moodColors[mood]!;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 4 ? 0 : AppSpacing.xs),
                  child: SizedBox(
                    height: AppSpacing.xxl,
                    child: Material(
                      color: Colors.transparent,
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isSel
                              ? color.withValues(alpha: 0.18)
                              : AppColors.bgSurface,
                          borderRadius: AppRadius.mdBr,
                          border: Border.all(
                            color: isSel ? color : AppColors.borderSubtle,
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: AppRadius.mdBr,
             onTap: saving ? null : () => onPickMood(mood),
                          child: Center(
                            child: Icon(
                              _icons[i],
                              semanticLabel: t(context, 'streak.mood.$mood'),
                              size: 24,
                              color: isSel ? color : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  final bool loading;
  final bool visible;
  final UserSettings? settings;
  final Map<String, dynamic>? headline;
  final String locale;
  final Future<void> Function() onDismiss;
  final Future<void> Function() onPickTime;

  const _RitualCard({
    required this.loading,
    required this.visible,
    required this.settings,
    required this.headline,
    required this.locale,
    required this.onDismiss,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return _card(context);
  }

  Widget _card(BuildContext context) {
    final hasTime = settings?.notificationTime != null;
    String? previewText;
    if (locale == 'en' || locale == 'tr') {
      final Map<String, dynamic>? hl = headline;
      if (hl != null) {
        final Object? n = hl['notification'];
        if (n is String && n.trim().isNotEmpty) {
          previewText = n;
        }
      }
    }
    final bool showPreview =
        previewText != null && previewText.trim().isNotEmpty;

    return Container(
      decoration: AppDecorations.cosmicCard(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t(context, 'today.ritual.title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h2(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t(context, 'today.ritual.body'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: AppSpacing.xxl,
                height: AppSpacing.xxl,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.textMuted,
                  onPressed: loading ? null : onDismiss,
                  tooltip: t(context, 'today.ritual.dismiss'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSizes.ctaHeight,
                  child: loading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : DecoratedBox(
                          decoration: hasTime
                              ? AppDecorations.secondaryCta()
                              : AppDecorations.primaryCta(),
                          child: TextButton(
                            onPressed: onPickTime,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    hasTime
                                        ? '${settings!.notificationTime!}  •  ${t(context, 'today.ritual.change_time')}'
                                        : t(context, 'today.ritual.set_time'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: hasTime
                                        ? AppTextStyles.ctaSecondary()
                                        : AppTextStyles.ctaPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (showPreview) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppRadius.mdBr,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(context, 'today.ritual.preview_label'),
                    style: AppTextStyles.fieldLabel(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          previewText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
