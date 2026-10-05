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
import '../services/match_service.dart';
import '../services/reference_names_service.dart';


class _ProfileEntry {
  final String id;
  final String displayName;
  final bool timeKnown;
  const _ProfileEntry({
    required this.id,
    required this.displayName,
    required this.timeKnown,
  });
}

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  List<_ProfileEntry> _profiles = const [];
  bool _profilesLoading = true;
  Object? _profilesError;
  String? _profileA;
  String? _profileB;

  bool _resultLoading = false;
  Object? _resultError;
  MatchResult? _result;
  final Map<String, MatchResult> _cache = {};

  @override
  void initState() {
    super.initState();
    _loadProfiles();
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
            .select('id,display_name,birth_time_known')
            .eq('user_id', uid);
      rows = List<Map<String, dynamic>>.from(r);
      }
      final list = <_ProfileEntry>[];
      for (final row in rows) {
        final id = row['id']?.toString();
        if (id == null) continue;
        list.add(
          _ProfileEntry(
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
      setState(() {
        _result = cached;
        _resultError = null;
        _resultLoading = false;
      });
      return;
    }
    setState(() {
      _resultLoading = true;
      _resultError = null;
      _result = null;
    });
    try {
      final r = await MatchService.fetch(a, b);
      if (!mounted) return;
      _cache[key] = r;
      setState(() {
        _result = r;
        _resultLoading = false;
      });
    } catch (e, st) {
      debugPrint('match fetch failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _resultError = e;
        _resultLoading = false;
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
    final aspects = r.aspects.take(40).toList();
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
                return _aspectRow(a, i == aspects.length - 1);
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

  Widget _aspectRow(MatchAspect a, bool isLast) {
    final svc = ReferenceNamesService.instance;
    final bA = svc.planet(a.bodyAId);
    final bB = svc.planet(a.bodyBId);
    final asp = svc.aspect(a.aspectTypeId);
    final tight = a.tightness < 0.25;
    final accent = tight ? AppColors.goldAccent : AppColors.textPrimary;
    final muted = tight ? AppColors.goldAccent : AppColors.textSecondary;
    final orbStr = a.orb.toStringAsFixed(1);
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: isLast ? AppSpacing.xs : 0,
      ),
      child: SizedBox(
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
            ],
          ),
        ),
      ),
    );
  }
}
