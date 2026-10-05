import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../presentation/widgets/components/cosmic_card.dart';
import '../presentation/widgets/components/cosmic_error_state.dart';
import '../providers/active_profile_provider.dart';
import '../services/reference_names_service.dart';
import 'edit_birth_time_page.dart';
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
  late final AnimationController _twinkle;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadProfiles();
  }

  @override
  void dispose() {
    _twinkle.dispose();
    _entrance.dispose();
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
        _twinkle.stop();
        _entrance.value = 1;
      } else {
        _twinkle.repeat(reverse: true);
        _entrance.forward();
      }
    } catch (e) {
      debugPrint('ProfileSwitcher._loadProfiles failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = t(context, 'profile_switcher.error');
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

  Future<void> _deleteProfile(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          t(context, 'profile_switcher.delete_title'),
          style: AppTextStyles.h2(color: AppColors.textPrimary),
        ),
        content: Text(
          t(context, 'profile_switcher.delete_message'),
          style: AppTextStyles.bodyMd(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              t(context, 'common.cancel'),
              style: AppTextStyles.bodyMd(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              t(context, 'profile_switcher.delete_confirm'),
              style: AppTextStyles.bodyMd(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

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
        builder: (_) => EditBirthTimePage(profileId: profileId),
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

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}.'
          '${d.month.toString().padLeft(2, '0')}.'
          '${d.year}';
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

  // ── Starfield CustomPaint ─────────────────────────────────────────────
  List<_Star> _seedStars(int seed, int count, Size size) {
    final r = Random(seed);
    return List.generate(count, (_) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      final r2 = r.nextDouble() * 1.6 + 0.4;
      final isViolet = r.nextDouble() < 0.35;
      final phase = r.nextDouble() * 2 * pi;
      return _Star(x, y, r2, isViolet, phase);
    });
  }

  Widget _buildStarfield(Size size) {
    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final sz = Size(constraints.maxWidth, constraints.maxHeight);
          final stars = _seedStars(42, 60, sz);
          return AnimatedBuilder(
            animation: _twinkle,
            builder: (_, w) => CustomPaint(
              size: sz,
              painter: _StarfieldPainter(
                stars: stars,
                t: _twinkle.value,
                disabled: MediaQuery.of(ctx).disableAnimations,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Skeleton blocks ───────────────────────────────────────────────────
  Widget _sk({double h = 56, double? w}) => Container(
    height: h,
    width: w,
    decoration: BoxDecoration(
      color: AppColors.bgSurface,
      borderRadius: AppRadius.mdBr,
    ),
  );

  // ── SliverAppBar ──────────────────────────────────────────────────────
  Widget _buildAppBar(Map<String, dynamic>? active) {
    final name = active?['display_name']?.toString() ?? '';
    final sunId = active?['sun_sign_id'] as int?;
    final moonId = active?['moon_sign_id'] as int?;
    final ascId = active?['ascendant_sign_id'] as int?;
    final timeKnown = active?['birth_time_known'] == true;
    final ref = ReferenceNamesService.instance;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 220,
      backgroundColor: AppColors.bgDeep,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (ctx, cons) {
          final top = cons.biggest.height;
          final collapsedHeight =
              kToolbarHeight + MediaQuery.of(ctx).padding.top;
          final ratio = ((top - collapsedHeight) / (220 - collapsedHeight))
              .clamp(0.0, 1.0);
          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              fit: StackFit.expand,
              children: [
                _buildStarfield(Size.infinite),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.bgDeep.withValues(alpha: 0.0),
                        AppColors.bgDeep.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            titlePadding: const EdgeInsetsDirectional.only(
              start: AppSpacing.screenH,
              bottom: 14,
              end: AppSpacing.screenH,
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle.lerp(
                    AppTextStyles.h2(color: AppColors.textPrimary),
                    AppTextStyles.heroTitle(color: AppColors.textPrimary),
                    ratio,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ratio > 0.25)
                  Opacity(
                    opacity: ((ratio - 0.25) / 0.75).clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Flexible(
                            child: _chip(
                              '☉ ${sunId != null ? ref.sign(sunId) : '—'}',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: _chip(
                              '☽ ${timeKnown && moonId != null ? ref.sign(moonId) : '—'}',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: _chip(
                              '↑ ${timeKnown && ascId != null ? ref.sign(ascId) : '—'}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.85),
        borderRadius: AppRadius.pillBr,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        label,
        style: AppTextStyles.chip(color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── Profile strip ─────────────────────────────────────────────────────
  Widget _buildProfileStrip(String? activeId) {
    return _wrapEntrance(
      index: 1,
      child: SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.sm,
          ),
          children: [
            ..._profiles.map((p) {
              final id = p['id'] as String;
              final name = p['display_name']?.toString() ?? '';
              final isActive = id == activeId;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: GestureDetector(
                  onTap: () => _selectProfile(id),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF3D2B7A),
                                AppColors.violetPrimary,
                              ],
                            ),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.violetPrimary
                                  : AppColors.borderSubtle,
                              width: isActive ? 2.0 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _initialLetter(name),
                              style: AppTextStyles.h2(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: AppTextStyles.bodyXs(
                            color: isActive
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed('/onboarding', arguments: {'isFirstProfile': false}),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 72,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgCard,
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.violetPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t(context, 'sen.new_profile'),
                      style: AppTextStyles.bodyXs(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Identity CosmicCard ───────────────────────────────────────────────
  Widget _buildIdentity(Map<String, dynamic> active) {
    final profileId = active['id'] as String;
    final birthDate = _formatDate(active['birth_date']?.toString());
    final city = active['birth_city']?.toString() ?? '—';
    final bt = active['birth_time'];
    final timeKnown = active['birth_time_known'] == true;

    return _wrapEntrance(
      index: 2,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.lg,
          left: AppSpacing.screenH,
          right: AppSpacing.screenH,
        ),
        child: CosmicCard(
          child: Column(
            children: [
              _row(
                leading: Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t(context, 'sen.birth_date'),
                        style: AppTextStyles.bodyXs(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        birthDate,
                        style: AppTextStyles.bodyMd(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),
              _row(
                leading: Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t(context, 'sen.birth_place'),
                        style: AppTextStyles.bodyXs(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        city,
                        style: AppTextStyles.bodyMd(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              if (timeKnown) ...[
                const Divider(height: 1, color: AppColors.borderSubtle),
                _row(
                  leading: Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(context, 'sen.birth_time'),
                          style: AppTextStyles.bodyXs(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(bt),
                          style: AppTextStyles.bodyMd(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (!timeKnown) ...[
                const Divider(height: 1, color: AppColors.borderSubtle),
                InkWell(
                  onTap: () => _navigateEditBirthTime(profileId),
                  borderRadius: AppRadius.mdBr,
                  child: _row(
                    leading: Expanded(
                      child: Text(
                        t(context, 'sen.add_time'),
                        style: AppTextStyles.bodyLg(
                          color: AppColors.violetPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.violetPrimary,
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

  // ── Shortcuts CosmicCard ──────────────────────────────────────────────
  Widget _buildShortcuts(Map<String, dynamic> active) {
    final profileId = active['id'] as String;
    return _wrapEntrance(
      index: 3,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppSpacing.lg,
          left: AppSpacing.screenH,
          right: AppSpacing.screenH,
        ),
        child: CosmicCard(
          child: Column(
            children: [
              InkWell(
                onTap: () => _navigateEditBirthTime(profileId),
                borderRadius: AppRadius.mdBr,
                child: _row(
                  leading: Expanded(
                    child: Text(
                      t(context, 'sen.edit_birth_time'),
                      style: AppTextStyles.bodyLg(color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),
              InkWell(
                onTap: () => Navigator.of(context).pushNamed('/settings'),
                borderRadius: AppRadius.mdBr,
                child: _row(
                  leading: Expanded(
                    child: Text(
                      t(context, 'settings.title'),
                      style: AppTextStyles.bodyLg(color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),
              InkWell(
                onTap: () => _deleteProfile(profileId),
                borderRadius: AppRadius.mdBr,
                child: _row(
                  leading: Expanded(
                    child: Text(
                      t(context, 'sen.delete_profile'),
                      style: AppTextStyles.bodyLg(color: AppColors.errorRed),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.delete_outline,
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row({required Widget leading, Widget? trailing}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            leading,
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing,
            ],
          ],
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
          expandedHeight: 220,
          backgroundColor: AppColors.bgDeep,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: AppColors.bgCard),
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
              height: 96,
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
                          _sk(h: 48, w: 48),
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
              AppSpacing.lg,
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              0,
              AppSpacing.screenH,
              AppSpacing.contentBottom,
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
      return Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: _buildSkeleton(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bgDeep,
        appBar: AppBar(
          backgroundColor: AppColors.bgDeep,
          title: Text(t(context, 'profile_switcher.title')),
        ),
        body: Center(
          child: CosmicErrorState(
            message: t(context, 'settings.error.load'),
            onRetry: _loadProfiles,
            retryLabel: t(context, 'settings.retry'),
          ),
        ),
      );
    }

    if (active == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CosmicErrorState(
              message: t(context, 'profile_switcher.empty'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(active),
          SliverToBoxAdapter(
            child: _buildProfileStrip(active['id'] as String?),
          ),
          SliverToBoxAdapter(child: _buildIdentity(active)),
          SliverToBoxAdapter(child: _buildShortcuts(active)),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.contentBottom),
          ),
        ],
      ),
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double radius;
  final bool isViolet;
  final double phase;
  const _Star(this.x, this.y, this.radius, this.isViolet, this.phase);
}

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  final bool disabled;
  _StarfieldPainter({
    required this.stars,
    required this.t,
    required this.disabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final baseA = s.isViolet ? 0.45 : 0.55;
      final twinkle = disabled
          ? baseA
          : (baseA + sin(t * 2 * pi + s.phase) * 0.30).clamp(0.08, 0.85);
      final c = s.isViolet
          ? AppColors.violetPrimary.withValues(alpha: twinkle)
          : AppColors.textPrimary.withValues(alpha: twinkle);
      canvas.drawCircle(Offset(s.x, s.y), s.radius, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => old.t != t;
}
