import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  void _showLanguageMenu(
    BuildContext context,
    LanguageProvider provider,
  ) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final String? selectedCode = await showMenu<String>(
      context: context,
      position: position,
      color: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.violet.withOpacity(0.2)),
      ),
      constraints: const BoxConstraints(maxHeight: 320), // CHANGE 1
      items: LanguageProvider.supportedLanguages.map((lang) {
        final isSelected = provider.locale.languageCode == lang['code'];
        return PopupMenuItem<String>(
          value: lang['code'],
          height: 48,
          child: Directionality(
            textDirection: TextDirection.ltr, // CHANGE 2
            child: Row(
              children: [
                Text(lang['flag']!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Text(
                  lang['label']!,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    // CHANGE 3
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB07BFF),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );

    if (selectedCode != null && selectedCode != provider.locale.languageCode) {
      provider.setLocale(selectedCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LanguageProvider>(context);
    final currentLang = LanguageProvider.supportedLanguages.firstWhere(
      (l) => l['code'] == provider.locale.languageCode,
      orElse: () => LanguageProvider.supportedLanguages.first,
    );

    return IgnorePointer(
      ignoring: provider.isLoading, // CHANGE 4
      child: GestureDetector(
        onTap: () => _showLanguageMenu(context, provider),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.bgCard.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.violet.withOpacity(0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.violet.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                size: 16,
                color: AppTheme.violet.withOpacity(0.9),
              ),
              const SizedBox(width: 8),
              Text(
                currentLang['code']!.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
