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
  String? _loadedProfileId;
  String? _loadingProfileId;
  String? _requestedProfileId;
  String? _error;
  ({NatalChartResponse chart, String name})? _result;
  bool _redirectedToOnboarding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileId = context.watch<ActiveProfileProvider>().activeProfileId;
    if (profileId == null) {
      if (!_redirectedToOnboarding) {
        _load(null);
      }
      return;
    }
    if (profileId != _requestedProfileId && profileId != _loadedProfileId) {
      _requestedProfileId = profileId;
      _load(profileId);
    }
  }

  Future<void> _load(String? profileId) async {
    if (profileId == null) {
      if (!_redirectedToOnboarding) {
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
      return;
    }
    setState(() {
      _loadingProfileId = profileId;
      _error = null;
      _result = null;
      _loadedProfileId = null;
    });
    try {
      debugPrint('LOAD profile=$profileId');
      final result = await ChartRepository.load(profileId);
      if (!mounted || _loadingProfileId != profileId) {
        return;
      }
      setState(() {
        _result = result;
        _loadedProfileId = profileId;
        _loadingProfileId = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProfileId = null;
        _error = 'profile_switcher.error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfileId != null) return const CosmicLoader();
    if (_error != null) {
      final profileId = context.watch<ActiveProfileProvider>().activeProfileId;
      return CosmicErrorState(
        message: t(context, _error!),
        retryLabel: t(context, 'profile_switcher.retry'),
        onRetry: () => _load(profileId),
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
