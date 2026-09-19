import 'package:flutter/material.dart';
import 'cosmic_cta_button.dart';

class CosmicAlertAction {
  final String label;
  final bool primary;
  final VoidCallback? onTap;
  const CosmicAlertAction({required this.label, this.primary = true, this.onTap});
}

Future<void> showCosmicAlert(
  BuildContext context, {
  required String message,
  required List<CosmicAlertAction> actions,
  String? title,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'alert',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final slide = CurvedAnimation(
          parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      final fade = CurvedAnimation(parent: anim, curve: const Interval(0.4, 1.0));
      // daire -> yuvarlatılmış kare
      final radius = 150 - 126 * Curves.easeInOut.transform(anim.value);

      return SlideTransition(
        position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(slide),
        child: FadeTransition(
          opacity: anim,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4A1519), Color(0xFF2A0B10)],
                      ),
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                          color: const Color(0xFFE53935).withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.35),
                            blurRadius: 24)
                      ],
                    ),
                    child: FadeTransition(
                      opacity: fade,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/images/logo/logo.png', height: 56),
                            const SizedBox(height: 16),
                            if (title != null) ...[
                              Text(title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                            ],
                            Text(message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white70, height: 1.4)),
                            const SizedBox(height: 20),
                            for (final a in actions)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: a.primary
                                    ? CosmicCtaButton(
                                        label: a.label,
                                        gradient: const LinearGradient(colors: [
                                          Color(0xFFE53935),
                                          Color(0xFFB71C1C)
                                        ]),
                                        onTap: () {
                                          Navigator.of(ctx).pop();
                                          a.onTap?.call();
                                        },
                                      )
                                    : TextButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          a.onTap?.call();
                                        },
                                        child: Text(a.label,
                                            style: const TextStyle(
                                                color: Colors.white70)),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}