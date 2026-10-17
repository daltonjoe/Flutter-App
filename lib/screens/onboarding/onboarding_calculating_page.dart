import 'package:flutter/material.dart';
import '../../presentation/widgets/components/cosmic_loader.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_error_state.dart';
import '../../core/theme/app_colors.dart';
import '../../redesign/splash/loading_video.dart';

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
    return PopScope(
      canPop: _failed,
      child: Scaffold(
        backgroundColor: AppColors.bgDeep,
        // Video arka planı CosmicLoader sağlar (tek controller).
        body: _failed
            ? Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(child: LoadingVideo()),
                  SafeArea(
                    child: CosmicErrorState(
                      message: t(context, 'onboarding.chart_save_failed'),
                      retryLabel: t(context, 'profile_switcher.retry'),
                      onRetry: _retry,
                    ),
                  ),
                ],
              )
            : const CosmicLoader(),
      ),
    );
  }
}
