import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../providers/active_profile_provider.dart';
import '../providers/language_provider.dart';
import '../services/match_service.dart';
import '../services/reference_names_service.dart';
import '../models/ask_context.dart';
import '../providers/ask_context_provider.dart' show askEnabled;
import '../widgets/ask_add.dart' show addToAsk;
import '../services/user_settings_service.dart';
import '../core/match_weights.dart';
import 'edit_birth_data_page.dart';


class _ProfileEntry {
  final String id;
  final String displayName;
  final bool timeKnown;
  final int? sunId, moonId, ascId;
  const _ProfileEntry({
    required this.id,
    required this.displayName,
    required this.timeKnown,
    this.sunId,
    this.moonId,
    this.ascId,
  });
}

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  List<_ProfileEntry> _profiles = const [];
  String _filter = 'all'; // all | harmony | tension | pull|feel|talk|pace|grow
  bool _profilesLoading = true;
  Object? _profilesError;
  String? _profileA;
  String? _profileB;
  bool _v2 = false;

  bool _resultLoading = false;
  Object? _resultError;
  MatchResult? _result;
  final Map<String, MatchResult> _cache = {};
  final Map<String, Map<String, String>> _textCache = {};
  String? _loc;
  Map<String, String> _texts = const {};

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    unawaited(UserSettingsService.isFlagEnabled('match_v2').then((v) {
      if (mounted) setState(() => _v2 = v);
    }));
  }

  static String _pk(String a, String b) {
    if (a.compareTo(b) < 0) return '$a|$b';
    return '$b|$a';
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _profilesLoading = true;
      _profilesError = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final uid = user?.id;
      List<Map<String, dynamic>> rows = const [];
      if (uid != null) {
        final r = await Supabase.instance.client
            .from('user_profiles')
            .select('id,display_name,birth_time_known,sun_sign_id,moon_sign_id,ascendant_sign_id')
            .eq('user_id', uid);
      rows = List<Map<String, dynamic>>.from(r);
      }
      final list = <_ProfileEntry>[];
      for (final row in rows) {
        final id = row['id']?.toString();
        if (id == null) continue;
        list.add(
          _ProfileEntry(
            sunId: row['sun_sign_id'] as int?,
            moonId: row['moon_sign_id'] as int?,
            ascId: row['ascendant_sign_id'] as int?,
            id: id,
            displayName: row['display_name']?.toString() ?? '',
            timeKnown: (row['birth_time_known'] as bool?) ?? false,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _profiles = list;
        _profilesLoading = false;
      });
      if (!mounted) return;
      final active = context.read<ActiveProfileProvider>().activeProfileId;
      if (active != null &&
          list.any((p) => p.id == active) &&
          _profileA == null) {
        if (!mounted) return;
        setState(() {
          _profileA = active;
        });
        unawaited(_maybeFetch(active, _profileB));
      }
    } catch (e, st) {
      debugPrint('match loadProfiles failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _profilesError = e;
        _profilesLoading = false;
      });
    }
  }
  Future<void> _maybeFetch(String? a, String? b) async {
    if (a == null || b == null) return;
    final key = _pk(a, b);
    final cached = _cache[key];
    if (cached != null) {
      final locC = context.read<LanguageProvider>().locale.languageCode;
      setState(() {
        _result = cached;
        _texts = _textCache['$key|$locC'] ?? const {};
        _resultError = null;
        _resultLoading = false;
      });
      if (_textCache['$key|$locC'] == null) {
        unawaited(_loadTexts(key, cached, locC));
      }
      return;
    }
    final loc = context.read<LanguageProvider>().locale.languageCode;
    setState(() {
      _resultLoading = true;
      _resultError = null;
      _result = null;
      _texts = const {};
    });
    try {
      final r = await MatchService.fetch(a, b);
      final tx = await MatchService.fetchTexts(r.aspects.toList(), loc);
      if (!mounted) return;
      _cache[key] = r;
      _textCache['$key|$loc'] = tx;
      final curLoc = context.read<LanguageProvider>().locale.languageCode;
      setState(() {
        _result = r;
        _texts = curLoc == loc ? tx : const {};
        _resultLoading = false;
      });
      if (curLoc != loc) unawaited(_loadTexts(key, r, curLoc));
    } catch (e, st) {
      debugPrint('match fetch failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _resultError = e;
        _resultLoading = false;
      });
    }
  }

  Future<void> _loadTexts(String key, MatchResult r, String loc) async {
    final tk = '$key|$loc';
    final c = _textCache[tk];
     if (c != null) {
      if (mounted) setState(() => _texts = c);
      return;
    }
    if (mounted) setState(() => _texts = const {});
    try {
      final tx = await MatchService.fetchTexts(r.aspects.toList(), loc);
      if (!mounted) return;
      _textCache[tk] = tx;
      if (_loc == loc && identical(_result, r)) {
        setState(() => _texts = tx);
      }
    } catch (e, st) {
      debugPrint('match texts reload failed: $e\n$st');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = Provider.of<LanguageProvider>(context).locale.languageCode;
    final prev = _loc;
    _loc = loc;
    final r = _result;
    final a = _profileA;
    final b = _profileB;
    if (prev != null && prev != loc && r != null && a != null && b != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadTexts(_pk(a, b), r, loc));
      });
    }
  }

  void _setA(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _profileA = id;
      if (_profileB == id) _profileB = null;
      _result = null;
      _resultError = null;
    });
    unawaited(_maybeFetch(_profileA, _profileB));
    Navigator.of(context).maybePop();
  }

  void _setB(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _profileB = id;
      if (_profileA == id) _profileA = null;
      _result = null;
      _resultError = null;
    });
    unawaited(_maybeFetch(_profileA, _profileB));
    Navigator.of(context).maybePop();
  }

  Future<void> _openPicker({required bool isA}) async {
    final exclude = isA ? _profileB : _profileA;
    final options = _profiles.where((p) => p.id != exclude).toList();
    await showModalBottomSheet<void>(
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        t(context, isA ? 'match.pick_a' : 'match.pick_b'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h2(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (options.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            t(context, 'match.pick_hint'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    fit: FlexFit.loose,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: options.length,
                      separatorBuilder: (_, i) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (_, i) {
                        final p = options[i];
                        return SizedBox(
                          height: AppSpacing.xxl,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: AppRadius.mdBr,
                              onTap: () {
                                if (isA) {
                                  _setA(p.id);
                                } else {
                                  _setB(p.id);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.displayName.isEmpty
                                            ? p.id
                                            : p.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.bodyLg(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _selector({required bool isA}) {
    final selected = isA ? _profileA : _profileB;
    final labelKey = isA ? 'match.pick_a' : 'match.pick_b';
    final entry = selected == null
        ? null
        : _profiles.cast<_ProfileEntry?>().firstWhere(
            (p) => p?.id == selected,
            orElse: () => null,
          );
    final text = entry == null
        ? t(context, labelKey)
        : (entry.displayName.isEmpty ? entry.id : entry.displayName);
    final hint = entry == null;
    return Expanded(
      child: SizedBox(
        height: AppSizes.ctaHeight,
        child: DecoratedBox(
          decoration: hint
              ? AppDecorations.primaryCta()
              : AppDecorations.secondaryCta(),
          child: TextButton(
            onPressed: _profilesLoading || _profiles.isNotEmpty == false
                ? null
                : () => _openPicker(isA: isA),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: hint
                        ? AppTextStyles.ctaPrimary
                        : AppTextStyles.ctaSecondary(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
   Widget build(BuildContext context) {
    context.watch<ReferenceNamesService>();
    final noAnim = MediaQuery.disableAnimationsOf(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Flexible(
              child: Text(
                t(context, 'match.title'),
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
            onPressed: () {
              final a = _profileA;
              final b = _profileB;
              if (a != null && b != null) {
                _cache.remove(_pk(a, b));
                unawaited(_maybeFetch(a, b));
              } else {
                unawaited(_loadProfiles());
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
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
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      _selector(isA: true),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.favorite_border,
                        size: 20,
                        color: AppColors.violetPrimary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _selector(isA: false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _body(noAnim, l),
          ],
        ),
      ),
    );
  }

  Widget _body(bool noAnim, AppLocalizations? l) {
    if (_profilesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_profilesError != null) {
      return _errorCard(context, onRetry: _loadProfiles);
    }
    if (_profiles.length < 2) {
      return _infoCard(context, t(context, 'match.empty'));
    }
    if (_profileA == null || _profileB == null) {
      return _infoCard(context, t(context, 'match.need_two'));
    }
    if (_resultLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_resultError != null) {
      return _errorCard(
        context,
        onRetry: () {
          final a = _profileA;
          final b = _profileB;
          if (a != null && b != null) {
            _cache.remove(_pk(a, b));
            unawaited(_maybeFetch(a, b));
          }
        },
      );
    }
    final r = _result;
    if (r == null) {
      return const SizedBox.shrink();
    }
    final note = !r.timeKnownA || !r.timeKnownB;
      // Yönsüz metin: A.x-B.y ve A.y-B.x aynı anahtar; küçük orb olanı tut.
    final dedup = <String, MatchAspect>{};
    for (final x in r.aspects) {
      final k = MatchService.textKey(x.bodyAId, x.bodyBId, x.aspectTypeId);
      final prev = dedup[k];
      if (prev == null || x.orb < prev.orb) dedup[k] = x;
    }
    final aspects = dedup.values.take(40).toList();
    if (_v2) return _v2Body(r, dedup.values.toList(), note);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note) ...[
          _infoCard(context, t(context, 'match.time_unknown_note')),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            Flexible(
              child: Text(
                t(context, 'match.aspects_title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (aspects.isEmpty)
          _infoCard(context, t(context, 'match.no_aspects'))
        else
          Container(
            decoration: AppDecorations.cosmicCard(),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: List.generate(aspects.length, (i) {
                final a = aspects[i];
                return _aspectRow(
                  a,
                  i == aspects.length - 1,
                  _texts[MatchService.textKey(
                      a.bodyAId, a.bodyBId, a.aspectTypeId)],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _infoCard(BuildContext context, String text) {
    return Container(
      decoration: AppDecorations.cosmicCard(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMd(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(BuildContext context, {required VoidCallback onRetry}) {
    return Container(
      decoration: AppDecorations.cosmicCard(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  t(context, 'match.error'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3(color: AppColors.errorRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSizes.ctaHeight,
            width: double.infinity,
            child: DecoratedBox(
              decoration: AppDecorations.primaryCta(),
              child: TextButton(
                onPressed: onRetry,
                child: Text(
                  t(context, 'match.retry'),
                  style: AppTextStyles.ctaPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
    void _addAspect(MatchAspect a) {
    final pa = _profileA;
    final pb = _profileB;
    if (pa == null || pb == null) return;
    final s = ReferenceNamesService.instance;
    addToAsk(
      context,
      AskContext.synastry(
        profileA: pa,
        profileB: pb,
        bodyA: a.bodyAId,
        bodyB: a.bodyBId,
        aspectTypeId: a.aspectTypeId,
        label:
            '${s.planet(a.bodyAId)} · ${s.aspect(a.aspectTypeId)} · ${s.planet(a.bodyBId)}',
      ),
    );
  }

  Widget _aspectRow(MatchAspect a, bool isLast, String? text) {
    final svc = ReferenceNamesService.instance;
    final bA = svc.planet(a.bodyAId);
    final bB = svc.planet(a.bodyBId);
    final asp = svc.aspect(a.aspectTypeId);
    final tight = a.tightness < 0.25;
    final accent = tight ? AppColors.goldAccent : AppColors.textPrimary;
    final muted = tight ? AppColors.goldAccent : AppColors.textSecondary;
    final orbStr = a.orb.toStringAsFixed(1);
    final hasText = text != null && text.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: isLast ? AppSpacing.xs : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: AppSpacing.xxl,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                children: [
                  Flexible(
                    flex: 4,
                    fit: FlexFit.tight,
                    child: Text(
                      bA,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd(color: accent),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    flex: 5,
                    fit: FlexFit.tight,
                    child: Text(
                      asp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLg(color: muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    flex: 4,
                    fit: FlexFit.tight,
                    child: Text(
                      bB,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.bodyMd(color: accent),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 72,
                    child: Text(
                      t(context, 'match.orb', args: {'value': orbStr}),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.bodyXs(color: muted),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: askEnabled,
                    builder: (ctx, on, _) => on
                        ? IconButton(
                            tooltip: t(ctx, 'ask.add'),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.auto_awesome_outlined,
                                size: 18, color: AppColors.violetPrimary),
                            onPressed: () => _addAspect(a),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          if (hasText)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                0,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Text(
                text,
                style: AppTextStyles.bodySm(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

    List<WeightedAspect> _weighted(List<MatchAspect> l) {
    final out = <WeightedAspect>[];
    for (final x in l) {
      final m = MatchService.meta[
          MatchService.textKey(x.bodyAId, x.bodyBId, x.aspectTypeId)];
      if (m == null) continue; // metinsiz: hesaba girmez
      final lo = x.bodyAId < x.bodyBId ? x.bodyAId : x.bodyBId;
      final hi = x.bodyAId < x.bodyBId ? x.bodyBId : x.bodyAId;
      out.add(WeightedAspect(lo, hi, x.aspectTypeId,
          aspectWeight(lo, hi, x.aspectTypeId, x.tightness, m.intensity),
          themeOf(lo, hi)));
    }
    return out;
  }

  _ProfileEntry? _prof(String? id) {
    for (final p in _profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  Widget _signCell(int? id, bool show, String? pid) {
    if (show && id != null) {
      return Text(ReferenceNamesService.instance.sign(id),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMd(color: AppColors.textPrimary));
    }
    return InkWell(
      onTap: pid == null
          ? null
          : () async {
              final ok = await Navigator.of(context, rootNavigator: true)
                  .push<bool>(MaterialPageRoute(
                      builder: (_) => EditBirthDataPage(profileId: pid)));
              if (ok != true || !mounted) return;
              _cache.clear();
              _textCache.clear();
              await _loadProfiles();
              unawaited(_maybeFetch(_profileA, _profileB));
            },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(t(context, 'match.add_time'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm(color: AppColors.goldAccent)),
        ),
      ),
    );
  }

  Widget _v2Body(MatchResult r, List<MatchAspect> all, bool note) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _v2Top(r, all, note),
          const SizedBox(height: AppSpacing.lg),
          _v2List(all),
        ],
      );

  String _heroLine(List<WeightedAspect> top) {
    if (top.isEmpty) return '';
    final s =
        _texts[MatchService.textKey(top.first.a, top.first.b, top.first.asp)] ??
            '';
    final m = RegExp(r'[.!?](\s|$)').firstMatch(s);
    return (m == null ? s : s.substring(0, m.start + 1)).trim();
  }

  Color _valColor(String v) {
    switch (v) {
      case 'power':
        return AppColors.tealSuccess;
      case 'pressure':
        return AppColors.amberTransit;
      case 'trouble':
        return AppColors.roseAccent;
      default:
        return AppColors.goldAccent;
    }
  }

  Widget _v2List(List<MatchAspect> all) {
    final svc = ReferenceNamesService.instance;
    final byKey = <String, MatchAspect>{};
    for (final x in all) {
      byKey[MatchService.textKey(x.bodyAId, x.bodyBId, x.aspectTypeId)] = x;
    }
    String keyOf(WeightedAspect x) => MatchService.textKey(x.a, x.b, x.asp);
    String vOf(WeightedAspect x) =>
        MatchService.meta[keyOf(x)]?.valence ?? 'neutral';
    bool pass(WeightedAspect x) {
      final v = vOf(x);
      switch (_filter) {
        case 'all':
          return true;
        case 'harmony':
          return v == 'power';
        case 'tension':
          return v == 'pressure' || v == 'trouble';
        default:
          return x.theme == _filter;
      }
    }

    final ranked = rankAspects(_weighted(all));
    const themeOrder = ['pull', 'feel', 'talk', 'pace', 'grow'];
    const chipKeys = ['all', 'harmony', 'tension', ...themeOrder];
    String chipLabel(String k) => (k == 'all' || k == 'harmony' || k == 'tension')
        ? t(context, 'match.filter.$k')
        : t(context, 'match.theme.$k');

    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final k in chipKeys)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(chipLabel(k),
                    style:
                        AppTextStyles.bodySm(color: AppColors.textPrimary)),
                selected: _filter == k,
                selectedColor: AppColors.violetPrimary,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _filter = k);
                },
              ),
            ),
        ],
      ),
    );

    Widget card(WeightedAspect x) {
      final asp = byKey[keyOf(x)];
      final col = _valColor(vOf(x));
      final bar = asp == null ? 0.0 : (1 - asp.tightness).clamp(0.0, 1.0);
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Container(
          decoration: AppDecorations.cosmicCard(),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              childrenPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: col, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${svc.planet(x.a)} ${svc.aspect(x.asp)} ${svc.planet(x.b)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: bar,
                    minHeight: 4,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(col),
                  ),
                ),
              ),
              children: [
                Text(_texts[keyOf(x)] ?? '',
                    style:
                        AppTextStyles.bodyMd(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    final groups = <Widget>[];
    for (final th in themeOrder) {
      final items = ranked.where((x) => x.theme == th && pass(x)).toList();
      if (items.isEmpty) continue;
      groups.add(Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
        child: Text(t(context, 'match.theme.$th'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h3()),
      ));
      groups.addAll(items.map(card));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chips,
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: _infoCard(context, t(context, 'match.no_aspects')),
          )
        else
          ...groups,
      ],
    );
  }

  Widget _v2Top(MatchResult r, List<MatchAspect> all, bool note) {
    final w = _weighted(all);
    final themes = topThemes(w);
    final top = top3(w);
    final a = _prof(_profileA), b = _prof(_profileB);
    Widget col(_ProfileEntry? p, bool known) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p?.displayName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h3()),
              const SizedBox(height: AppSpacing.xs),
              _signCell(p?.sunId, true, p?.id),
              const SizedBox(height: AppSpacing.xs),
              _signCell(p?.moonId, known, p?.id),
              const SizedBox(height: AppSpacing.xs),
              _signCell(p?.ascId, known, p?.id),
            ],
          ),
        );
    final svc = ReferenceNamesService.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note) ...[
          _infoCard(context, t(context, 'match.time_unknown_note')),
          const SizedBox(height: AppSpacing.md),
        ],
        if (themes.isNotEmpty) ...[
          Text(
            themes.length == 2
                ? t(context, 'match.hero.two', args: {
                    'a': t(context, 'match.theme.${themes[0]}'),
                    'b': t(context, 'match.theme.${themes[1]}'),
                  })
                : t(context, 'match.theme.${themes[0]}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h1(),
          ),
          if (_heroLine(top).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(_heroLine(top),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style:
                    AppTextStyles.bodyMd(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        Container(
          decoration: AppDecorations.cosmicCard(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              col(a, r.timeKnownA),
              const SizedBox(width: AppSpacing.sm),
              col(b, r.timeKnownB),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(t(context, 'match.top3_title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h3()),
        const SizedBox(height: AppSpacing.sm),
        if (top.isEmpty)
          _infoCard(context, t(context, 'match.no_aspects'))
        else
          for (final x in top)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                decoration: AppDecorations.cosmicCard(),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${svc.planet(x.a)} ${svc.aspect(x.asp)} ${svc.planet(x.b)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLg(
                            color: AppColors.goldAccent)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                        _texts[MatchService.textKey(x.a, x.b, x.asp)] ?? '',
                        style: AppTextStyles.bodyMd(
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
