// lib/widgets/navigation/nav_tour_overlay.dart
// K34 — İlk açılış navigasyon turu: sekmeleri sırayla tanıtır.
//
// Gezinme mantığı içermez: adım değişimini [onStep], bitişi [onDone] ile
// yukarı bildirir. Tur yalnızca bir kez gösterilir (bkz. [navTourSeen]).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';

/// Turun gösterildiğini işaretleyen SharedPreferences anahtarı.
const String kNavTourSeenKey = 'nav_tour_seen';

/// Pop-up altındaki "devam et" ipucu anahtarı.
const String _kTapHint = 'tour.tap_hint';

/// Tur daha önce gösterildi mi? Okuma hata verirse `true` döner, yani tur
/// gösterilmez.
Future<bool> navTourSeen() async {
  try {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(kNavTourSeenKey) ?? false;
  } catch (e) {
    debugPrint('nav tour seen read failed: $e');
    return true;
  }
}

/// Turu "görüldü" olarak işaretler.
Future<void> navTourMarkSeen() async {
  try {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(kNavTourSeenKey, true);
  } catch (e) {
    debugPrint('nav tour seen write failed: $e');
  }
}

/// Tek bir tur adımı: alt çubuktaki [slot] (görünür sekme sırası), başlık
/// (sekme etiketi) ve açıklama metni.
class NavTourStep {
  const NavTourStep({
    required this.slot,
    required this.title,
    required this.body,
  });

  final int slot;
  final String title;
  final String body;
}

/// Tüm ekranı karartıp seçili slotu boşluk bırakan tur katmanı.
///
/// Herhangi bir dokunuş sonraki adıma geçirir; atla/kapat düğmesi yoktur.
class NavTourOverlay extends StatefulWidget {
  const NavTourOverlay({
    super.key,
    required this.steps,
    required this.pillRect,
    required this.onStep,
    required this.onDone,
  });

  final List<NavTourStep> steps;

  /// Alt çubuk pilinin global (ekran) koordinatındaki dikdörtgeni.
  final Rect Function() pillRect;

  /// Adım değişiminde ilgili sekme indeksiyle çağrılır.
  final ValueChanged<int> onStep;

  /// Son adımda dokunulduğunda çağrılır.
  final VoidCallback onDone;

  @override
  State<NavTourOverlay> createState() => _NavTourOverlayState();
}

class _NavTourOverlayState extends State<NavTourOverlay> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // İlk adımın sekmesini aç; ardından pilin yerleşmiş geometrisiyle
      // yeniden çiz.
      widget.onStep(0);
      setState(() {});
    });
  }

  void _advance() {
    if (_i + 1 >= widget.steps.length) {
      widget.onDone();
      return;
    }
    setState(() => _i++);
    widget.onStep(_i);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_i];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppMotion.enter;

    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size ?? MediaQuery.sizeOf(context);
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;

    final pill = widget.pillRect().shift(-origin);
    final slotW = widget.steps.isEmpty ? 0.0 : pill.width / widget.steps.length;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final slotLeft = rtl
        ? pill.right - (step.slot + 1) * slotW
        : pill.left + step.slot * slotW;
    final hole = Rect.fromLTWH(slotLeft, pill.top, slotW, pill.height);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TourPainter(
                hole: hole,
                radius: const Radius.circular(AppRadius.xl),
                dimColor: AppColors.bgVoid.withValues(alpha: 0.78),
                ringColor: AppColors.gold,
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.screenH,
            right: AppSpacing.screenH,
            bottom: size.height - pill.top + 12,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: AnimatedSwitcher(
                  duration: duration,
                  switchInCurve: AppMotion.enterCurve,
                  child: Semantics(
                    key: ValueKey<int>(_i),
                    container: true,
                    liveRegion: true,
                    excludeSemantics: true,
                    label:
                        '${step.title}. ${step.body} ${t(context, _kTapHint)}',
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.navyDeep.withValues(alpha: 0.95),
                        border: Border.all(color: AppColors.hairline),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: AppTextStyles.h2(color: AppColors.starlight),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            step.body,
                            style: AppTextStyles.bodyMd(
                              color: AppColors.starlight,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            t(context, _kTapHint),
                            style: AppTextStyles.bodyXs(color: AppColors.mist),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ekranı karartıp seçili slotu boş bırakan, çevresine altın çerçeve çizen
/// ressam.
class _TourPainter extends CustomPainter {
  _TourPainter({
    required this.hole,
    required this.radius,
    required this.dimColor,
    required this.ringColor,
  });

  final Rect hole;
  final Radius radius;
  final Color dimColor;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(hole, radius);
    final screen = Path()..addRect(Offset.zero & size);
    final cutout = Path()..addRRect(rrect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, screen, cutout),
      Paint()..color = dimColor,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_TourPainter old) =>
      old.hole != hole ||
      old.radius != radius ||
      old.dimColor != dimColor ||
      old.ringColor != ringColor;
}
