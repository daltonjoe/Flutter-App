import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../presentation/widgets/components/cosmic_card.dart';
import '../presentation/widgets/components/cosmic_error_state.dart';
import '../providers/language_provider.dart';
import '../services/user_settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  bool _isLoading = true;
  String? _loadError;
  UserSettings? _settings;
  bool _notificationsFlagEnabled = false;

  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _loadAll();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        UserSettingsService.load(),
        UserSettingsService.isFlagEnabled('settings_notifications'),
        PackageInfo.fromPlatform(),
      ]);
      if (!mounted) return;
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      setState(() {
        _settings = results[0] as UserSettings? ??
            UserSettings(
              notificationTime: null,
              notificationsEnabled: false,
              currentTimezone: null,
            );
        _notificationsFlagEnabled = results[1] as bool;
        final info = results[2] as PackageInfo;
        _appVersion = '${info.version} (${info.buildNumber})';
        _isLoading = false;
      });
      if (disableAnimations) {
        _animController.value = 1;
      } else {
        _animController.forward();
      }
    } catch (e) {
      debugPrint('SettingsPage._loadAll failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = t(context, 'settings.error.load');
      });
    }
  }

  Widget _sectionLabel(String key) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        t(context, key).toUpperCase(),
        style: AppTextStyles.fieldLabel(color: AppColors.textMuted),
      ),
    );
  }

  Widget _wrapSectionEntrance({required int index, required Widget child}) {
    final curves = [0.0, 0.10, 0.22, 0.35];
    final start = curves[index.clamp(0, curves.length - 1)];
    final end = (start + 0.50).clamp(0.0, 1.0);
    final Animation<double> fade = CurvedAnimation(
      parent: _animController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    final Animation<Offset> slide = Tween<Offset>(
      begin: const Offset(0, 12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ));
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  Widget _skeleton({double height = 56, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.mdBr,
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.contentTop,
        AppSpacing.screenH,
        AppSpacing.contentBottom,
      ),
      children: [
        _sectionLabel('settings.section.notifications'),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: CosmicCard(
            child: Column(
              children: [
                _skeleton(height: 48),
                const SizedBox(height: AppSpacing.md),
                _skeleton(height: 48),
                const SizedBox(height: AppSpacing.md),
                _skeleton(height: 16, width: double.infinity),
              ],
            ),
          ),
        ),
        _sectionLabel('settings.section.language'),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: CosmicCard(child: _skeleton(height: 48)),
        ),
        _sectionLabel('settings.section.account'),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: CosmicCard(child: _skeleton(height: 48)),
        ),
        _sectionLabel('settings.section.about'),
        CosmicCard(child: _skeleton(height: 48)),
      ],
    );
  }

  Widget _buildRow({
    required Widget leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool enabled = true,
    double minHeight = 48,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadius.mdBr,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight.toDouble()),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: leading),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationsSection() {
    if (!_notificationsFlagEnabled) return const SizedBox.shrink();
    final settings = _settings!;
    final enabled = settings.notificationsEnabled;
    final displayTime = settings.notificationTime ?? '09:00';

    return _wrapSectionEntrance(
      index: 0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('settings.section.notifications'),
            CosmicCard(
              child: Column(
                children: [
                  _buildRow(
                                      leading: Text(
                      t(context, 'settings.notifications.enabled'),
                      style: AppTextStyles.bodyLg(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Switch(
                      value: enabled,
                      onChanged: (v) => _onNotificationsChanged(v),
                      activeThumbColor: AppColors.violetPrimary,
                      activeTrackColor: AppColors.violetDark,
                      inactiveThumbColor: AppColors.bgSurfaceBright,
                      inactiveTrackColor: AppColors.bgSurfaceLow,
                    ),
                  ),
                  const Divider(
                    height: 1,
                    color: AppColors.borderSubtle,
                  ),
                  _buildRow(
                    enabled: enabled,
                    onTap: enabled ? _pickTime : null,
                     leading: Text(
                      t(context, 'settings.notifications.time'),
                      style: AppTextStyles.bodyLg(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      displayTime,
                      style: AppTextStyles.bodyMd(
                        color: enabled
                            ? AppColors.violetPrimary
                            : AppColors.textDisabled,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                t(context, 'settings.notifications.note'),
                style: AppTextStyles.bodyXs(color: AppColors.textMuted),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onNotificationsChanged(bool value) async {
    HapticFeedback.selectionClick();
    final previous = _settings!.notificationsEnabled;
    setState(() {
      _settings = _settings!.copyWith(notificationsEnabled: value);
    });
    try {
      await UserSettingsService.save(notificationsEnabled: value);
    } catch (e) {
      debugPrint('save notificationsEnabled failed: $e');
      if (!mounted) return;
      setState(() {
        _settings = _settings!.copyWith(notificationsEnabled: previous);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, 'settings.error.save'))),
      );
    }
  }

  Future<void> _pickTime() async {
    final initialParts = (_settings!.notificationTime ?? '09:00').split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(initialParts[0]) ?? 9,
      minute: int.tryParse(initialParts[1]) ?? 0,
    );
    TimeOfDay? picked = initial;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 180,
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: DateTime(
                        2000, 1, 1, initial.hour, initial.minute,
                      ),
                      backgroundColor: AppColors.bgCard,
                      onDateTimeChanged: (dt) {
                        picked = TimeOfDay(hour: dt.hour, minute: dt.minute);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.ctaHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.violetPrimary,
                      borderRadius: AppRadius.mdBr,
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        t(context, 'settings.save'),
                        style: AppTextStyles.ctaPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || picked == null || !mounted) return;
    final hh = picked!.hour.toString().padLeft(2, '0');
    final mm = picked!.minute.toString().padLeft(2, '0');
    final newTime = '$hh:$mm';
    final prevTime = _settings!.notificationTime;
    setState(() {
      _settings = _settings!.copyWith(notificationTime: newTime);
    });
    try {
      await UserSettingsService.save(notificationTime: newTime);
    } catch (e) {
      debugPrint('save notificationTime failed: $e');
      if (!mounted) return;
      setState(() {
        _settings = _settings!.copyWith(notificationTime: prevTime);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, 'settings.error.save'))),
      );
    }
  }

  Widget _languageSection() {
    final languageProvider = context.watch<LanguageProvider>();
    final current = languageProvider.locale.languageCode;
    final currentEntry = LanguageProvider.supportedLanguages.firstWhere(
      (l) => l['code'] == current,
      orElse: () => LanguageProvider.supportedLanguages.first,
    );

    return _wrapSectionEntrance(
      index: 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('settings.section.language'),
            CosmicCard(
              onTap: _showLanguageSheet,
              child: _buildRow(
                leading: Text(
                  t(context, 'settings.language.title'),
                  style: AppTextStyles.bodyLg(color: AppColors.textPrimary),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentEntry['label']!,
                      style: AppTextStyles.bodyMd(
                        color: AppColors.violetPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textMuted,
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

  void _showLanguageSheet() {
    final languageProvider = context.read<LanguageProvider>();
    final currentCode = languageProvider.locale.languageCode;

    final languagesWithoutArabic = LanguageProvider.supportedLanguages
        .where((l) => l['code'] != 'ar')
        .toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: languagesWithoutArabic.map((lang) {
                final selected = lang['code'] == currentCode;
                return InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await languageProvider.setLocale(lang['code']!);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang['label']!,
                            style: AppTextStyles.bodyLg(
                              color: selected
                                  ? AppColors.violetPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.violetPrimary,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _accountSection() {
    final user = Supabase.instance.client.auth.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;
    final email = user?.email;

    String statusText;
    if (isAnonymous) {
      statusText = t(context, 'settings.account.anonymous');
    } else {
      statusText = t(context, 'settings.account.linked');
      if (email != null && email.isNotEmpty) {
        statusText = '$statusText  •  $email';
      }
    }

    return _wrapSectionEntrance(
      index: 2,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('settings.section.account'),
            CosmicCard(
              child: _buildRow(
                 leading: Text(
                  statusText,
                  style: AppTextStyles.bodyMd(color: AppColors.textSecondary),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutSection() {
    return _wrapSectionEntrance(
      index: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('settings.section.about'),
          CosmicCard(
            child: _buildRow(
              leading: Text(
                t(context, 'settings.about.version'),
                style: AppTextStyles.bodyLg(color: AppColors.textPrimary),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              trailing: Text(
                _appVersion ?? '',
                style: AppTextStyles.bodyMd(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'settings.title'))),
      body: _isLoading
          ? _buildSkeleton()
          : _loadError != null
          ? Center(
              child: CosmicErrorState(
                message: _loadError!,
                onRetry: _loadAll,
                retryLabel: t(context, 'settings.retry'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.contentTop,
                AppSpacing.screenH,
                AppSpacing.contentBottom,
              ),
              children: [
                _notificationsSection(),
                _languageSection(),
                _accountSection(),
                _aboutSection(),
              ],
            ),
    );
  }
}

// MISSING TOKENS: skeleton/placeholder color (used AppColors.bgSurface), explicit minTapHeight constant (inline 48dp), dedicated section-divider token
