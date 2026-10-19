import "dart:async";
import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:url_launcher/url_launcher.dart";
import "../../core/constants/legal_links.dart";
import "../../core/theme/app_colors.dart";
import "../../core/theme/app_dimensions.dart";
import "../../core/theme/app_gradients.dart";
import "../../core/theme/app_typography.dart";
import "../../i18n/app_localizations.dart";
import "../../presentation/widgets/components/social_auth_button.dart";
import "../../services/account_linking_service.dart";

class OnboardingRegisterPage extends StatefulWidget {
  const OnboardingRegisterPage({super.key});

  @override
  State<OnboardingRegisterPage> createState() => _OnboardingRegisterPageState();
}

class _OnboardingRegisterPageState extends State<OnboardingRegisterPage> {
  StreamSubscription<AuthState>? _sub;
  bool _busy = false;
  bool _went = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
    });
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((s) {
      final u = s.session?.user;
      if (u == null || u.isAnonymous) return;
      _next();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _next() {
    if (_went || !mounted) return;
    _went = true;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil("/onboarding/consent", (r) => false);
  }

  Future<void> _oauth(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      debugPrint("register oauth failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t(
                context,
                (e is AuthException &&
                        (e.message.toLowerCase().contains("already linked") ||
                            e.message.contains("identity_already_exists")))
                    ? "onboarding.register.exists"
                    : "ask.error",
              ),
            ),
          ),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _contact() async {
    if (kSupportEmail.isEmpty) return;
    try {
      await launchUrl(Uri(scheme: "mailto", path: kSupportEmail));
    } catch (e) {
      debugPrint("mailto failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = AppTextStyles.bodyMd(color: AppColors.starlight).copyWith(
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.bold,
    );
    final subtitle = AppTextStyles.bodyMd(color: AppColors.mist);
    final plain = AppTextStyles.bodyMd(color: AppColors.mist);
    final btn = TextButton.styleFrom(minimumSize: const Size(48, 48));
    final double hPad = AppSpacing.screenH + AppSpacing.lg;
    return Scaffold(
      // Arka plan "Giriş yap" ekranıyla birebir aynı.
      backgroundColor: AppColors.bgDeep,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.heroHeader),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: hPad,
                        right: hPad,
                        bottom: AppSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            t(context, "onboarding.register.title"),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heroTitle(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            t(context, "onboarding.register.subtitle"),
                            textAlign: TextAlign.center,
                            style: subtitle,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SocialAuthButton(
                            leading: const Icon(
                              Icons.mail_outline,
                              size: 22,
                              color: AppColors.starlight,
                            ),
                            label: t(context, "onboarding.register.email"),
                            onTap: _busy
                                ? null
                                : () => Navigator.pushNamed(
                                    context,
                                    "/onboarding/email",
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SocialAuthButton(
                            leading: const GoogleLogoMark(),
                            label: t(context, "onboarding.register.google"),
                            onTap: _busy
                                ? null
                                : () =>
                                      _oauth(AccountLinkingService.linkGoogle),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SocialAuthButton(
                            leading: const Icon(
                              Icons.apple,
                              size: 22,
                              color: AppColors.starlight,
                            ),
                            label: t(context, "onboarding.register.apple"),
                            onTap: _busy
                                ? null
                                : () => _oauth(AccountLinkingService.linkApple),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: _busy ? null : _next,
                            child: Text(
                              t(context, "onboarding.register.guest"),
                              style: link,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                t(context, "onboarding.register.have_account"),
                                style: plain,
                              ),
                              TextButton(
                                style: btn,
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.pushNamed(
                                        context,
                                        "/signin",
                                      ),
                                child: Text(
                                  t(context, "onboarding.register.signin"),
                                  style: link,
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                t(context, "onboarding.register.trouble"),
                                style: plain,
                              ),
                              TextButton(
                                style: btn,
                                onPressed: _contact,
                                child: Text(
                                  t(context, "onboarding.register.contact"),
                                  style: link,
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
  }
}
