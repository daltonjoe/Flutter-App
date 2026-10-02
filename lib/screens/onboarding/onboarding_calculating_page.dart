import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_error_state.dart';

class OnboardingCalculatingPage extends StatefulWidget {
  const OnboardingCalculatingPage({
    super.key,
    required this.setupFactory,
    required this.isFirstProfile,
  });
  final Future<void> Function() setupFactory;
  final bool isFirstProfile;

  @override
  State<OnboardingCalculatingPage> createState() =>
      _OnboardingCalculatingPageState();
}

class _OnboardingCalculatingPageState extends State<OnboardingCalculatingPage> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      await Future.wait([
        widget.setupFactory(),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/onboarding/first-result',
        arguments: widget.isFirstProfile,
      );
    } catch (e, st) {
      debugPrint('Calculating setup error: $e\n$st');
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return PopScope(
      canPop: _failed,
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
              child: _failed
                  ? CosmicErrorState(
                      message: t(context, 'onboarding.chart_save_failed'),
                      retryLabel: t(context, 'profile_switcher.retry'),
                      onRetry: _retry,
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: Lottie.asset(
                              'assets/animations/Astrology.json',
                              animate: !reduce,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t(context, 'onboarding.calculating.title'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}