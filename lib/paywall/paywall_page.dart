import 'package:flutter/material.dart';
import 'package:flutter_application/i18n/app_localizations.dart';
import 'package:flutter_application/services/user_settings_service.dart';
import 'entitlement_service.dart';

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
  bool _error = false;
  bool _loadFailed = false;
  EntitlementState _ent = EntitlementState.none;

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
      on = await UserSettingsService.isFlagEnabled('paywall');
    } catch (e) {
      debugPrint('paywall flag error: $e');
    }
    if (!mounted) return;
    if (!on) {
      _leave();
      return;
    }
    try {
      final s = await EntitlementService.load();
      if (!mounted) return;
      if (widget.source == PaywallSource.onboarding && s.hasRecord) {
        _leave();
        return;
      }
      setState(() {
        _ent = s;
        _loading = false;
        _loadFailed = false;
      });
    } catch (e) {
      debugPrint('paywall entitlement error: $e');
      if (!mounted) return;
      if (widget.source == PaywallSource.onboarding) {
        _leave();
        return;
      }
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      await EntitlementService.startTrial();
      if (!mounted) return;
      if (widget.next != null) {
        _leave();
        return;
      }
      final s = await EntitlementService.load();
      if (!mounted) return;
      setState(() {
        _ent = s;
        _busy = false;
      });
    } catch (e) {
      debugPrint('paywall start error: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = true;
      });
    }
  }

  Widget _p(String s, {TextStyle? style}) =>
      Text(s, textAlign: TextAlign.center, style: style);

  Widget _shell(List<Widget> children) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _canStart => !_ent.hasRecord;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final quota = widget.source == PaywallSource.quota;
    final canStart = _canStart;
    final closeBtn = TextButton(
      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: _busy ? null : _leave,
      child: Text(_t(quota || !canStart ? 'paywall.quota.close' : 'paywall.trial.skip')),
    );

    if (_loadFailed) {
      return _shell([
        _p(_t('paywall.error.generic'), style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () {
            setState(() => _loading = true);
            _init();
          },
          child: Text(_t('paywall.error.retry')),
        ),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _leave,
          child: Text(_t('paywall.quota.close')),
        ),
      ]);
    }

    final ends = _ent.expiresAt ?? DateTime.now().add(const Duration(days: 7));
    final dateStr = MaterialLocalizations.of(context).formatMediumDate(ends);
    final String title = quota
        ? _t('paywall.quota.title')
        : (canStart ? _t('paywall.trial.title') : _t('paywall.settings.row'));

    final body = <Widget>[];
    if (quota) body.add(_p(_t('paywall.quota.body')));
    if (canStart) {
      body.add(_p(_t('paywall.trial.body')));
      body.add(_p(_t('paywall.trial.ends').replaceAll('{date}', dateStr)));
      body.add(_p(_t('paywall.trial.nocharge')));
      body.add(_p(_t('paywall.trial.cancel')));
    } else {
      final key = _ent.trialActive ? 'paywall.settings.trial_active' : 'paywall.settings.expired';
      body.add(_p(_t(key).replaceAll('{date}', dateStr)));
      if (_ent.trialActive) body.add(_p(_t('paywall.trial.body')));
    }
    if (_error) {
      body.add(_p(_t('paywall.error.generic'), style: TextStyle(color: theme.colorScheme.error)));
    }

    return _shell([
      _p(title, style: theme.textTheme.headlineSmall),
      const SizedBox(height: 16),
      for (final w in body) Padding(padding: const EdgeInsets.only(bottom: 12), child: w),
      const SizedBox(height: 12),
      if (canStart)
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _busy ? null : _start,
          child: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_t(_error ? 'paywall.error.retry' : 'paywall.trial.cta')),
        ),
      closeBtn,
    ]);
  }
}