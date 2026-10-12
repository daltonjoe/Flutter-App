import 'package:flutter/material.dart';
import 'package:flutter_application/i18n/app_localizations.dart';
import 'package:flutter_application/services/user_settings_service.dart';
import 'entitlement_service.dart';
import 'paywall_page.dart';

class SubscriptionSettingsRow extends StatefulWidget {
  const SubscriptionSettingsRow({super.key});

  @override
  State<SubscriptionSettingsRow> createState() => _SubscriptionSettingsRowState();
}

class _SubscriptionSettingsRowState extends State<SubscriptionSettingsRow> {
  bool _on = false;
  EntitlementState _ent = EntitlementState.none;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var on = false;
    var ent = EntitlementState.none;
    try {
      on = await UserSettingsService.isFlagEnabled('paywall');
      if (on) ent = await EntitlementService.load();
    } catch (e) {
      debugPrint('subscription row error: $e');
    }
    if (!mounted) return;
    setState(() {
      _on = on;
      _ent = ent;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_on) return const SizedBox.shrink();
    final ends = _ent.expiresAt;
    final dateStr = ends == null ? '' : MaterialLocalizations.of(context).formatMediumDate(ends);
    final String sub = (_ent.trialActive && ends != null)
        ? t(context, 'paywall.settings.trial_active').replaceAll('{date}', dateStr)
        : ((_ent.trialEnded && ends != null)
            ? t(context, 'paywall.settings.expired').replaceAll('{date}', dateStr)
            : t(context, 'paywall.settings.none'));
    return ListTile(
      title: Text(t(context, 'paywall.settings.row')),
      subtitle: Text(sub),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            builder: (_) => const PaywallPage(source: PaywallSource.settings),
          ),
        );
        if (!mounted) return;
        _load();
      },
    );
  }
}