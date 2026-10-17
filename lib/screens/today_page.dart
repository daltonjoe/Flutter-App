import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/astro_glyphs.dart';

import '../core/theme/app_colors.dart';

import '../core/theme/app_dimensions.dart';

import '../core/theme/app_shadows.dart';

import '../core/theme/app_typography.dart';

import '../core/reference_ids.dart';

import '../i18n/app_localizations.dart';

import '../providers/active_profile_provider.dart';

import '../providers/language_provider.dart';

import '../services/checkin_service.dart';

import '../services/reference_names_service.dart';

import '../services/user_settings_service.dart';

import '../services/today_service.dart';

import '../widgets/feedback_vote.dart';

import 'edit_birth_data_page.dart';

import 'transit_detail_page.dart';

import '../models/ask_context.dart';

import '../providers/ask_context_provider.dart';

import '../widgets/ask_add.dart';

import '../presentation/widgets/components/cosmic_loader.dart';

import '../presentation/widgets/components/cosmic_background.dart';

import '../presentation/widgets/components/cosmic_card.dart';

import '../presentation/widgets/components/cosmic_chip.dart';

import '../presentation/widgets/components/glyph.dart';
import '../presentation/widgets/components/planet_glyph_icon.dart';

import '../presentation/widgets/components/overline_text.dart';

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

  /// Bildirim saatini kaydeder; başarılıysa true döner.

  Future<bool> _saveRitualTime(String newTime) async {
    if (!mounted) return false;

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

      return true;
    } catch (e) {
      debugPrint('ritual save notificationTime failed: $e');

      if (!mounted) return false;

      setState(() {
        _ritualSettings = prevSettings;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, 'settings.error.save'))),
      );

      return false;
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

      // Alt navigasyon çubuğunun üstünde açılsın: yerel navigator'da açılınca

      // saat tekerleği ve kaydet butonu çubuğun altında kalıyordu.
      useRootNavigator: true,

      backgroundColor: AppColors.navyDeep,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),

      builder: (ctx) {
        // Sheet kök navigator'da açıldığı için alt sistem insetini kendimiz

        // uygularız (SafeArea bottom: false ile çift boşluk önlenir).

        final bottomInset = MediaQuery.viewPaddingOf(ctx).bottom;

        return SafeArea(
          bottom: false,

          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,

              AppSpacing.sm,

              AppSpacing.md,

              AppSpacing.md + bottomInset,
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
                          color: AppColors.starlight,

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

                      backgroundColor: AppColors.navyDeep,

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
                      color: AppColors.gold,

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

    await _saveRitualTime('$hh:$mm');
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
        return AppColors.statusSupportive;

      case 'pressure':
        return AppColors.statusChallenging;

      case 'trouble':
        return AppColors.statusChallenging;

      default:
        return AppColors.statusNeutral;
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

  /// Gezegen ref id -> glyph anahtarı (RefIds.planets ters haritası).

  static final Map<int, String> _planetGlyphKey = {
    for (final e in RefIds.planets.entries) e.value: e.key.toLowerCase(),
  };

  /// Açı ref id -> glyph anahtarı (RefIds.aspectByAngle sırasıyla).

  static const Map<int, String> _aspectGlyphKey = {
    1: 'conjunction',

    2: 'sextile',

    3: 'square',

    4: 'trine',

    5: 'opposition',
  };

  /// `head['text']` metnini ilk cümle sonuna (`.` `!` `?` + boşluk) göre

  /// böler. Tek cümleyse hero tüm metni alır, commentary boş döner.

  static (String, String) _splitHeadline(String text) {
    final t = text.trim();

    if (t.isEmpty) return ('', '');

    final match = RegExp(r'[.!?]\s').firstMatch(t);

    if (match == null) return (t, '');

    final cut = match.start + 1;

    return (t.substring(0, cut).trim(), t.substring(cut).trim());
  }

  /// HERO + yorum kartı + oy/Ask satırı.

  Widget _headlineSection(Map head, Map? tag, String loc) {
    final split = _splitHeadline(head['text']?.toString() ?? '');

    final heroText = split.$1;

    final commentary = split.$2;

    final pid = context.read<ActiveProfileProvider>().activeProfileId;

    final templateId = _id(head['template_id']);

    final actions = Row(
      children: [
        if (templateId != null && pid != null)
          Expanded(
            child: FeedbackVote(
              key: ValueKey('$pid|${_dkey(_selected)}|$templateId'),

              profileId: pid,

              day: _dkey(_selected),

              templateId: templateId,

              locale: (loc == 'tr' || loc == 'en') ? loc : 'en',
            ),
          )
        else
          const Spacer(),

        if (pid != null) AskAddButton(onPressed: () => _addHeadline(head)),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _headlineHero(heroText, tag),

        if (commentary.isNotEmpty)
          CosmicCard(
            blur: true,

            padding: const EdgeInsets.all(AppSpacing.cardPadding),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  commentary,

                  style: AppTextStyles.bodyMd(
                    color: AppColors.starlight,
                  ).copyWith(fontSize: 15, height: 24 / 15),
                ),

                const SizedBox(height: AppSpacing.md),

                actions,
              ],
            ),
          )
        else ...[
          const SizedBox(height: AppSpacing.md),

          actions,
        ],
      ],
    );
  }

  /// Overline + hero cümlesi + glyph üçlüsü; arkada tek soft gold glow ve

  /// giriş animasyonu (fade + 12px yukarı).

  Widget _headlineHero(String heroText, Map? tag) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        OverlineText(_t('today.hero_overline')),

        const SizedBox(height: AppSpacing.sm),

        Text(
          heroText,

          textAlign: TextAlign.start,

          style: AppTextStyles.h1(
            color: AppColors.starlight,
          ).copyWith(fontSize: 30, height: 38 / 30),
        ),

        const SizedBox(height: AppSpacing.md),

        _heroGlyphRow(tag),
      ],
    );

    final content = MediaQuery.disableAnimationsOf(context)
        ? body
        : TweenAnimationBuilder<double>(
            key: ValueKey('${_dkey(_selected)}|$heroText'),

            tween: Tween<double>(begin: 0, end: 1),

            duration: const Duration(milliseconds: 500),

            curve: Curves.easeOutExpo,

            builder: (_, v, child) => Opacity(
              opacity: v.clamp(0.0, 1.0).toDouble(),

              child: Transform.translate(
                offset: Offset(0, 12 * (1 - v)),

                child: child,
              ),
            ),

            child: body,
          );

    return Stack(
      clipBehavior: Clip.none,

      children: [
        Positioned(
          left: -AppSpacing.md,

          right: -AppSpacing.md,

          top: -AppSpacing.sm,

          bottom: -AppSpacing.sm,

          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),

                    boxShadow: AppShadows.glow(
                      AppColors.gold,

                      blur: 32,

                      alpha: 0.25,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        content,
      ],
    );
  }

  /// Transit gezegen · açı · natal gezegen glyph üçlüsü + etiket.

  Widget _heroGlyphRow(Map? tag) {
    final tb = _id(tag?['transit']);

    final asp = _id(tag?['aspect']);

    final nb = _id(tag?['natal']);

    final transitKey = tb == null ? null : _planetGlyphKey[tb];

    final aspectKey = asp == null ? null : _aspectGlyphKey[asp];

    final natalKey = nb == null ? null : _planetGlyphKey[nb];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        if (transitKey != null) ...[
          PlanetGlyphIcon(
            name: transitKey,
            size: 28,
            color: AppColors.gold,
            decorative: true,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (aspectKey != null) ...[
          Glyph(
            aspectKey,
            size: 28,
            color: AstroGlyphs.aspectColorFor(aspectKey) ?? AppColors.gold,
            decorative: true,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (natalKey != null) ...[
          PlanetGlyphIcon(
            name: natalKey,
            size: 28,
            color: AppColors.gold,
            decorative: true,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],

        Flexible(
          child: Text(
            _label(tb, asp, nb),

            style: AppTextStyles.bodySm(color: AppColors.mist),
          ),
        ),
      ],
    );
  }

  /// Etkinlik satırı: dikey gold çizgi + nokta, etiket ve Ask ekle.

  Widget _eventRow(Map e, {required bool isLast}) {
    final tb = _id(e['transit_body_id']);

    final asp = _id(e['aspect_type_id']);

    final nb = _id(e['natal_body_id']);

    final label = _label(tb, asp, nb);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          SizedBox(
            width: 12,

            child: Column(
              children: [
                const SizedBox(height: 6),

                Container(
                  width: 8,

                  height: 8,

                  decoration: const BoxDecoration(
                    color: AppColors.gold,

                    shape: BoxShape.circle,
                  ),
                ),

                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,

                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();

                Navigator.of(context).push(
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

                      title: label,
                    ),
                  ),
                );
              },

              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),

                      child: Text(
                        label,

                        style: AppTextStyles.bodyMd(color: AppColors.starlight),
                      ),
                    ),
                  ),

                  ValueListenableBuilder<bool>(
                    valueListenable: askEnabled,

                    builder: (ctx, on, _) => on
                        ? IconButton(
                            tooltip: t(ctx, 'ask.add'),

                            icon: const Icon(
                              Icons.auto_awesome_outlined,

                              size: 18,

                              color: AppColors.gold,
                            ),

                            onPressed: () => _addEvent(e),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _selectedData() {
    final today = _stripTime(DateTime.now());

    if (_selected == today) return _data;

    return _week[_dkey(_selected)];
  }

  Color _dotColorFor(Map<String, dynamic>? data) {
    if (data == null) return AppColors.statusNeutral;

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

  Widget _dayChip(DateTime d, {required String wd}) {
    final k = _dkey(d);

    final selected = _selected == d;

    final data = _stripTime(DateTime.now()) == d ? _data : _week[k];

    final dotColor = _dotColorFor(data);

    final today = _stripTime(DateTime.now()) == d;

    final nameColor = (selected || today) ? AppColors.gold : AppColors.mist;

    final numberColor = (selected || today)
        ? AppColors.gold
        : AppColors.starlight;

    return SizedBox(
      width: 44,

      height: 64,

      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();

          setState(() => _selected = d);
        },

        borderRadius: AppRadius.mdBr,

        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdBr,

            border: Border.all(
              color: selected ? AppColors.gold : Colors.transparent,

              width: 1,
            ),

            color: selected
                ? AppColors.gold.withValues(alpha: 0.16)
                : Colors.transparent,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Text(
                wd,

                maxLines: 1,

                style: AppTextStyles.overline(
                  color: nameColor,
                ).copyWith(fontSize: 11),
              ),

              const SizedBox(height: 2),

              Text(
                d.day.toString(),

                style: AppTextStyles.bodyLg(
                  color: numberColor,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
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
      ),
    );
  }

  Widget _weekStrip(String mloc) {
    final dates = _weekDates();

    return SizedBox(
      height: 72,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),

        itemCount: dates.length,

        separatorBuilder: (_, i) => const SizedBox(width: 8),

        itemBuilder: (_, i) {
          final d = dates[i];

          return _dayChip(d, wd: DateFormat('EEE', mloc).format(d));
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
      body = const CosmicLoader();
    } else if (_error != null && _data == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Text(_t('today.error')),

            const SizedBox(height: 8),

            Text(
              _error!,

              style: AppTextStyles.bodyXs(color: AppColors.mist),

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

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          backgroundColor: Colors.transparent,

          toolbarHeight: 72,

          centerTitle: false,

          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            mainAxisSize: MainAxisSize.min,

            children: [
              Text(_t('today.title'), style: AppTextStyles.h1()),

              const SizedBox(height: 2),

              Text(
                DateFormat('d MMMM, EEEE', loc).format(_selected),

                style: AppTextStyles.bodySm(color: AppColors.mist),
              ),
            ],
          ),

          actions: [
            if (_streakFlagEnabled && !_streakFlagLoading && pid != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.screenH - 8),

                child: Semantics(
                  button: true,

                  label: _t('streak.checkin.title'),

                  child: SizedBox(
                    width: 40,

                    height: 40,

                    child: InkWell(
                      borderRadius: AppRadius.pillBr,

                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed('/streak', arguments: pid),

                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome,

                          size: 16,

                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        body: SafeArea(bottom: false, child: body),
      ),
    );
  }

  Widget _content(Map<String, dynamic>? d, String loc) {
    final isToday = _selected == _stripTime(DateTime.now());

    if (d == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenH,

          AppSpacing.md,

          AppSpacing.screenH,

          AppSizes.scrollBottomPadding(context),
        ),

        children: [_weekStrip(loc)],
      );
    }

    final head = d['headline'] as Map?;

    final tag = head?['tag'] as Map?;

    final cats = (d['categories'] as List?) ?? const [];

    final events = (d['events'] as List?) ?? const [];

    final rate = (d['rarity'] as Map?)?['event_rate_pct'];

    final known = (_data ?? d)['time_known'] != false;

    // Headline ile aynı olan etkinliği listeden çıkar; kalan ilk 3.

    final shownEvents = <Map>[];

    for (final e in events) {
      final m = e as Map;

      if (tag != null &&
          _id(m['transit_body_id']) == _id(tag['transit']) &&
          _id(m['aspect_type_id']) == _id(tag['aspect']) &&
          _id(m['natal_body_id']) == _id(tag['natal'])) {
        continue;
      }

      shownEvents.add(m);

      if (shownEvents.length >= 3) break;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH,

        AppSpacing.md,

        AppSpacing.screenH,

        AppSizes.scrollBottomPadding(context),
      ),

      children: [
        _weekStrip(loc),

        const SizedBox(height: 8),

        if (isToday && _cachedAt != null) ...[
          Text(
            AppLocalizations.of(
              context,
            )!.translate('today.offline', args: {'time': _fmt(_cachedAt!)}),

            style: AppTextStyles.bodyXs(color: AppColors.statusChallenging),
          ),

          const SizedBox(height: 12),
        ],

        if (head != null) ...[
          _headlineSection(head, tag, loc),

          const SizedBox(height: 20),
        ],

        if (rate is num) ...[
          Row(
            children: [
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.translate(
                    'today.rarity',

                    args: {'pct': rate.toStringAsFixed(1)},
                  ),

                  style: AppTextStyles.bodyXs(color: AppColors.mist),
                ),
              ),

              if (rate < 5) ...[
                const SizedBox(width: AppSpacing.sm),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,

                    vertical: AppSpacing.xs,
                  ),

                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.16),

                    borderRadius: AppRadius.pillBr,

                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),

                  child: Text(
                    _t('today.rare_day'),

                    style: AppTextStyles.overline(color: AppColors.gold),
                  ),
                ),
              ],
            ],
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

          onSetTime: _saveRitualTime,
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

        _ring(cats),

        _catGrid(cats),

        if (shownEvents.isNotEmpty) ...[
          const SizedBox(height: 20),

          OverlineText(
            isToday
                ? _t('today.events')
                : AppLocalizations.of(context)!.translate(
                    'today.events_on',

                    args: {
                      'date':
                          '${_selected.day.toString().padLeft(2, '0')}.${_selected.month.toString().padLeft(2, '0')}',
                    },
                  ),
          ),

          const SizedBox(height: 8),

          for (var i = 0; i < shownEvents.length; i++)
            _eventRow(shownEvents[i], isLast: i == shownEvents.length - 1),
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
                    builder: (_) => EditBirthDataPage(profileId: pid),
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

                        style: AppTextStyles.bodyXs(color: AppColors.mist),
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right,

                      size: 16,

                      color: AppColors.mist,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        Center(
          child: Text(
            _t('ask.disclaimer'),

            textAlign: TextAlign.center,

            style: AppTextStyles.bodyXs(color: AppColors.mist),
          ),
        ),
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

    final wordKey = avg > 0.7 ? 'valence.power' : 'today.energy.balanced';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('${_dkey(_selected)}|${(avg * 100).round()}'),

              tween: Tween<double>(begin: 0, end: avg),

              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 900),

              curve: Curves.easeOutCubic,

              builder: (context, v, _) {
                final pct = (v * 100).round();

                return Semantics(
                  label: '$pct, ${_t(wordKey)}',

                  child: Stack(
                    alignment: Alignment.center,

                    children: [
                      _EnergyRing(value: v),

                      Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Text(
                            '$pct',

                            style: AppTextStyles.h1(color: AppColors.starlight)
                                .copyWith(
                                  fontSize: 40,

                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),

                          const SizedBox(height: AppSpacing.xs),

                          Text(
                            _t(wordKey),

                            style: AppTextStyles.bodySm(color: AppColors.mist),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  static const _themes = {1: 'love', 2: 'career', 3: 'identity', 4: 'health'};

  /// Kategori teması -> glyph anahtarı.

  static const Map<String, String> _themeGlyph = {
    'love': 'venus',

    'career': 'saturn',

    'identity': 'sun',

    'health': 'mars',
  };

  /// Kategorileri 2x2 kart ızgarası olarak çizer. Hepsi nötrse tek "sakin gün"

  /// metni döner; veri yokken hiçbir şey çizilmez.

  Widget _catGrid(List cats) {
    if (cats.isEmpty) return const SizedBox.shrink();

    final allNeutral = cats.every((c) {
      final lvl = (c as Map)['level']?.toString();

      return lvl == null || lvl == 'neutral';
    });

    if (allNeutral) {
      return Center(
        child: Text(
          _t('today.calm_day'),

          textAlign: TextAlign.center,

          style: AppTextStyles.bodyMd(color: AppColors.mist),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, cons) {
        final w = (cons.maxWidth - AppSpacing.cardGap) / 2;

        return Wrap(
          spacing: AppSpacing.cardGap,

          runSpacing: AppSpacing.cardGap,

          children: [
            for (final c in cats) SizedBox(width: w, child: _catCard(c as Map)),
          ],
        );
      },
    );
  }

  Widget _catCard(Map c) {
    final lvl = c['level']?.toString();

    final tid = _id(c['theme_id']);

    final themeKey = _themes[tid] ?? '$tid';

    final glyphName = _themeGlyph[themeKey];

    final score = c['score'] is num ? (c['score'] as num).toDouble() : 0.0;

    final pr = c['percentile'] is num
        ? (c['percentile'] as num).toDouble()
        : null;

    final p = pr == null ? score : (pr > 1 ? pr / 100 : pr);

    final color = _valenceColor(lvl);

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppColors.navyDeep.withValues(alpha: 0.65),

        borderRadius: AppRadius.mdBr,

        border: Border.all(color: AppColors.hairline),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              if (glyphName != null &&
                  AstroGlyphs.glyphFor(glyphName) != null) ...[
                PlanetGlyphIcon(
                  name: glyphName,
                  size: 20,
                  color: color,
                  decorative: true,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],

              Expanded(
                child: Text(
                  _t('theme.$themeKey'),

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: AppTextStyles.bodyMd(color: AppColors.starlight),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _BiBar(value: p, level: lvl),

          const SizedBox(height: 6),

          Text(
            _t('valence.${lvl ?? 'neutral'}'),

            style: AppTextStyles.bodyXs(color: color),
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

  /// Seçenek dairesinin tasarım boyutu (AppSizes'ta karşılığı yok).

  static const double _moodCircle = 56.0;

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

    return CosmicCard(
      key: const ValueKey('checkin-checked'),

      blur: false,

      padding: const EdgeInsets.all(AppSpacing.md),

      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,

        spacing: AppSpacing.sm,

        runSpacing: AppSpacing.xs,

        children: [
          Icon(_icons[todayMood - 1], size: 28, color: AppColors.gold),

          Text(
            t(
              context,

              'streak.today_mood',

              args: {'mood': t(context, 'streak.mood.$todayMood')},
            ),

            style: AppTextStyles.bodyMd(color: AppColors.starlight),
          ),

          Material(
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
                  t(context, 'streak.days', args: {'n': streak.toString()}),

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: AppTextStyles.bodySm(
                    color: streak > 0 ? AppColors.gold : AppColors.mist,
                  ),
                ),
              ),
            ),
          ),

          TextButton(
            onPressed: saving ? null : onToggleChangeMode,

            child: Text(
              t(context, 'streak.change'),

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: AppTextStyles.ctaSecondary(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerCard(BuildContext context, int? selected) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);

    return CosmicCard(
      key: const ValueKey('checkin-picker'),

      blur: false,

      padding: const EdgeInsets.all(AppSpacing.cardPadding),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            t(context, 'streak.checkin.title'),

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: AppTextStyles.h2(),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            t(context, 'streak.checkin.body'),

            maxLines: 2,

            overflow: TextOverflow.ellipsis,

            style: AppTextStyles.bodySm(),
          ),

          const SizedBox(height: AppSpacing.md),

          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.sm;

              // Dar ekranlarda beş daire sığsın: 56'yı aşmayacak şekilde küçült.

              final circle = math.min(
                _moodCircle,

                (constraints.maxWidth - gap * 4) / 5,
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: List.generate(5, (i) {
                  final mood = i + 1;

                  final isSel = selected == mood;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 4 ? 0 : gap),

                      child: Semantics(
                        button: true,

                        selected: isSel,

                        label: t(context, 'streak.mood.$mood'),

                        child: AnimatedOpacity(
                          duration: duration,

                          opacity: changeMode && !isSel ? 0.5 : 1.0,

                          child: AnimatedScale(
                            duration: duration,

                            curve: Curves.easeOut,

                            scale: isSel ? 1.08 : 1.0,

                            child: Column(
                              children: [
                                Material(
                                  color: Colors.transparent,

                                  child: Ink(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,

                                      color: isSel
                                          ? AppColors.gold.withValues(
                                              alpha: 0.16,
                                            )
                                          : AppColors.navyRaised,

                                      border: Border.all(
                                        color: isSel
                                            ? AppColors.gold
                                            : AppColors.hairline,

                                        width: isSel ? 1.5 : 1.0,
                                      ),
                                    ),

                                    child: InkWell(
                                      customBorder: const CircleBorder(),

                                      onTap: saving
                                          ? null
                                          : () => onPickMood(mood),

                                      child: SizedBox(
                                        width: circle,

                                        height: circle,

                                        child: Icon(
                                          _icons[i],

                                          size: 28,

                                          color: isSel
                                              ? AppColors.gold
                                              : AppColors.mist,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: AppSpacing.xs),

                                Text(
                                  t(context, 'streak.mood.$mood'),

                                  maxLines: 1,

                                  overflow: TextOverflow.ellipsis,

                                  textAlign: TextAlign.center,

                                  style: AppTextStyles.bodyXs(
                                    color: isSel
                                        ? AppColors.starlight
                                        : AppColors.mist,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
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

  final Future<bool> Function(String) onSetTime;

  const _RitualCard({
    required this.loading,

    required this.visible,

    required this.settings,

    required this.headline,

    required this.locale,

    required this.onDismiss,

    required this.onPickTime,

    required this.onSetTime,
  });

  /// Hazır saat önerileri (HH:mm).

  static const List<String> _quickTimes = ['07:30', '08:30', '12:00'];

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return _card(context);
  }

  Future<void> _applyTime(BuildContext context, String time) async {
    final ok = await onSetTime(time);

    if (ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(context, 'today.ritual.saved'))));
    }
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

    return CosmicCard(
      blur: false,

      padding: const EdgeInsets.all(AppSpacing.cardPadding),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(child: hasTime ? _timeLine(context) : _header(context)),

              SizedBox(
                width: AppSpacing.xxl,

                height: AppSpacing.xxl,

                child: IconButton(
                  padding: EdgeInsets.zero,

                  icon: const Icon(Icons.close, size: 20),

                  color: AppColors.mist,

                  onPressed: loading ? null : onDismiss,

                  tooltip: t(context, 'today.ritual.dismiss'),
                ),
              ),
            ],
          ),

          if (!hasTime) ...[
            const SizedBox(height: AppSpacing.md),

            if (loading)
              const Center(
                child: SizedBox(
                  width: 20,

                  height: 20,

                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,

                runSpacing: AppSpacing.sm,

                children: [
                  for (final time in _quickTimes)
                    CosmicChip(
                      label: time,

                      onTap: () => _applyTime(context, time),
                    ),

                  CosmicChip(
                    label: t(context, 'today.ritual.set_time'),

                    onTap: onPickTime,
                  ),
                ],
              ),
          ],

          if (showPreview) ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(AppSpacing.sm),

              decoration: BoxDecoration(
                color: AppColors.navyRaised,

                borderRadius: AppRadius.mdBr,

                border: Border.all(color: AppColors.hairline),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    t(context, 'today.ritual.preview_label'),

                    style: AppTextStyles.fieldLabel(),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    previewText,

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: AppTextStyles.bodyMd(color: AppColors.starlight),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          t(context, 'today.ritual.title'),

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

          style: AppTextStyles.h2(),
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          t(context, 'today.ritual.body'),

          maxLines: 2,

          overflow: TextOverflow.ellipsis,

          style: AppTextStyles.bodySm(),
        ),
      ],
    );
  }

  Widget _timeLine(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.schedule, size: 16, color: AppColors.gold),

        const SizedBox(width: AppSpacing.xs),

        Flexible(
          child: Text(
            settings!.notificationTime!,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: AppTextStyles.bodyMd(color: AppColors.starlight),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        TextButton(
          onPressed: loading ? null : onPickTime,

          child: Text(
            t(context, 'today.ritual.change_time'),

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: AppTextStyles.ctaSecondary(),
          ),
        ),
      ],
    );
  }
}

/// Enerji halkası: iz + destekleyici→altın gradyanlı yay.

class _EnergyRing extends StatelessWidget {
  final double value;

  const _EnergyRing({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,

      height: 160,

      child: CustomPaint(painter: _RingPainter(value)),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t);

  final double t;

  static const double _stroke = 10;

  static const SweepGradient _gradient = SweepGradient(
    colors: [AppColors.statusSupportive, AppColors.gold],

    startAngle: -math.pi / 2,

    endAngle: math.pi * 3 / 2,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = (size.shortestSide - _stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.hairline;

    canvas.drawCircle(center, radius, track);

    if (t <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..shader = _gradient.createShader(Offset.zero & size);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),

      -math.pi / 2,

      2 * math.pi * t.clamp(0.0, 1.0),

      false,

      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

/// İki yönlü gösterge: güç sağa, baskı/sıkıntı sola dolar.

class _BiBar extends StatelessWidget {
  final double value;

  final String? level;

  const _BiBar({required this.value, required this.level});

  @override
  Widget build(BuildContext context) {
    final double direction;

    final Color color;

    switch (level) {
      case 'power':
        direction = 1;

        color = AppColors.statusSupportive;

        break;

      case 'pressure':
      case 'trouble':
        direction = -1;

        color = AppColors.statusChallenging;

        break;

      default:
        direction = 0;

        color = AppColors.statusNeutral;
    }

    final noAnim = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      height: 6,

      child: LayoutBuilder(
        builder: (context, cons) {
          final target = direction == 0
              ? 0.0
              : cons.maxWidth / 2 * value.clamp(0.04, 1.0);

          return Stack(
            children: [
              Container(
                width: double.infinity,

                height: 6,

                decoration: BoxDecoration(
                  color: AppColors.hairline,

                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              if (direction != 0)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: target),

                  duration: noAnim
                      ? Duration.zero
                      : const Duration(milliseconds: 600),

                  curve: Curves.easeOutCubic,

                  builder: (context, w, _) => Align(
                    alignment: direction > 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,

                    child: Container(
                      width: w,

                      height: 6,

                      decoration: BoxDecoration(
                        color: color,

                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),

              Align(
                alignment: Alignment.center,

                child: Container(
                  width: 1,

                  height: 6,

                  color: AppColors.starlight.withValues(alpha: 0.4),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
