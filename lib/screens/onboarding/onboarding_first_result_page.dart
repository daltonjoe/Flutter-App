import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_localizations.dart';
import '../../models/natal_chart_response.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../presentation/widgets/components/cosmic_error_state.dart';
import '../../presentation/widgets/components/cosmic_loader.dart';
import '../../providers/active_profile_provider.dart';
import '../../services/chart_repository.dart';

class OnboardingFirstResultPage extends StatefulWidget {
  const OnboardingFirstResultPage({super.key, required this.isFirstProfile});
  final bool isFirstProfile;

  @override
  State<OnboardingFirstResultPage> createState() =>
      _OnboardingFirstResultPageState();
}

class _OnboardingFirstResultPageState extends State<OnboardingFirstResultPage> {
  late Future<({NatalChartResponse chart, String name})> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<({NatalChartResponse chart, String name})> _load() {
    final id = context.read<ActiveProfileProvider>().activeProfileId;
    if (id == null) return Future.error('no_active_profile');
    return ChartRepository.load(id);
  }

  void _continue() {
    final u = Supabase.instance.client.auth.currentUser;
    final linked = u != null && !u.isAnonymous;
    if (!widget.isFirstProfile || linked) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding/link-account');
    }
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/logo/background.png',
                  fit: BoxFit.cover),
            ),
            SafeArea(
              child: FutureBuilder<({NatalChartResponse chart, String name})>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const CosmicLoader();
                  }
                  if (snap.hasError || snap.data == null) {
                    return CosmicErrorState(
                      message: t(context, 'profile_switcher.error'),
                      retryLabel: t(context, 'profile_switcher.retry'),
                      onRetry: () => setState(() => _future = _load()),
                    );
                  }
                  final s = snap.data!.chart.summary;
                  final timeKnown = (s?.ascendantSign ?? '').isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        Text(
                          t(context, 'onboarding.first_result.title'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        _row(t(context, 'onboarding.first_result.sun'),
                            s?.sunSign ?? ''),
                        if (timeKnown) ...[
                          _row(t(context, 'onboarding.first_result.moon'),
                              s?.moonSign ?? ''),
                          _row(t(context, 'onboarding.first_result.rising'),
                              s?.ascendantSign ?? ''),
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              t(context, 'onboarding.first_result.time_hint'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        const Spacer(),
                        CosmicCtaButton(
                          label: t(context, 'common.next'),
                          disabled: false,
                          onTap: _continue,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}