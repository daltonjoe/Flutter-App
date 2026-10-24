import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/reference_ids.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../presentation/widgets/components/cosmic_background.dart';
import '../presentation/widgets/components/cosmic_card.dart';
import '../presentation/widgets/components/cosmic_error_state.dart';
import '../presentation/widgets/components/glyph.dart';
import '../presentation/widgets/components/overline_text.dart';
import '../providers/active_profile_provider.dart';
import '../providers/language_provider.dart';
import '../redesign/assets_map.dart';
import '../services/checkin_service.dart';
import 'edit_birth_data_page.dart';
import 'main_shell.dart' show mapPopToRoot;

class ProfileSwitcherPage extends StatefulWidget {
  const ProfileSwitcherPage({super.key});

  @override
  State<ProfileSwitcherPage> createState() => _ProfileSwitcherPageState();
}

class _ProfileSwitcherPageState extends State<ProfileSwitcherPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _profiles = [];
  late final AnimationController _entrance;
  late final AnimationController _lineDraw;
  late final AnimationController _triple;
  late final AnimationController _breath;

  // Yolculuk kartı (C5) — yükleme/hata durumunda kart gizlenir.
  String? _journeyProfileId;
  int? _streakDays;
  int? _moodCount;
  bool _journeyLoading = false;
  bool _journeyFailed = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _lineDraw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _triple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 690),
    );
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _loadProfiles();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeId = Provider.of<ActiveProfileProvider>(
      context,
    ).activeProfileId;
    if (activeId != null && activeId != _journeyProfileId) {
      _journeyProfileId = activeId;
      _loadJourney(activeId);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _lineDraw.dispose();
    _triple.dispose();
    _breath.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = t(context, 'profile_switcher.error');
      });
      return;
    }

    try {
      final rows = await Supabase.instance.client
          .from('user_profiles')
          .select(
            'id, display_name, birth_date, birth_time, birth_city, sun_sign_id, moon_sign_id, ascendant_sign_id, birth_time_known',
          )
          .eq('user_id', user.id)
          .order('created_at');
      if (!mounted) return;
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(rows);
        _isLoading = false;
      });
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      if (disableAnimations) {
        _entrance.value = 1;
      } else {
        _entrance.forward();
      }
      _startHeroAnimations(disableAnimations);
    } catch (e) {
      debugPrint('ProfileSwitcher._loadProfiles failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = t(context, 'profile_switcher.error');
      });
    }
  }

  /// Kimlik kartı giriş/nefes animasyonları; reduce-motion'da statik.
  void _startHeroAnimations(bool disableAnimations) {
    if (disableAnimations) {
      _lineDraw.value = 1;
      _triple.value = 1;
      _breath.stop();
      return;
    }
    _lineDraw.forward(from: 0);
    _triple.forward(from: 0);
    _breath.repeat(reverse: true);
  }

  /// Yolculuk kartı verisi: son 60 günün serisi ve ruh hali kaydı sayısı.
  Future<void> _loadJourney(String profileId) async {
    setState(() {
      _journeyLoading = true;
      _journeyFailed = false;
      _streakDays = null;
      _moodCount = null;
    });
    try {
      final rows = await CheckinService.loadRecent(profileId, days: 60);
      if (!mounted || _journeyProfileId != profileId) return;
      final days = rows.map((c) => c.day).toSet();
      final moods = rows.where((c) => c.mood > 0).length;
      setState(() {
        _streakDays = CheckinService.currentStreak(days, DateTime.now());
        _moodCount = moods;
        _journeyLoading = false;
      });
    } catch (e) {
      debugPrint('ProfileSwitcher._loadJourney failed: $e');
      if (!mounted) return;
      setState(() {
        _journeyLoading = false;
        _journeyFailed = true;
      });
    }
  }

  Map<String, dynamic>? _resolveActive(String? activeId) {
    if (_profiles.isEmpty) return null;
    if (activeId != null) {
      final m = _profiles.firstWhere(
        (p) => p['id'] == activeId,
        orElse: () => _profiles.first,
      );
      return m;
    }
    return _profiles.first;
  }

  Future<void> _selectProfile(String id) async {
    HapticFeedback.selectionClick();
    await context.read<ActiveProfileProvider>().setActive(id);
    mapPopToRoot.value++;
  }

  /// Silme onayı: alt sayfa (bottom sheet). Onayda [id] silinir.
  Future<void> _confirmDeleteProfile(String id) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isDismissible: true,
      backgroundColor: AppColors.navyDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t(context, 'profile_switcher.delete_title'),
                style: AppTextStyles.h2(color: AppColors.starlight),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t(context, 'profile_switcher.delete_message'),
                style: AppTextStyles.bodyMd(color: AppColors.mist),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.onGold,
                  minimumSize: const Size.fromHeight(AppSizes.ctaHeight),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                onPressed: () => Navigator.pop(sheetContext, false),
                child: Text(t(context, 'common.cancel')),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(sheetContext, true);
                },
                child: Text(
                  t(context, 'profile_switcher.delete_confirm'),
                  style: AppTextStyles.bodyMd(color: AppColors.statusDanger),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    await _deleteProfile(id);
  }

  Future<void> _deleteProfile(String id) async {
    try {
      await Supabase.instance.client
          .from('user_profiles')
          .delete()
          .eq('id', id);
      if (!mounted) return;

      final activeProfileProvider = context.read<ActiveProfileProvider>();
      if (activeProfileProvider.activeProfileId == id) {
        await activeProfileProvider.clearActive();
      }
      if (!mounted) return;
      await _loadProfiles();
      if (!mounted) return;
      if (_profiles.isEmpty) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/onboarding',
          (route) => false,
          arguments: {'isFirstProfile': true},
        );
      }
    } catch (e) {
      debugPrint('ProfileSwitcher._deleteProfile failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, 'profile_switcher.delete_error'))),
      );
    }
  }

  Future<void> _navigateEditBirthTime(String profileId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditBirthDataPage(profileId: profileId),
      ),
    );
    if (result == true && mounted) {
      await _loadProfiles();
    }
  }

  Widget _wrapEntrance({required int index, required Widget child}) {
    const curves = [0.0, 0.08, 0.18, 0.30, 0.44];
    final start = curves[index.clamp(0, curves.length - 1)];
    final end = (start + 0.50).clamp(0.0, 1.0);
    final fade = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entrance,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  String _formatDate(String? iso, String locale) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso);
      return DateFormat('d MMMM y', locale).format(d);
    } catch (_) {
      return iso;
    }
  }

  String _formatTime(dynamic bt) {
    if (bt == null) return '—';
    final s = bt.toString();
    final parts = s.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return s;
  }

  String _initialLetter(String name) {
    if (name.isEmpty) return '?';
    return name.characters.first.toUpperCase();
  }

  // ── Skeleton blocks ───────────────────────────────────────────────────
  Widget _sk({double h = 56, double? w}) => Container(
    height: h,
    width: w,
    decoration: BoxDecoration(
      color: AppColors.navyRaised,
      borderRadius: AppRadius.mdBr,
    ),
  );

  // ── Kimlik kartı (hero) ───────────────────────────────────────────────
  Widget _buildHero(Map<String, dynamic> active) {
    final name = active['display_name']?.toString() ?? '';
    final sunIdx = RefIds.signIndex(active['sun_sign_id'] as int?);
    final moonIdx = RefIds.signIndex(active['moon_sign_id'] as int?);
    final ascIdx = RefIds.signIndex(active['ascendant_sign_id'] as int?);
    final timeKnown = active['birth_time_known'] == true;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 260,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (ctx, cons) {
          final top = cons.biggest.height;
          final collapsedHeight =
              kToolbarHeight + MediaQuery.of(ctx).padding.top;
          final ratio = ((top - collapsedHeight) / (260 - collapsedHeight))
              .clamp(0.0, 1.0);
          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            titlePadding: const EdgeInsetsDirectional.only(
              start: AppSpacing.screenH,
              bottom: 14,
              end: AppSpacing.screenH,
            ),
            title: Opacity(
              opacity: (1 - ratio).clamp(0.0, 1.0),
              child: Text(
                name,
                style: AppTextStyles.h2(color: AppColors.starlight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            background: _heroBackground(
              name: name,
              sunIdx: sunIdx,
              moonIdx: moonIdx,
              ascIdx: ascIdx,
              timeKnown: timeKnown,
            ),
          );
        },
      ),
    );
  }

  Widget _heroBackground({
    required String name,
    required int? sunIdx,
    required int? moonIdx,
    required int? ascIdx,
    required bool timeKnown,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (sunIdx != null)
          AnimatedBuilder(
            animation: _breath,
            builder: (context, _) {
              final disable = MediaQuery.of(context).disableAnimations;
              final opacity = disable ? 0.05 : 0.04 + 0.03 * _breath.value;
              return Opacity(
                opacity: opacity,
                child: Image.asset(
                  RdAssets.signIcon(sunIdx),
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              );
            },
          ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            top: kToolbarHeight,
            bottom: AppSpacing.lg,
            start: AppSpacing.screenH,
            end: AppSpacing.screenH,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tripleRow(ascIdx: ascIdx, timeKnown: timeKnown),
              const SizedBox(height: AppSpacing.md),
              Text(
                name,
                style: AppTextStyles.display(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              ..._heroChips(
                sunIdx: sunIdx,
                moonIdx: moonIdx,
                ascIdx: ascIdx,
                timeKnown: timeKnown,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Güneş · Ay · Yükselen glyph satırı; aralarında çizilen ince altın çizgi.
  Widget _tripleRow({required int? ascIdx, required bool timeKnown}) {
    final showAsc = timeKnown && ascIdx != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tripleGlyph('sun', 0),
        _connector(),
        _tripleGlyph('moon', 1),
        if (showAsc) ...[_connector(), _tripleGlyph('asc', 2)],
      ],
    );
  }

  Widget _tripleGlyph(String glyph, int order) {
    final start = (order * 120) / 690;
    final end = ((order * 120 + 450) / 690).clamp(0.0, 1.0);
    final fade = CurvedAnimation(
      parent: _triple,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    final scale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _triple,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        child: Glyph(glyph, size: 36, color: AppColors.gold, decorative: true),
      ),
    );
  }

  Widget _connector() {
    return SizedBox(
      width: 44,
      height: 36,
      child: Center(
        child: AnimatedBuilder(
          animation: _lineDraw,
          builder: (_, _) => Container(
            width: 44 * _lineDraw.value,
            height: 1,
            color: AppColors.gold.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  List<Widget> _heroChips({
    required int? sunIdx,
    required int? moonIdx,
    required int? ascIdx,
    required bool timeKnown,
  }) {
    final chips = <Widget>[
      if (sunIdx != null) _roleChip(sunIdx, 'sun', 'chart.sun'),
      if (moonIdx != null) _roleChip(moonIdx, 'moon', 'chart.moon'),
      if (timeKnown && ascIdx != null)
        _roleChip(ascIdx, 'asc', 'chart.ascendant'),
    ];
    if (chips.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: chips,
      ),
    ];
  }

  /// "Güneş · Yengeç" biçiminde glyph + rol + burç adı chip'i.
  Widget _roleChip(int signIndex, String glyph, String roleKey) {
    final code = RefIds.signCode(signIndex);
    final signName = code == null ? '' : t(context, 'signs.$code');
    return Container(
      height: AppSizes.chipHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.navyRaised.withValues(alpha: 0.85),
        borderRadius: AppRadius.pillBr,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Glyph(glyph, size: 16, color: AppColors.gold, decorative: true),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${t(context, roleKey)} · $signName',
            style: AppTextStyles.chip(color: AppColors.starlight),
          ),
        ],
      ),
    );
  }

  // ── Profil şeridi ─────────────────────────────────────────────────────
  Widget _buildProfileStrip(String? activeId) {
    return _wrapEntrance(
      index: 1,
      child: SizedBox(
        height: 112,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.sm,
          ),
          children: [
            ..._profiles.map((p) => _stripAvatar(p, p['id'] == activeId)),
            _addChip(),
          ],
        ),
      ),
    );
  }

  Widget _stripAvatar(Map<String, dynamic> p, bool isActive) {
    final name = p['display_name']?.toString() ?? '';
    final sunIdx = RefIds.signIndex(p['sun_sign_id'] as int?);
    final disable = MediaQuery.of(context).disableAnimations;
    final duration = disable
        ? Duration.zero
        : const Duration(milliseconds: 300);

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Semantics(
        button: true,
        selected: isActive,
        label: name,
        child: GestureDetector(
          onTap: () => _selectProfile(p['id'] as String),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOut,
                  width: 56,
                  height: 56,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.navyRaised,
                    border: Border.all(
                      color: isActive ? AppColors.gold : AppColors.hairline,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: sunIdx == null
                      ? _stripInitial(name)
                      : Image.asset(
                          RdAssets.signIcon(sunIdx),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _stripInitial(name),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: AppTextStyles.bodyXs(
                    color: isActive ? AppColors.starlight : AppColors.mist,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (isActive) ...[
                  const SizedBox(height: 2),
                  Text(
                    t(context, 'profile_switcher.active'),
                    style: AppTextStyles.miniTag(color: AppColors.gold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stripInitial(String name) => Center(
    child: Text(
      _initialLetter(name),
      style: AppTextStyles.h2(color: AppColors.starlight),
    ),
  );

  Widget _addChip() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).pushNamed(
          '/onboarding',
          arguments: {'isFirstProfile': false},
        );
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.navyRaised,
                border: Border.all(color: AppColors.hairline),
              ),
              child: const Icon(Icons.add, color: AppColors.gold),
            ),
            const SizedBox(height: 6),
            Text(
              t(context, 'profile_switcher.new_short'),
              style: AppTextStyles.bodyXs(color: AppColors.mist),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Doğum kartı ───────────────────────────────────────────────────────
  Widget _buildBirthCard(Map<String, dynamic> active) {
    final profileId = active['id'] as String;
    final locale = context.watch<LanguageProvider>().locale.languageCode;
    final birthDate = _formatDate(active['birth_date']?.toString(), locale);
    final city = active['birth_city']?.toString() ?? '—';
    final timeKnown = active['birth_time_known'] == true;

    return _wrapEntrance(
      index: 2,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.cardGap,
          left: AppSpacing.screenH,
          right: AppSpacing.screenH,
        ),
        child: CosmicCard(
          blur: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Semantics(
                    button: true,
                    label: t(context, 'sen.edit_birth_data'),
                    child: InkWell(
                      borderRadius: AppRadius.pillBr,
                      onTap: () => _navigateEditBirthTime(profileId),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.mist,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _birthField(
                      label: t(context, 'sen.birth_date'),
                      value: birthDate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _birthField(
                      label: t(context, 'sen.birth_place'),
                      value: city,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _birthField(
                label: t(context, 'sen.birth_time'),
                value: _formatTime(active['birth_time']),
                trailing: _timeBadge(timeKnown),
              ),
              if (!timeKnown) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  t(context, 'profile_switcher.time_hint'),
                  style: AppTextStyles.bodyXs(color: AppColors.mist),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  borderRadius: AppRadius.mdBr,
                  onTap: () => _navigateEditBirthTime(profileId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 18,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            t(context, 'sen.add_time'),
                            style: AppTextStyles.bodyMd(color: AppColors.gold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _birthField({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OverlineText(label),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodyMd(color: AppColors.starlight),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              trailing,
            ],
          ],
        ),
      ],
    );
  }

  Widget _timeBadge(bool timeKnown) {
    final color = timeKnown ? AppColors.statusSupportive : AppColors.mist;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.pillBr,
      ),
      child: Text(
        t(
          context,
          timeKnown
              ? 'profile_switcher.time_exact'
              : 'profile_switcher.time_unknown',
        ),
        style: AppTextStyles.miniTag(color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── Yolculuk kartı ────────────────────────────────────────────────────
  Widget _buildJourneyCard(String profileId) {
    final streak = _streakDays;
    final moods = _moodCount;
    if (_journeyLoading || _journeyFailed || streak == null || moods == null) {
      return const SizedBox.shrink();
    }
    return _wrapEntrance(
      index: 3,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppSpacing.cardGap,
          left: AppSpacing.screenH,
          right: AppSpacing.screenH,
        ),
        child: CosmicCard(
          onTap: () =>
              Navigator.of(context).pushNamed('/streak', arguments: profileId),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OverlineText(t(context, 'profile_switcher.journey.title')),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _journeyStat(
                      value: streak,
                      label: t(context, 'profile_switcher.journey.streak'),
                    ),
                  ),
                  Expanded(
                    child: _journeyStat(
                      value: moods,
                      label: t(context, 'profile_switcher.journey.moods'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _journeyStat({required int value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CountUp(
          value: value,
          style: AppTextStyles.display(color: AppColors.gold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodyXs(color: AppColors.mist),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Kısayollar ────────────────────────────────────────────────────────
  Widget _buildShortcuts() {
    return _wrapEntrance(
      index: 4,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppSpacing.lg,
          left: AppSpacing.screenH,
          right: AppSpacing.screenH,
        ),
        child: CosmicCard(
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed('/settings'),
            borderRadius: AppRadius.mdBr,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: AppColors.mist,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      t(context, 'settings.title'),
                      style: AppTextStyles.bodyLg(color: AppColors.starlight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    size: 20,
                    color: AppColors.mist,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Silme (kart dışında, en altta) ────────────────────────────────────
  Widget _buildDeleteButton(String profileId) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl,
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
      ),
      child: Center(
        child: TextButton(
          onPressed: () => _confirmDeleteProfile(profileId),
          child: Text(
            t(context, 'sen.delete_profile'),
            style: AppTextStyles.bodyMd(color: AppColors.statusDanger),
          ),
        ),
      ),
    );
  }

  // ── Loading skeleton ──────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 260,
          backgroundColor: AppColors.bgDeep,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: AppColors.navyDeep),
            titlePadding: const EdgeInsetsDirectional.only(
              start: AppSpacing.screenH,
              bottom: 14,
              end: AppSpacing.screenH,
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sk(h: 34, w: 180),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _sk(h: 28, w: 72),
                    const SizedBox(width: 6),
                    _sk(h: 28, w: 72),
                    const SizedBox(width: 6),
                    _sk(h: 28, w: 72),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: SizedBox(
              height: 112,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                  vertical: AppSpacing.sm,
                ),
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          _sk(h: 56, w: 56),
                          const SizedBox(height: 6),
                          _sk(h: 12, w: 56),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.md,
              AppSpacing.screenH,
              AppSpacing.cardGap,
            ),
            child: CosmicCard(
              child: Column(
                children: [
                  _sk(h: 48),
                  const SizedBox(height: AppSpacing.md),
                  _sk(h: 48),
                  const SizedBox(height: AppSpacing.md),
                  _sk(h: 48),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              0,
              AppSpacing.screenH,
              AppSizes.scrollBottomPadding(context),
            ),
            child: CosmicCard(
              child: Column(
                children: [
                  _sk(h: 48),
                  const SizedBox(height: AppSpacing.md),
                  _sk(h: 48),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ActiveProfileProvider>();
    final activeId = prov.activeProfileId;
    // ignore: unused_local_variable
    final rev = prov.revision;
    final active = _resolveActive(activeId);

    if (_isLoading) {
      return CosmicBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: _buildSkeleton(),
        ),
      );
    }

    if (_error != null) {
      return CosmicBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(t(context, 'profile_switcher.title')),
          ),
          body: Center(
            child: CosmicErrorState(
              message: t(context, 'settings.error.load'),
              onRetry: _loadProfiles,
              retryLabel: t(context, 'settings.retry'),
            ),
          ),
        ),
      );
    }

    if (active == null) {
      return CosmicBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CosmicErrorState(
                message: t(context, 'profile_switcher.empty'),
              ),
            ),
          ),
        ),
      );
    }

    final profileId = active['id'] as String? ?? '';

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            _buildHero(active),
            SliverToBoxAdapter(
              child: _buildProfileStrip(active['id'] as String?),
            ),
            SliverToBoxAdapter(child: _buildBirthCard(active)),
            SliverToBoxAdapter(child: _buildJourneyCard(profileId)),
            SliverToBoxAdapter(child: _buildShortcuts()),
            SliverToBoxAdapter(child: _buildDeleteButton(profileId)),
            SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.scrollBottomPadding(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 0 → değer arası sayma animasyonu (reduce-motion'da animasyonsuz).
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final disable = MediaQuery.of(context).disableAnimations;
    if (disable) return Text(value.toString(), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(v.round().toString(), style: style),
    );
  }
}
