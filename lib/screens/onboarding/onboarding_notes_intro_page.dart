// lib/screens/onboarding/onboarding_notes_intro_page.dart
// S10d — Notlarım tanıtımı: sohbette üretilen notların salt görsel kopyası (K30).
// Yalnızca ilk profilde gösterilir; Supabase'e bağlanmaz, veri yazmaz.

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../notes_page.dart';

const String _kCaption = 'onboarding.notes_intro.caption';
const String _kCta = 'onboarding.chat.close.continue';

/// S10d: sohbet bitince Notlarım ekranının canlı görünümlü, etkileşimsiz
/// kopyasını gösterir. Devam edince hesaplama adımına geçilir.
class OnboardingNotesIntroPage extends StatefulWidget {
  const OnboardingNotesIntroPage({
    super.key,
    required this.notes,
    required this.onDone,
  });

  /// Sohbette üretilen not metinleri (kayıt sırasıyla).
  final List<String> notes;

  /// CTA'ya basılınca çağrılır.
  final VoidCallback onDone;

  @override
  State<OnboardingNotesIntroPage> createState() =>
      _OnboardingNotesIntroPageState();
}

class _OnboardingNotesIntroPageState extends State<OnboardingNotesIntroPage> {
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce ? Duration.zero : AppMotion.enter;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t(context, 'notes.title')),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  '${widget.notes.length}/10',
                  style: AppTextStyles.bodyMd(),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  t(context, _kCaption),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd(color: AppColors.mist),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _reveal(
                    duration: duration,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.notes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (c, i) => NotesRowCard(
                            body: widget.notes[i],
                            onEdit: () {},
                            onDelete: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                CosmicCtaButton(label: t(context, _kCta), onTap: widget.onDone),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kopya fade 0→1 + ~24 px yukarı kayma ile girer; reduce motion'da anında.
  Widget _reveal({required Duration duration, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: AppMotion.enterCurve,
      builder: (context, value, inner) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 24),
          child: inner,
        ),
      ),
      child: child,
    );
  }
}
