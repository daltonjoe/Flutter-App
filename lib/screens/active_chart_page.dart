import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/app_localizations.dart';
import '../models/natal_chart_response.dart';
import '../presentation/widgets/components/cosmic_error_state.dart';
import '../presentation/widgets/components/cosmic_loader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  int _lastRevision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<ActiveProfileProvider>();
    final profileId = provider.activeProfileId;
    final revision = provider.revision;

    if (profileId == null) {
      if (!_redirectedToOnboarding) {
        _redirectToOnboarding();
      }
      return;
    }

    final revisionChanged = revision != _lastRevision;
    final profileChanged =
        profileId != _requestedProfileId && profileId != _loadedProfileId;
    if (profileChanged || revisionChanged) {
      _lastRevision = revision;
      _requestedProfileId = profileId;
      _load(profileId);
    }
  }

  void _redirectToOnboarding() {
    _redirectedToOnboarding = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/onboarding', (route) => false);
    });
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
      if (e is PostgrestException && e.code == 'PGRST116') {
        setState(() => _loadingProfileId = null);
        await _recoverMissingProfile();
        return;
      }
      setState(() {
        _loadingProfileId = null;
        _error = 'profile_switcher.error';
      });
    }
  }

  Future<void> _recoverMissingProfile() async {
    final provider = context.read<ActiveProfileProvider>();
    final user = Supabase.instance.client.auth.currentUser;
    String? firstId;
    if (user != null) {
      final rows = await Supabase.instance.client
          .from('user_profiles')
          .select('id')
          .eq('user_id', user.id)
          .order('created_at')
          .limit(1);
      if (rows.isNotEmpty) firstId = rows.first['id'] as String;
    }
    if (!mounted) return;
    if (firstId != null) {
      await provider.setActive(firstId);
    } else {
      await provider.clearActive();
    }
  }

  void _retry() {
    final provider = context.read<ActiveProfileProvider>();
    if (provider.activeProfileId != null) {
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
