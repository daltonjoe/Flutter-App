import "package:flutter/material.dart";
import "package:flutter_application/core/theme/app_colors.dart";
import "package:flutter_application/core/theme/app_gradients.dart";
import "package:flutter_application/core/theme/app_dimensions.dart";
import "package:flutter_application/core/theme/app_typography.dart";
import "package:flutter_application/core/theme/app_shadows.dart";
import "package:flutter_application/i18n/app_localizations.dart";
import "package:flutter_application/screens/legal_agreements_page.dart";
import "package:flutter_application/services/user_settings_service.dart";
import "package:purchases_flutter/purchases_flutter.dart";
import "paywall_service.dart";
import '../presentation/widgets/components/cosmic_loader.dart';

enum PaywallSource { onboarding, quota, settings }

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key, required this.source, this.next});
  final PaywallSource source;
  final String? next;

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _busy = false;
  int _selIdx = 0; // 0: Yearly, 1: Monthly
  String? _errKey;
  PaywallOffer? _offer;

  /// Yıllık plan seçiliyken "Tasarruf Et" rozetini parıldatıp büyüten sürücü.
  late final AnimationController _badgeCtrl;

  @override
  void initState() {
    super.initState();
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBadgeAnimation();
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    super.dispose();
  }

  /// Rozet animasyonunu yalnızca yıllık plan seçiliyken ve
  /// "hareketi azalt" tercihi kapalıyken çalıştırır.
  void _syncBadgeAnimation() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_selIdx == 0 && !reduceMotion) {
      if (!_badgeCtrl.isAnimating) _badgeCtrl.repeat(reverse: true);
    } else {
      _badgeCtrl.stop();
      _badgeCtrl.value = 0;
    }
  }

  void _selectPlan(int index) {
    if (_selIdx == index) return;
    setState(() => _selIdx = index);
    _syncBadgeAnimation();
  }

  String _t(String k, {Map<String, String>? args}) {
    String res = t(context, k);
    if (args != null) {
      args.forEach((key, value) {
        res = res.replaceAll("{$key}", value);
      });
    }
    return res;
  }

  void _leave() {
    final nav = Navigator.of(context);
    final n = widget.next;
    if (n != null) {
      nav.pushReplacementNamed(n);
    } else {
      nav.maybePop();
    }
  }

  Future<void> _init() async {
    var on = false;
    try {
      on = await UserSettingsService.isFlagEnabled("paywall");
    } catch (e) {
      debugPrint("paywall flag error: $e");
    }
    if (!mounted) return;
    if (!on) {
      _leave();
      return;
    }
    var pro = false;
    PaywallOffer? offer;
    try {
      pro = await PaywallService.hasPro();
      if (!pro) offer = await PaywallService.loadOffer();
    } catch (e) {
      debugPrint("paywall load error: $e");
    }
    if (!mounted) return;
    if (pro && widget.source == PaywallSource.onboarding) {
      _leave();
      return;
    }
    setState(() {
      _offer = offer;
      _loading = false;
      if (offer?.yearly == null && offer?.monthly != null) _selIdx = 1;
    });
  }

  Future<void> _buy() async {
    final p = _selIdx == 0
        ? _offer?.yearly : _offer?.monthly;
    if (p == null) {
      setState(() => _errKey = "paywall.unavailable");
      return;
    }
    setState(() {
      _busy = true;
      _errKey = null;
    });
    try {
      final done = await PaywallService.buyPackage(p);
      if (!mounted) return;
      if (done) {
        _leave();
        return;
      }
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errKey = "paywall.error.purchase";
      });
    }
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _errKey = null;
    });
    try {
      final ok = await PaywallService.restore();
      if (!mounted) return;
      if (ok) {
        _leave();
        return;
      }
      setState(() {
        _busy = false;
        _errKey = "paywall.restore.none";
      });
    } catch (e) {
      debugPrint("paywall restore error: $e");
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errKey = "paywall.unavailable";
      });
    }
  }

  void _legal(String titleKey, String bodyKey) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalTextPage(titleKey: titleKey, bodyKey: bodyKey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CosmicLoadingScreen();
    }

    final y = _offer?.yearly;
    final m = _offer?.monthly;
    final int? yd = y == null ? null : _trialDays(y.storeProduct);
    final int? md = m == null ? null : _trialDays(m.storeProduct);
    final String? yPriceStr = y?.storeProduct.priceString;
    final String? mPriceStr = m?.storeProduct.priceString;
    final int? discount = (y != null && m != null && m.storeProduct.price > 0)
        ? ((1 - (y.storeProduct.price / 12) / m.storeProduct.price) * 100).round()
        : null;
    final bool hasSel = _selIdx == 0 ? y != null : m != null;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.mist),
            onPressed: _busy ? null : _leave,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _t(widget.source == PaywallSource.onboarding ? "paywall.title_onboarding" : "paywall.title"),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h1(
                                color: AppColors.starlight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _t("paywall.subtitle"),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd(color: AppColors.mist),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 18, color: AppColors.gold),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _t("paywall.feature"),
                                    style: AppTextStyles.bodySm(color: AppColors.starlight),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            if (y != null)
                              _buildPlanCard(
                                index: 0,
                                label: _t("paywall.plan.yearly"),
                                trial: yd == null
                                    ? null
                                    : _t("paywall.trial_days", args: {"days": "$yd"}),
                                price: _t("paywall.plan.per_year", args: {"price": yPriceStr!}),
                                discount: (discount != null && discount > 0) ? discount : null,
                              ),
                            if (y != null && m != null)
                              const SizedBox(height: AppSpacing.md),
                            if (m != null)
                              _buildPlanCard(
                                index: 1,
                                label: _t("paywall.plan.monthly"),
                                trial: md == null
                                    ? null
                                    : _t("paywall.trial_days", args: {"days": "$md"}),
                                price: _t("paywall.plan.per_month", args: {"price": mPriceStr!}),
                              ),
                            
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  if (_errKey != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _t(_errKey!),
                        style: const TextStyle(color: AppColors.statusDanger),
                      ),
                    ),
                  Text(
                    hasSel
                        ? _commitText(
                            _selIdx == 0 ? yd : md,
                            (_selIdx == 0 ? yPriceStr : mPriceStr) ?? "",
                          )
                        : _t("paywall.unavailable"),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm(color: AppColors.mist),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildCtaButton(
                    enabled: hasSel,
                    days: hasSel ? (_selIdx == 0 ? yd : md) : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildFooterLinks(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mağaza paketinin ücretsiz deneme süresi (gün); teklif yoksa null.
  /// iOS: tanıtım teklifi (fiyat 0); Android: ücretsiz faz. Yalnız PnD ve PnW çözülür.
  int? _trialDays(StoreProduct p) {
    String? iso;
    int cycles = 1;
    final intro = p.introductoryPrice;
    if (intro != null && intro.price == 0) {
      iso = intro.period;
      cycles = intro.cycles;
    } else {
      final free = p.defaultOption?.freePhase;
      iso = free?.billingPeriod?.iso8601;
      cycles = free?.billingCycleCount ?? 1;
    }
    if (iso == null || cycles < 1) return null;
    final m = RegExp(r'^P(\d+)([DW])$').firstMatch(iso);
    if (m == null) return null;
    final n = int.parse(m.group(1)!);
    final days = m.group(2) == 'W' ? n * 7 : n;
    return days * cycles;
  }

  String _commitText(int? days, String price) {
    final yearly = _selIdx == 0;
    if (days == null) {
      final paid = _t(
        yearly ? "paywall.commit.yearly_paid" : "paywall.commit.monthly_paid",
        args: {"price": price},
      );
      return "$paid\n${_t("paywall.cancel_anytime")}";
    }
    final key = yearly ? "paywall.commit.yearly" : "paywall.commit.monthly";
    final end = MaterialLocalizations.of(context)
        .formatMediumDate(DateTime.now().add(Duration(days: days)));
    final head = _t(key, args: {"days": "$days", "price": price});
    final ends = _t("paywall.trial.ends", args: {"date": end});
    return "$head\n$ends ${_t("paywall.cancel_anytime")}";
  }

  Widget _buildPlanCard({
    required int index,
    required String label,
    required String price,
    String? trial,
    int? discount,
  }) {
    final bool isSel = _selIdx == index;
    return GestureDetector(
      onTap: () => _selectPlan(index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.navyDeep,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSel ? AppColors.gold : AppColors.borderSubtle,
                width: isSel ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (trial != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            trial,
                            style: AppTextStyles.bodyXs(
                              color: AppColors.mist,
                            ).copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      Text(
                        label,
                        style: AppTextStyles.h3(color: AppColors.starlight),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: AppTextStyles.bodyMd(
                    color: AppColors.starlight,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.md),
                _buildRadio(isSel),
              ],
            ),
          ),
          if (discount != null)
            PositionedDirectional(start: 16, top: -12, child: _buildSaveBadge(discount)),
        ],
      ),
    );
  }

  /// Yıllık plan seçiliyken parıldayan ve büyüyen "Tasarruf Et" rozeti.
  /// Seçili değilken ya da "hareketi azalt" açıkken sabit görünür.
  Widget _buildSaveBadge(int discount) {
    final bool active = _selIdx == 0;
    return AnimatedBuilder(
      animation: _badgeCtrl,
      builder: (context, child) {
        final double v = active ? _badgeCtrl.value : 0.0;
        return Transform.scale(
          scale: 1.0 + 0.08 * v,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: active ? null : AppColors.gold,
              gradient: active
                  ? LinearGradient(
                      begin: Alignment(-1.5 + 3.0 * v, -1.0),
                      end: Alignment(-0.5 + 3.0 * v, 1.0),
                      colors: const [
                        AppColors.gold,
                        AppColors.roseSoft,
                        AppColors.gold,
                      ],
                      stops: const [0.25, 0.5, 0.75],
                    )
                  : null,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(
                    alpha: 0.30 + 0.40 * v,
                  ),
                  blurRadius: 8 + 14 * v,
                  spreadRadius: 3.0 * v,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Text(
        _t("paywall.save_badge", args: {"percent": "$discount"}),
        style: AppTextStyles.bodyXs(
          color: Colors.white,
        ).copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRadio(bool sel) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: sel ? AppColors.gold : Colors.transparent,
        border: Border.all(
          color: sel ? AppColors.gold : AppColors.mist,
          width: 2,
        ),
      ),
      child: sel
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }

  Widget _buildCtaButton({required bool enabled, int? days}) {
    final String label = days == null
        ? _t("paywall.cta_continue")
        : _t("paywall.cta_trial_days", args: {"days": "$days"});

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
      width: double.infinity,
      height: AppSizes.ctaHeight,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryCta,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.violetGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: (_busy || !enabled) ? null : _buy,
          child: Center(
            child: _busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(label, style: AppTextStyles.ctaPrimary),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _link(
          _t("settings.privacy.policy"),
          () => _legal("settings.privacy.policy", "legal.privacy.body"),
        ),
        _dot(),
        _link(_t("paywall.restore"), _restore),
        _dot(),
        _link(
          _t("settings.privacy.terms"),
          () => _legal("settings.privacy.terms", "legal.terms.body"),
        ),
      ],
    );
  }

  Widget _link(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: AppTextStyles.bodySm(color: AppColors.mist),
      ),
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text("•", style: TextStyle(color: AppColors.mist)),
    );
  }
}
