import 'package:flutter_application/paywall/paywall_page.dart';
import 'dart:ui' show ImageFilter, lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../i18n/app_localizations.dart';
import '../../models/natal_chart_response.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../presentation/widgets/components/cosmic_error_state.dart';
import '../../presentation/widgets/components/cosmic_loader.dart';
import '../../providers/active_profile_provider.dart';
import '../../services/chart_repository.dart';
import 'onboarding_first_question_page.dart';
import 'onboarding_memory_page.dart';

class OnboardingFirstResultPage extends StatefulWidget {
  const OnboardingFirstResultPage({super.key, required this.isFirstProfile});
  final bool isFirstProfile;

  @override
  State<OnboardingFirstResultPage> createState() =>
      _OnboardingFirstResultPageState();
}

class _OnboardingFirstResultPageState extends State<OnboardingFirstResultPage>
    with SingleTickerProviderStateMixin {
  late Future<({NatalChartResponse chart, String name})> _future;

  static const int _totalMs = 7400;
  late final AnimationController _scene;
  bool _hSun = false, _hMoon = false, _hRise = false;
  bool _timeKnown = true;
  String _sun = '';
  String _moon = '';

  @override
  void initState() {
    super.initState();
    _scene = AnimationController(
        vsync: this, duration: const Duration(milliseconds: _totalMs));
    _scene.addListener(_haptics);
    _future = _load();
    _play();
  }

  Future<({NatalChartResponse chart, String name})> _load() {
    final id = context.read<ActiveProfileProvider>().activeProfileId;
    if (id == null) return Future.error('no_active_profile');
    return ChartRepository.load(id);
  }

  @override
  void dispose() {
    _scene.dispose();
    super.dispose();
  }

  /// Veri yüklenince sahneyi başlatır (reduce motion: statik son durum).
  void _play() {
    _future.then((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _hSun = _hMoon = _hRise = true;
        _scene.value = 1;
      } else {
        _scene.forward(from: 0);
      }
    }, onError: (_) {});
  }

  void _haptics() {
    final ms = _scene.value * _totalMs;
    if (!_hSun && ms >= 400) {
      _hSun = true;
      HapticFeedback.lightImpact();
    }
    if (!_hMoon && ms >= 1400) {
      _hMoon = true;
      if (_timeKnown) HapticFeedback.lightImpact();
    }
    if (!_hRise && ms >= 2200) {
      _hRise = true;
      if (_timeKnown) HapticFeedback.mediumImpact();
    }
  }

  void _skip() {
    _hSun = _hMoon = _hRise = true;
    if (_scene.value < 1) _scene.value = 1;
  }

  Widget _at(int ms, Widget child, {int dur = 420}) {
    final a = ms / _totalMs;
    final b = (ms + dur) / _totalMs;
    return AnimatedBuilder(
      animation: _scene,
      child: child,
      builder: (context, child) {
        final v = AppMotion.enterCurve
            .transform(((_scene.value - a) / (b - a)).clamp(0.0, 1.0));
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
        );
      },
    );
  }

  void _continue() {
    if (!widget.isFirstProfile) {
      _afterAi();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingFirstQuestionPage(
          sunSign: _sun,
          moonSign: _moon,
          onDone: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => OnboardingMemoryPage(
                  onDone: () {
                    Navigator.of(context).pop();
                    _afterAi();
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _afterAi() async {
    if (widget.isFirstProfile) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("home_ask_invite_pending", true);
      } catch (e) {
        debugPrint("ask invite flag failed: $e");
      }
      if (!mounted) return;
    }
    final u = Supabase.instance.client.auth.currentUser;
    final linked = u != null && !u.isAnonymous;
    if (!widget.isFirstProfile || linked) {
      Navigator.of(context, rootNavigator: true)
    .pushNamedAndRemoveUntil('/home', (r) => false);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) => const PaywallPage(source: PaywallSource.onboarding, next: '/onboarding/link-account')));
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
        backgroundColor: AppColors.bgVoid,
        body: FutureBuilder<({NatalChartResponse chart, String name})>(
          future: _future,
          builder: (context, snap) {
            // Yükleme dalının arka planını CosmicLoader (video + poster)
            // sağlar; burada ayrıca görsel çizilmez (tek arka plan katmanı).
            if (snap.connectionState != ConnectionState.done) {
              return const CosmicLoader();
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _scene,
                    child: Image.asset('assets/images/logo/background.jpg',
                        fit: BoxFit.cover),
                    builder: (context, child) {
                      final p =
                          ((_scene.value * _totalMs - 3900) / 1400).clamp(0.0, 1.0);
                      final sigma =
                          lerpDouble(6, 0, Curves.easeOutQuart.transform(p))!;
                      if (sigma < 0.1) return child!;
                      return ImageFiltered(
                        imageFilter: ImageFilter.blur(
                            sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.mirror),
                        child: child,
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: snap.hasError || snap.data == null
                      ? CosmicErrorState(
                          message: t(context, 'profile_switcher.error'),
                          retryLabel: t(context, 'profile_switcher.retry'),
                          onRetry: () => setState(() {
                            _future = _load();
                            _play();
                          }),
                        )
                      : _summary(snap.data!.chart.summary),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summary(ChartSummary? summary) {
    final timeKnown = (summary?.ascendantSign ?? '').isNotEmpty;
    _timeKnown = timeKnown;
    _sun = summary?.sunSign ?? '';
    _moon = timeKnown ? (summary?.moonSign ?? '') : '';
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _skip,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            _at(
              0,
              Text(
                t(context, 'onboarding.first_result.title'),
                textAlign: TextAlign.center,
                style: tt.headlineSmall,
              ),
            ),
            const SizedBox(height: 24),
            _at(400,
                _row(t(context, 'onboarding.first_result.sun'), summary?.sunSign ?? '')),
            if (timeKnown) ...[
              _at(
                  1400,
                  _row(t(context, 'onboarding.first_result.moon'),
                      summary?.moonSign ?? '')),
              _at(
                  2200,
                  _row(t(context, 'onboarding.first_result.rising'),
                      summary?.ascendantSign ?? '')),
            ] else ...[
              _at(
                2200,
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: _row(
                      t(context, 'onboarding.first_result.rising'), '••••••'),
                ),
              ),
              _at(
                3000,
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    t(context, 'onboarding.first_result.time_hint'),
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            _at(
              5600,
              Text(
                t(context, 'onboarding.first_result.final1'),
                textAlign: TextAlign.center,
                style: tt.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            _at(
              6600,
              Text(
                t(context, 'onboarding.first_result.final2'),
                textAlign: TextAlign.center,
                style: tt.titleMedium,
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _scene,
              builder: (context, child) =>
                  IgnorePointer(ignoring: _scene.value < 7000 / _totalMs, child: child),
              child: _at(
                7000,
                CosmicCtaButton(
                  label: t(context, 'onboarding.first_result.cta'),
                  disabled: false,
                  onTap: _continue,
                ),
                dur: 400,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}