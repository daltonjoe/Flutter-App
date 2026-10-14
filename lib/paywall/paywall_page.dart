import "package:flutter/material.dart";
import "package:purchases_flutter/purchases_flutter.dart";
import "package:flutter_application/core/theme/app_colors.dart";
import "package:flutter_application/i18n/app_localizations.dart";
import "package:flutter_application/screens/legal_agreements_page.dart";
import "package:flutter_application/services/user_settings_service.dart";
import "paywall_service.dart";

enum PaywallSource { onboarding, quota, settings }

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key, required this.source, this.next});
  final PaywallSource source;
  final String? next;

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _loading = true;
  bool _busy = false;
  bool _yearlySel = true;
  String? _errKey;
  PaywallOffer? _offer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  String _t(String k) => t(context, k);

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
    });
  }

  int? _trialDays(Package? p) {
    final ip = p?.storeProduct.introductoryPrice;
    if (ip == null || ip.price != 0) return null;
    final n = ip.periodNumberOfUnits;
    switch (ip.periodUnit) {
      case PeriodUnit.day:
        return n;
      case PeriodUnit.week:
        return n * 7;
      case PeriodUnit.month:
        return n * 30;
      default:
        return null;
    }
  }

  Future<void> _buy() async {
    final p = _yearlySel ? _offer?.yearly : _offer?.monthly;
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
      MaterialPageRoute<void>(builder: (_) => LegalTextPage(titleKey: titleKey, bodyKey: bodyKey)),
    );
  }

  Widget _card({
    required bool sel,
    required String label,
    required String price,
    required VoidCallback onTap,
    String? sub,
    bool best = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: sel ? AppColors.textPrimary : AppColors.borderMedium,
              width: sel ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _busy ? null : onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 18, color: AppColors.textPrimary)),
                        if (sub != null)
                          Text(sub, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      price,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (best)
          Positioned(
            right: 12,
            top: -12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.amberTransit,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _t("paywall.plan.best"),
                style: const TextStyle(fontSize: 13, color: AppColors.bgDeep),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final y = _offer?.yearly;
    final m = _offer?.monthly;
    final yd = _trialDays(y);
    final md = _trialDays(m);
    final sel = _yearlySel ? y : m;
    final days = _yearlySel ? yd : md;
    final yPrice = y?.storeProduct.priceString ?? "-";
    final mPrice = m?.storeProduct.priceString ?? "-";
    final best = y != null && m != null && y.storeProduct.price < m.storeProduct.price * 12;
    final quota = widget.source == PaywallSource.quota;
    String title;
    if (days == null) {
      title = _t("paywall.plan.title.none");
    } else {
      title = _t(_yearlySel ? "paywall.plan.title.yearly" : "paywall.plan.title.monthly")
          .replaceAll("{days}", "$days");
    }
    String? commit;
    if (sel != null) {
      final price = sel.storeProduct.priceString;
      final base = _yearlySel ? "paywall.commit.yearly" : "paywall.commit.monthly";
      final key = days == null ? "${base}_paid" : base;
      commit = _t(key).replaceAll("{days}", "${days ?? 0}").replaceAll("{price}", price);
    }
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 190,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.violetDark, AppColors.bgDeep],
                    ),
                  ),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        iconSize: 28,
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        tooltip: _t("paywall.quota.close"),
                        onPressed: _busy ? null : _leave,
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (quota)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _t("paywall.quota.title"),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 32),
                      _card(
                        sel: _yearlySel,
                        label: _t("paywall.plan.yearly"),
                        sub: yd == null ? null : _t("paywall.plan.free_days").replaceAll("{days}", "$yd"),
                        price: _t("paywall.plan.per_year").replaceAll("{price}", yPrice),
                        best: best,
                        onTap: () => setState(() => _yearlySel = true),
                      ),
                      const SizedBox(height: 18),
                      _card(
                        sel: !_yearlySel,
                        label: _t("paywall.plan.monthly"),
                        sub: md == null ? null : _t("paywall.plan.free_days").replaceAll("{days}", "$md"),
                        price: _t("paywall.plan.per_month").replaceAll("{price}", mPrice),
                        onTap: () => setState(() => _yearlySel = false),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                        onPressed: _busy ? null : _buy,
                        child: _busy
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_t("paywall.cta.continue")),
                      ),
                      if (_errKey != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _t(_errKey!),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.errorRed),
                          ),
                        ),
                      if (commit != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            commit,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                            onPressed: _busy ? null : _restore,
                            child: Text(_t("paywall.restore")),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                            onPressed: () => _legal("settings.privacy.terms", "legal.terms.body"),
                            child: Text(_t("settings.privacy.terms")),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                            onPressed: () => _legal("settings.privacy.policy", "legal.privacy.body"),
                            child: Text(_t("settings.privacy.policy")),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
