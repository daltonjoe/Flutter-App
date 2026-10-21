import 'package:flutter_application/paywall/paywall_page.dart';
import 'dart:math' as math;
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

const String _fr = 'onboarding.first_result.';
const List<String> _signKeys = [
  'aries',
  'taurus',
  'gemini',
  'cancer',
  'leo',
  'virgo',
  'libra',
  'scorpio',
  'sagittarius',
  'capricorn',
  'aquarius',
  'pisces',
];

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

  static const int _totalMs = 7200;
  static const int _msSun = 400;
  static const int _msMoon = 2000;
  static const int _msRise = 3600;
  static const int _msHint = 4400;
  static const int _msFinal = 6000;
  static const int _msCta = 6800;
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

  /// Veri yuklenince sahneyi baslatir (reduce motion: statik son durum).
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
    if (!_hSun && ms >= _msSun) {
      _hSun = true;
      HapticFeedback.lightImpact();
    }
    if (!_hMoon && ms >= _msMoon) {
      _hMoon = true;
      if (_timeKnown) HapticFeedback.lightImpact();
    }
    if (!_hRise && ms >= _msRise) {
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
        builder: (_) => OnboardingMemoryPage(
          onDone: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => OnboardingFirstQuestionPage(
                  sunSign: _sun,
                  moonSign: _moon,
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

  /// Burc adini (yerel ya da Ingilizce) sabit anahtara cevirir; bulunamazsa null.
  String? _signKey(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    for (final k in _signKeys) {
      if (s == k) return k;
      if (s == t(context, 'signs.$k').trim().toLowerCase()) return k;
    }
    return null;
  }

  Widget _block(String labelKey, String whatKey, String sign) {
    final tt = Theme.of(context).textTheme;
    final k = _signKey(sign);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Text(
            t(context, labelKey),
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 4),
          Text(sign, textAlign: TextAlign.center, style: tt.headlineSmall),
          const SizedBox(height: 6),
          Text(t(context, whatKey),
              textAlign: TextAlign.center, style: tt.bodyMedium),
          if (k != null) ...[
            const SizedBox(height: 4),
            Text(
              t(context, '${_fr}trait_$k'),
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: AppColors.starlight),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgVoid,
        body: FutureBuilder<({NatalChartResponse chart, String name})>(
          future: _future,
          builder: (context, snap) {
            // Yukleme dalinin arka planini CosmicLoader (video + poster)
            // saglar; burada ayrica gorsel cizilmez (tek arka plan katmani).
            if (snap.connectionState != ConnectionState.done) {
              return const CosmicLoader();
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _scene,
                    child: RepaintBoundary(child: Image.asset('assets/images/logo/background.jpg', fit: BoxFit.cover)),
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _OrbitPainter(_scene, timeKnown, _totalMs),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, cs) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: cs.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _at(
                              0,
                              Text(
                                t(context, '${_fr}title'),
                                textAlign: TextAlign.center,
                                style: tt.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _at(_msSun,
                                _block('${_fr}sun', '${_fr}what_sun', _sun)),
                            if (timeKnown) ...[
                              _at(_msMoon,
                                  _block('${_fr}moon', '${_fr}what_moon', _moon)),
                              _at(
                                  _msRise,
                                  _block('${_fr}rising', '${_fr}what_rising',
                                      summary?.ascendantSign ?? '')),
                            ] else ...[
                              _at(
                                _msRise,
                                ImageFiltered(
                                  imageFilter:
                                      ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                  child: Column(
                                    children: [
                                      Text(
                                        t(context, '${_fr}rising'),
                                        textAlign: TextAlign.center,
                                        style: tt.bodyMedium
                                            ?.copyWith(color: AppColors.gold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\u2022\u2022\u2022\u2022\u2022\u2022',
                                        textAlign: TextAlign.center,
                                        style: tt.headlineSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _at(
                                _msHint,
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    t(context, '${_fr}time_hint'),
                                    textAlign: TextAlign.center,
                                    style: tt.bodyMedium,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _at(
                              _msFinal,
                              Text(
                                t(context, '${_fr}final_angles'),
                                textAlign: TextAlign.center,
                                style: tt.titleMedium,
                              ),
                              dur: 600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _scene,
                  builder: (context, child) => IgnorePointer(
                      ignoring: _scene.value < _msCta / _totalMs, child: child),
                  child: _at(
                    _msCta,
                    CosmicCtaButton(
                      label: t(context, '${_fr}cta'),
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
        ],
      ),
    );
  }
}

/// Arka plan: sirayla beliren altin halkalar ve yorungede donen noktalar.
class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.scene, this.timeKnown, this.totalMs)
      : super(repaint: scene);
  final Animation<double> scene;
  final bool timeKnown;
  final int totalMs;

  @override
  void paint(Canvas canvas, Size size) {
    final ms = scene.value * totalMs;
    final c = size.center(Offset.zero);
    final base = size.shortestSide * 0.5;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dot = Paint();
    final n = timeKnown ? 3 : 1;
    for (var i = 0; i < n; i++) {
      final p = ((ms - (200 + i * 1600)) / 1200).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final e = Curves.easeOutCubic.transform(p);
      final r = base * (0.5 + 0.22 * i) * e;
      ring.color = AppColors.gold.withValues(alpha: 0.2 * e);
      canvas.drawCircle(c, r, ring);
      final a = i * 2.1 + ms / 1000 * 0.5;
      final pos = c + Offset(math.cos(a), math.sin(a)) * r;
      dot.color = AppColors.gold.withValues(alpha: 0.25 * e);
      canvas.drawCircle(pos, 9, dot);
      dot.color = AppColors.gold.withValues(alpha: 0.9 * e);
      canvas.drawCircle(pos, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) =>
      old.timeKnown != timeKnown || old.totalMs != totalMs;
}