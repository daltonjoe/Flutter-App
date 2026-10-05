import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_decorations.dart';
import '../i18n/app_localizations.dart';
import '../services/checkin_service.dart';

class StreakPage extends StatefulWidget {
  final String profileId;
  const StreakPage({super.key, required this.profileId});

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage> {
  bool _loading = true;
  Object? _error;
  List<Checkin> _checkins = const [];

  static const Map<int, Color> _moodColors = {
    1: AppColors.roseAccent,
    2: AppColors.amberTransit,
    3: AppColors.textMuted,
    4: AppColors.tealSuccess,
    5: AppColors.goldAccent,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await CheckinService.loadRecent(widget.profileId, days: 60);
      if (!mounted) return;
      setState(() {
        _checkins = c;
        _loading = false;
      });
    } catch (e) {
      debugPrint('streak page load failed: $e');
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Flexible(
              child: Text(
                t(context, 'streak.detail.title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h2(),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t(context, 'today.error'),
                style: AppTextStyles.h3(color: AppColors.errorRed),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _error.toString(),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: AppSizes.ctaHeight,
                child: DecoratedBox(
                  decoration: AppDecorations.primaryCta(),
                  child: TextButton(
                    onPressed: _load,
                    child: Text(
                      t(context, 'today.retry'),
                      style: AppTextStyles.ctaPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final byDay = <String, int>{};
    for (final c in _checkins) {
      byDay[c.day] = c.mood;
    }
    final days = byDay.keys.toSet();
    final current = CheckinService.currentStreak(days, DateTime.now());
    final best = CheckinService.bestStreak(days);
    final empty = byDay.isEmpty;
    if (empty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.contentTop,
          AppSpacing.screenH,
          AppSpacing.contentBottom,
        ),
        children: [
          Container(
            decoration: AppDecorations.cosmicCard(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 40,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        t(context, 'streak.detail.empty'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.contentTop,
        AppSpacing.screenH,
        AppSpacing.contentBottom,
      ),
      children: [
        Container(
          decoration: AppDecorations.cosmicCard(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                current.toString(),
                style: AppTextStyles.heroTitle(
                  color: current > 0
                      ? AppColors.violetPrimary
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      t(
                        context,
                        'streak.days',
                        args: {'n': current.toString()},
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLg(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                   '${t(context, 'streak.best')}: $best',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Flexible(
              child: Text(
                t(context, 'streak.detail.last30'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: AppDecorations.cosmicCard(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LayoutBuilder(
            builder: (ctx, c) {
              return _last30Grid(ctx, c.maxWidth, byDay);
            },
          ),
        ),
      ],
    );
  }

  Widget _last30Grid(
    BuildContext context,
    double maxWidth,
    Map<String, int> byDay,
  ) {
    const columns = 7;
    const total = 30;
    final today = DateTime.now().toLocal();
    today.toLocal();
    final todayStripped = DateTime(today.year, today.month, today.day);
    final oldest = todayStripped.subtract(const Duration(days: total - 1));
    final days = List<DateTime>.generate(
      total,
      (i) => oldest.add(Duration(days: i)),
    );
    const cellMinDp = 36.0;
    final gap = AppSpacing.xs;
    final available = maxWidth - (gap * (columns - 1));
    final perCol = (available / columns).floorToDouble();
    final side = perCol < cellMinDp ? cellMinDp : perCol;
    final int rows = (total / columns).ceil();
    return Column(
      children: List.generate(rows, (r) {
        return Padding(
          padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : gap),
          child: Row(
            children: List.generate(columns, (c) {
              final idx = r * columns + c;
              if (idx >= total) {
                return Expanded(
                  child: SizedBox(width: side, height: side),
                );
              }
              final d = days[idx];
              final k = CheckinService.dayKey(d);
              final mood = byDay[k];
              final isToday = d == todayStripped;
              final bgColor = mood == null
                  ? AppColors.bgSurface
                  : _moodColors[mood] ?? AppColors.textMuted;
              final borderColor = mood == null
                  ? AppColors.borderSubtle
                  : (mood == 3
                        ? AppColors.borderMedium
                        : (_moodColors[mood] ?? AppColors.borderSubtle)
                              .withValues(alpha: 0.5));
              return Padding(
                padding: EdgeInsets.only(right: c == columns - 1 ? 0 : gap),
                child: SizedBox(
                  width: side,
                  height: side,
                  child: Tooltip(
                    message: k,
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isToday
                              ? AppColors.violetPrimary
                              : borderColor,
                          width: isToday ? 1.5 : 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
