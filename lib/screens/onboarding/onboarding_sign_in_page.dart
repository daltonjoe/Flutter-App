import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_application/paywall/paywall_service.dart";
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import '../../core/constants/auth_redirect.dart';
import "../../core/theme/app_borders.dart";
import "../../core/theme/app_colors.dart";
import "../../core/theme/app_decorations.dart";
import "../../core/theme/app_dimensions.dart";
import "../../core/theme/app_typography.dart";
import "../../i18n/app_localizations.dart";
import "../../providers/active_profile_provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../../main.dart" show showNotFound70;

class OnboardingSignInPage extends StatefulWidget {
  const OnboardingSignInPage({super.key});

  @override
  State<OnboardingSignInPage> createState() => _OnboardingSignInPageState();
}

class _OnboardingSignInPageState extends State<OnboardingSignInPage> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  StreamSubscription<AuthState>? _sub;
  bool _busy = false;
  bool _err = false;
  bool _done = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((s) {
      final u = s.session?.user;
      if (u == null || u.isAnonymous) return;
      _after();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _after() async {
    if (_done || !mounted) return;
    _done = true;
    final prov = context.read<ActiveProfileProvider>();
    final nav = Navigator.of(context, rootNavigator: true);
    String? pid;
    try {
      final rows = await Supabase.instance.client
          .from("user_profiles")
          .select("id")
          .order("created_at")
          .limit(1);
      if (rows.isNotEmpty) pid = rows.first["id"] as String;
    } catch (e) {
      debugPrint("signin profile lookup failed: $e");
      _done = false;
      if (mounted) setState(() => _err = true);
      return;
    }
    if (pid == null) {
      var empty70 = true;
      try {
        final cons70 = await Supabase.instance.client
            .from("user_consents")
            .select("kind")
            .limit(1);
        empty70 = cons70.isEmpty;
      } catch (e) {
        debugPrint("signin consent lookup failed: $e");
        _done = false;
        if (mounted) setState(() => _err = true);
        return;
      }
      if (empty70) {
        await prov.clearActive();
        if (!mounted) return;
        await showNotFound70(context);
        return;
      }
    }
    if (pid != null) {
      await prov.setActive(pid);
    } else {
      await prov.clearActive();
    }
    try {
      await PaywallService.init();
    } catch (e) {
      debugPrint("paywall init failed: $e");
    }
    if (pid == null) {
      nav.pushNamedAndRemoveUntil(
        "/onboarding",
        (r) => false,
        arguments: {"isFirstProfile": true},
      );
    } else {
      nav.pushNamedAndRemoveUntil("/onboarding/consent", (r) => false);
    }
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _err = false;
    });
    try {
      await f();
    } catch (e) {
      debugPrint("signin failed: $e");
      if (mounted) setState(() => _err = true);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _signIn() async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: _email.text.trim(),
      password: _pw.text,
    );
    await _after();
  }

  Future<void> _saveGuest84(SharedPreferences sp) async {
    try {
      final c = Supabase.instance.client;
      final tok = c.auth.currentSession?.refreshToken;
      if (c.auth.currentUser?.isAnonymous == true && tok != null) {
        await sp.setString("guest_refresh", tok);
      } else {
        await sp.remove("guest_refresh");
      }
    } catch (e) {
      debugPrint("guest save failed: $e");
    }
  }

  Future<void> _oauth(OAuthProvider p) async {
    final sp70 = await SharedPreferences.getInstance();
    await sp70.setString("auth_intent", "signin");
    await _saveGuest84(sp70);
    await Supabase.instance.client.auth.signInWithOAuth(
      p,
      redirectTo: kAuthRedirectUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Ekrana özgü ortak ölçüler (tek yerden ayarlanır) ────────────────
    final double kControlHeight = AppSizes.ctaHeight;
    final double kFormInset = AppSpacing.lg;
    final double kFormPaddingH = AppSpacing.screenH + kFormInset;

    final scaffold = Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.starlight),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(top: kToolbarHeight),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - kToolbarHeight).clamp(
                      0.0,
                      double.infinity,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: kFormPaddingH,
                        right: kFormPaddingH,
                        bottom: AppSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            t(context, "auth.signin.title"),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heroTitle(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            t(context, "auth.signin.description"),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMd(
                              color: AppColors.mist,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            height: kControlHeight,
                            child: TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTextStyles.bodyLg(
                                color: AppColors.starlight,
                              ),
                              decoration: _fieldDecoration(
                                hint: t(
                                  context,
                                  "onboarding.link_account.email_label",
                                ),
                                icon: Icons.mail_outline,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: kControlHeight,
                            child: TextField(
                              controller: _pw,
                              obscureText: _obscure,
                              style: AppTextStyles.bodyLg(
                                color: AppColors.starlight,
                              ),
                              decoration: _fieldDecoration(
                                hint: t(
                                  context,
                                  "onboarding.link_account.password_label",
                                ),
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.mist,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                          ),
                          if (_err) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              t(context, "auth.signin.error"),
                              style: AppTextStyles.bodyMd(
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                          // Alanlar arası ve alan→buton dikey boşlukları eşitlendi.
                          const SizedBox(height: AppSpacing.md),
                          _buildPrimaryCta(context, kControlHeight),
                          const SizedBox(height: AppSpacing.lg),
                          _buildOrDivider(context),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialButton(
                                  height: kControlHeight,
                                  leading: const Icon(
                                    Icons.apple,
                                    size: 22,
                                    color: AppColors.starlight,
                                  ),
                                  label: t(
                                    context,
                                    "onboarding.link_account.apple_button",
                                  ),
                                  onTap: _busy
                                      ? null
                                      : () => _run(
                                          () => _oauth(OAuthProvider.apple),
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildSocialButton(
                                  height: kControlHeight,
                                  leading: _buildGoogleLogo(),
                                  label: t(
                                    context,
                                    "onboarding.link_account.google_button",
                                  ),
                                  onTap: _busy
                                      ? null
                                      : () => _run(
                                          () => _oauth(OAuthProvider.google),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/logo/background.jpg',
            fit: BoxFit.cover,
          ),
        ),
        scaffold,
      ],
    );
  }

  // ── Görsel yardımcılar (davranış içermez) ──────────────────────────────

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMd(color: AppColors.mist),
      prefixIcon: Icon(icon, color: AppColors.mist),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.bgSurface,
      // Yükseklik kControlHeight ile sabitlendiği için dikey dolgu bırakılmaz;
      // böylece içerik (ikon + metin) 58px içinde ortalanır ve alanın görsel
      // yüksekliği CTA ile birebir aynı olur.
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.inputPaddingH,
      ),
      border: AppBorders.inputDefault().copyWith(
        borderRadius: AppRadius.pillBr,
      ),
      enabledBorder: AppBorders.inputDefault().copyWith(
        borderRadius: AppRadius.pillBr,
      ),
      focusedBorder: AppBorders.inputFocused().copyWith(
        borderRadius: AppRadius.pillBr,
      ),
    );
  }

  Widget _buildPrimaryCta(BuildContext context, double height) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: AppDecorations.primaryCta(
          disabled: _busy,
        ).copyWith(borderRadius: AppRadius.pillBr),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.pillBr,
          child: InkWell(
            borderRadius: AppRadius.pillBr,
            onTap: _busy ? null : () => _run(_signIn),
            child: Center(
              child: Text(
                t(context, "auth.signin.button"),
                style: AppTextStyles.ctaPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.borderSubtle, height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            t(context, "onboarding.link_account.or_divider"),
            style: AppTextStyles.bodyXs(color: AppColors.mist),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.borderSubtle, height: 1),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required double height,
    required Widget leading,
    required String label,
    required VoidCallback? onTap,
  }) {
    final bool disabled = onTap == null;
    return SizedBox(
      height: height,
      child: Material(
        color: AppColors.navyDeep,
        borderRadius: AppRadius.pillBr,
        child: InkWell(
          borderRadius: AppRadius.pillBr,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.pillBr,
              border: Border.all(color: AppColors.borderMedium),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: AppTextStyles.ctaSecondary(
                        color: disabled
                            ? AppColors.textDisabled
                            : AppColors.starlight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return Image.asset(
      'assets/images/logo/google_logo.png',
      width: 20,
      height: 20,
      errorBuilder: (context, error, stackTrace) =>
          const SizedBox(width: 20, height: 20),
    );
  }
}

/// 90: snackbar Sign in dogrudan Google girisi baslatir (sayfa acilmaz).
Future<void> startOAuthSignin90(OAuthProvider p) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setString("auth_intent", "signin");
  try {
    final c = Supabase.instance.client;
    final tok = c.auth.currentSession?.refreshToken;
    if (c.auth.currentUser?.isAnonymous == true && tok != null) {
      await sp.setString("guest_refresh", tok);
    } else {
      await sp.remove("guest_refresh");
    }
  } catch (e) {
    debugPrint("guest save failed: $e");
  }
  await Supabase.instance.client.auth.signInWithOAuth(
    p,
    redirectTo: kAuthRedirectUrl,
  );
}
