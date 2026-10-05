import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_decorations.dart';
import '../i18n/app_localizations.dart';
import '../providers/active_profile_provider.dart';
import '../providers/language_provider.dart';
import '../services/chart_persistence_service.dart';

class EditBirthTimePage extends StatefulWidget {
  final String profileId;
  const EditBirthTimePage({super.key, required this.profileId});

  @override
  State<EditBirthTimePage> createState() => _EditBirthTimePageState();
}

class _EditBirthTimePageState extends State<EditBirthTimePage> {
  TimeOfDay? _selectedTime;
  bool _isSaving = false;
  bool _hasError = false;

  String _t(String k) => AppLocalizations.of(context)?.translate(k) ?? k;

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _hasError = false;
      });
    }
  }

  Future<void> _save() async {
    final time = _selectedTime;
    if (time == null) return;
    setState(() {
      _isSaving = true;
      _hasError = false;
    });
    try {
      final locale = context.read<LanguageProvider>().locale.languageCode;
      await ChartPersistenceService.addBirthTime(
        profileId: widget.profileId,
        time: time,
        locale: locale,
      );
      if (!mounted) return;
      context.read<ActiveProfileProvider>().bump();
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('EditBirthTime save error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          _t('birth_time.title'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _t('birth_time.hint'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                onTap: _isSaving ? null : _pick,
                borderRadius: AppRadius.mdBr,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: AppDecorations.cosmicCard(),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: AppColors.violetPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _selectedTime == null
                              ? _t('birth_time.pick')
                              : _format(_selectedTime!),
                          style: TextStyle(
                            color: _selectedTime == null
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (_hasError) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: AppDecorations.errorBanner(),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.errorRed,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _t('birth_time.error'),
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              InkWell(
                onTap: (_selectedTime == null || _isSaving) ? null : _save,
                borderRadius: AppRadius.mdBr,
                child: Container(
                  height: AppSizes.ctaHeight,
                  decoration: AppDecorations.primaryCta(
                    disabled: _selectedTime == null || _isSaving,
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _t('birth_time.save'),
                            style: TextStyle(
                              color: (_selectedTime == null || _isSaving)
                                  ? AppColors.textDisabled
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
