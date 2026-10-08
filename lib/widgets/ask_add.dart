import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../i18n/app_localizations.dart';
import '../models/ask_context.dart';
import '../providers/ask_context_provider.dart';
import '../providers/ask_draft.dart';
import '../screens/main_shell.dart' show shellTab;

/// Bağlamı ekler ve Ask sekmesine geçer. Üst sınırda snackbar, false döner.
bool addToAsk(BuildContext context, AskContext c) {
  final ok = askContext.add(c);
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t(context, 'ask.context.limit'))),
    );
    return false;
  }
  HapticFeedback.selectionClick();
  shellTab.value = kAskTab;
  return true;
}

/// Soruyu composer'a yazar (göndermez) ve Ask sekmesine geçer.
void askAbout(String question) {
  askDraft.value = question;
  HapticFeedback.selectionClick();
  shellTab.value = kAskTab;
}

/// tab_ai kapalıyken görünmez.
class AskAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AskAddButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: askEnabled,
      builder: (c, on, _) {
        if (!on) return const SizedBox.shrink();
        return TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.auto_awesome_outlined,
              size: 18, color: AppColors.violetPrimary),
          label: Text(t(c, 'ask.add')),
        );
      },
    );
  }
}