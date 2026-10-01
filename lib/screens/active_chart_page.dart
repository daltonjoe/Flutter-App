import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/app_localizations.dart';
import '../models/natal_chart_response.dart';
import '../presentation/widgets/components/cosmic_error_state.dart';
import '../presentation/widgets/components/cosmic_loader.dart';
import '../providers/active_profile_provider.dart';
import '../services/chart_repository.dart';
import 'chart_page.dart';

class ActiveChartPage extends StatefulWidget {
  const ActiveChartPage({super.key});

  @override
  State<ActiveChartPage> createState() => _ActiveChartPageState();
}

class _ActiveChartPageState extends State<ActiveChartPage> {
  static const String _pendingSetupKey = 'pending-setup';

  String? _loadedProfileId;
  String? _loadingProfileId;
  String? _requestedProfileId;
  String? _error;
  ({NatalChartResponse chart, String name})? _result;
  bool _redirectedToOnboarding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<ActiveProfileProvider>();
    final profileId = provider.activeProfileId;

    // pendingProfileSetup kontrolü artık activeProfileId'den BAĞIMSIZ —
    // ikinci+ profil eklerken activeProfileId zaten eski profile işaret
    // ediyor olabilir, bu yüzden null kontrolünden ÖNCE bakılmalı.
    if (provider.pendingProfileSetup != null) {
      if (_requestedProfileId != _pendingSetupKey) {
        _requestedProfileId = _pendingSetupKey;
        _runPendingSetup(provider);
      }
      return;
    }

    if (profileId == null) {
      if (!_redirectedToOnboarding) {
        _redirectToOnboarding();
      }
      return;
    }

    if (profileId != _requestedProfileId && profileId != _loadedProfileId) {
      _requestedProfileId = profileId;
      _load(profileId);
    }
  }

  void _redirectToOnboarding() {
    _redirectedToOnboarding = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/onboarding',
        (route) => false,
      );
    });
  }

  Future<void> _runPendingSetup(ActiveProfileProvider provider) async {
    setState(() {
      _loadingProfileId = _pendingSetupKey;
      _error = null;
      _result = null;
      _loadedProfileId = null;
    });
    try {
      await provider.pendingProfileSetup!();
      provider.pendingProfileSetup = null;
      if (!mounted) return;
      final newId = provider.activeProfileId;
      if (newId != null) {
        // didChangeDependencies'e güvenme: yüklemeyi burada açıkça başlat.
        _requestedProfileId = newId;
        await _load(newId);
      } else {
        setState(() {
          _loadingProfileId = null;
          _error = 'onboarding.chart_save_failed';
        });
      }
    } catch (e, st) {
      debugPrint('Pending setup error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadingProfileId = null;
        _error = 'onboarding.chart_save_failed';
      });
    }
  }

  Future<void> _load(String profileId) async {
    setState(() {
      _loadingProfileId = profileId;
      _error = null;
      _result = null;
      _loadedProfileId = null;
    });
    try {
      final result = await ChartRepository.load(profileId);
      if (!mounted || _loadingProfileId != profileId) return;
      setState(() {
        _result = result;
        _loadedProfileId = profileId;
        _loadingProfileId = null;
      });
    } catch (e, st) {
      debugPrint('ActiveChartPage load failed: ${e.runtimeType}: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingProfileId = null;
        _error = 'profile_switcher.error';
      });
    }
  }

  void _retry() {
    final provider = context.read<ActiveProfileProvider>();
    if (provider.pendingProfileSetup != null) {
      _requestedProfileId = null;
      _runPendingSetup(provider);
    } else if (provider.activeProfileId != null) {
      _load(provider.activeProfileId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfileId != null) return const CosmicLoader();
    if (_error != null) {
      return CosmicErrorState(
        message: t(context, _error!),
        retryLabel: t(context, 'profile_switcher.retry'),
        onRetry: _retry,
      );
    }
    final result = _result;
    if (result == null) return const CosmicLoader();
    final profileId = context.watch<ActiveProfileProvider>().activeProfileId;
    if (profileId == null) return const CosmicLoader();
    return ChartPage(
      key: ValueKey(profileId),
      chartData: result.chart,
      userName: result.name,
    );
  }
}