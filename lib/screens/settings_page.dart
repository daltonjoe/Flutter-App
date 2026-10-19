import 'dart:async';
import 'active_chart_page.dart' show signingOut74;
import 'package:flutter_application/paywall/subscription_settings_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../presentation/widgets/components/cosmic_card.dart';
import '../presentation/widgets/components/cosmic_error_state.dart';
import '../presentation/widgets/components/overline_text.dart';
import '../providers/active_profile_provider.dart';
import "package:flutter_application/diag68.dart";
import 'legal_agreements_page.dart';
import '../providers/language_provider.dart';
import '../services/account_deletion_service.dart';
import '../services/user_settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final AnimationController _holdDelete;

  bool _isLoading = true;
  String? _loadError;
  UserSettings? _settings;
  bool _notificationsFlagEnabled = false;

  String? _appVersion;

  bool _deleting = false;
  bool _holdTriggered = false;
  bool _showConfirmForA11y = false;
  StreamSubscription<AuthState>? _authSub66;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _holdDelete = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _holdDelete.addListener(_onHoldTick);
    _authSub66 = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
    _loadAll();
  }

  @override
  void dispose() {
    _authSub66?.cancel();
    _holdDelete.removeListener(_onHoldTick);
    _animController.dispose();
    _holdDelete.dispose();
    super.dispose();
  }

  void _onHoldTick() {
    if (!_holdTriggered && _holdDelete.status == AnimationStatus.completed) {
      _holdTriggered = true;
      HapticFeedback.heavyImpact();
      _runAccountDelete();
    }
  }

  void _onHoldDown() {
    if (_deleting) return;
    _holdTriggered = false;
    _holdDelete.forward();
  }

  void _onHoldUp() {
    if (_holdDelete.status == AnimationStatus.completed) return;
    _holdDelete.stop();
    _holdDelete.animateBack(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  Future<void> _runAccountDelete() async {
    if (!mounted) return;
    setState(() => _deleting = true);
    try {
      await AccountDeletionService.deleteAccount();
      if (!mounted) return;
      await context.read<ActiveProfileProvider>().clearActive();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/onboarding',
        (route) => false,
        arguments: {'isFirstProfile': true},
      );
    } catch (e) {
      debugPrint('SettingsPage._runAccountDelete failed: $e');
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _holdTriggered = false;
        _showConfirmForA11y = false;
      });
      _holdDelete.value = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, 'settings.danger.error'))),
      );
    }
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
        _settings =
            results[0] as UserSettings? ??
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

  Widget _sectionLabel(String key, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: OverlineText(t(context, key), color: color),
    );
  }

  Widget _wrapSectionEntrance({required int index, required Widget child}) {
    final curves = [0.0, 0.10, 0.22, 0.35, 0.45];
    final start = curves[index.clamp(0, curves.length - 1)];
    final end = (start + 0.50).clamp(0.0, 1.0);
    final Animation<double> fade = CurvedAnimation(
      parent: _animController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(opacity: fade, child: child);
  }

  Widget _skeleton({double height = 56, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.navyRaised,
        borderRadius: AppRadius.mdBr,
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.contentTop,
        AppSpacing.screenH,
        AppSizes.scrollBottomPadding(context),
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
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: CosmicCard(child: _skeleton(height: 48)),
        ),
        _sectionLabel('settings.danger.title', color: AppColors.statusDanger),
        CosmicCard(child: _skeleton(height: 48)),
      ],
    );
  }

  Widget _buildRow({
    IconData? icon,
    required Widget leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool enabled = true,
    double minHeight = 48,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadius.cardBr,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight.toDouble()),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.mist),
                const SizedBox(width: AppSpacing.cardGap),
              ],
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
                    icon: Icons.notifications_none,
                    leading: Text(
                      t(context, 'settings.notifications.enabled'),
                      style: AppTextStyles.bodyLg(color: AppColors.starlight),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Switch(
                      value: enabled,
                      onChanged: (v) => _onNotificationsChanged(v),
                      activeThumbColor: AppColors.onGold,
                      activeTrackColor: AppColors.gold,
                      inactiveThumbColor: AppColors.navyRaised,
                      inactiveTrackColor: AppColors.hairline,
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.hairline),
                  _buildRow(
                    icon: Icons.schedule_outlined,
                    enabled: enabled,
                    onTap: enabled ? _pickTime : null,
                    leading: Text(
                      t(context, 'settings.notifications.time'),
                      style: AppTextStyles.bodyLg(
                        color: enabled
                            ? AppColors.starlight
                            : AppColors.mist.withValues(alpha: 0.5),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      displayTime,
                      style: AppTextStyles.bodyMd(
                        color: enabled
                            ? AppColors.gold
                            : AppColors.mist.withValues(alpha: 0.5),
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
                style: AppTextStyles.bodyXs(color: AppColors.mist),
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
      // Aynı kök neden: yerel navigator'da açılınca kaydet butonu alt
      // navigasyon çubuğunun altında kalıyordu.
      useRootNavigator: true,
      backgroundColor: AppColors.navyDeep,
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
                          color: AppColors.starlight,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: DateTime(
                        2000,
                        1,
                        1,
                        initial.hour,
                        initial.minute,
                      ),
                      backgroundColor: AppColors.navyDeep,
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
                      color: AppColors.gold,
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
                icon: Icons.language,
                leading: Text(
                  t(context, 'settings.language.title'),
                  style: AppTextStyles.bodyLg(color: AppColors.starlight),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentEntry['label']!,
                      style: AppTextStyles.bodyMd(color: AppColors.gold),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                      color: AppColors.mist,
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
      // Alt navigasyon çubuğunun üstünde açılsın: yerel navigator'da açıldığında
      // listenin en alttaki dilleri çubuğun altında kalıp seçilemiyordu.
      useRootNavigator: true,
      backgroundColor: AppColors.navyDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
                                  ? AppColors.gold
                                  : AppColors.starlight,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: AppColors.gold),
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

  Future<void> _signOut() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(ctx, "settings.account.signout")),
        content: Text(t(ctx, "settings.account.signout_body")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(ctx, "notes.cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t(ctx, "settings.account.signout")),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    final prov = context.read<ActiveProfileProvider>();
    try {
      signingOut74 = true;
      diag68("signout before");
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      await Supabase.instance.client.auth.signInAnonymously();
      diag68("signout after-anon");
      diag68("signout pre-clear");
      await prov.clearActive();
      diag68("signout post-clear");
      final sp = await SharedPreferences.getInstance();
      await sp.remove("force_consent");
      nav.pushNamedAndRemoveUntil("/onboarding/link-account", (route) => false);
      debugPrint("signout: link-account pushed");
    } catch (e) {
      signingOut74 = false;
      debugPrint("SettingsPage._signOut failed: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(context, "ask.error"))));
    }
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
              child: Column(
                children: [
                  _buildRow(
                    icon: Icons.person_outline,
                    leading: Text(
                      statusText,
                      style: AppTextStyles.bodyMd(color: AppColors.mist),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                  if (!isAnonymous)
                    _buildRow(
                      icon: Icons.logout,
                      leading: Text(
                        t(context, "settings.account.signout"),
                        style: AppTextStyles.bodyLg(color: AppColors.starlight),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      onTap: _signOut,
                    ),
                ],
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('settings.section.privacy'),
            CosmicCard(
              child: _buildRow(
                icon: Icons.description_outlined,
                leading: Text(
                  t(context, 'settings.legal.row'),
                  style: AppTextStyles.bodyLg(color: AppColors.starlight),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LegalAgreementsPage(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _sectionLabel('settings.section.about'),
            const SubscriptionSettingsRow(),
            CosmicCard(
              child: _buildRow(
                icon: Icons.info_outline,
                leading: Text(
                  t(context, 'settings.about.version'),
                  style: AppTextStyles.bodyLg(color: AppColors.starlight),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                trailing: Text(
                  _appVersion ?? '',
                  style: AppTextStyles.bodyMd(color: AppColors.mist),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dangerSection() {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    return _wrapSectionEntrance(
      index: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('settings.danger.title', color: AppColors.statusDanger),
          CosmicCard(
            borderColor: AppColors.statusDanger.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    t(context, 'settings.danger.warning'),
                    style: AppTextStyles.bodySm(color: AppColors.mist),
                    softWrap: true,
                  ),
                ),
                if (disableAnimations)
                  _buildA11yDeleteButtons()
                else
                  _buildHoldDeleteButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldDeleteButton() {
    return IgnorePointer(
      ignoring: _deleting,
      child: Listener(
        onPointerDown: (_) => _onHoldDown(),
        onPointerUp: (_) => _onHoldUp(),
        onPointerCancel: (_) => _onHoldUp(),
        child: AnimatedBuilder(
          animation: _holdDelete,
          builder: (_, fillW) {
            final progress = _holdDelete.value;
            return SizedBox(
              width: double.infinity,
              height: AppSizes.ctaHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.statusDanger.withValues(alpha: 0.12),
                        borderRadius: AppRadius.pillBr,
                        border: Border.all(
                          color: AppColors.statusDanger.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  if (progress > 0)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: AppRadius.pillBr,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress,
                            heightFactor: 1,
                            child: const ColoredBox(
                              color: AppColors.statusDanger,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: _deleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.starlight,
                                ),
                              ),
                            )
                          : Text(
                              t(context, 'settings.danger.hold'),
                              style: AppTextStyles.ctaSecondary(
                                color: Color.lerp(
                                  AppColors.statusDanger,
                                  AppColors.starlight,
                                  progress,
                                )!,
                              ).copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildA11yDeleteButtons() {
    return Column(
      children: [
        if (!_showConfirmForA11y)
          SizedBox(
            width: double.infinity,
            height: AppSizes.ctaHeight,
            child: OutlinedButton(
              onPressed: _deleting
                  ? null
                  : () => setState(() => _showConfirmForA11y = true),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.statusDanger.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
                disabledForegroundColor: AppColors.mist.withValues(alpha: 0.5),
              ),
              child: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.starlight,
                        ),
                      ),
                    )
                  : Text(
                      t(context, 'settings.danger.delete_account'),
                      style: AppTextStyles.ctaSecondary(
                        color: AppColors.statusDanger,
                      ).copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        if (_showConfirmForA11y)
          SizedBox(
            width: double.infinity,
            height: AppSizes.ctaHeight,
            child: ElevatedButton(
              onPressed: _deleting ? null : _runAccountDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusDanger,
                disabledBackgroundColor: AppColors.navyRaised,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
                elevation: 0,
              ),
              child: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.starlight,
                        ),
                      ),
                    )
                  : Text(
                      t(context, 'settings.danger.confirm'),
                      style: AppTextStyles.ctaPrimary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
      ],
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
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.contentTop,
                AppSpacing.screenH,
                AppSizes.scrollBottomPadding(context),
              ),
              children: [
                _notificationsSection(),
                _languageSection(),
                _accountSection(),
                _aboutSection(),
                _dangerSection(),
              ],
            ),
    );
  }
}
