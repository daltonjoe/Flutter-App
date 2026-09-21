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
  String? _error;
  ({NatalChartResponse chart, String name})? _result;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileId = context.watch<ActiveProfileProvider>().activeProfileId;
    if (profileId != _loadingProfileId && profileId != _loadedProfileId) {
      _load(profileId);
    }
  }

  Future<void> _load(String? profileId) async {
    if (profileId == null) {
      setState(() {
        _loadingProfileId = null;
        _loadedProfileId = null;
        _result = null;
        _error = 'profile_switcher.empty';
      });
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
    final profileId = context.watch<ActiveProfileProvider>().activeProfileId!;
    return ChartPage(
      key: ValueKey(profileId),
      chartData: result.chart,
      userName: result.name,
    );
  }
}
