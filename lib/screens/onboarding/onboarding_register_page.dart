import "dart:async";
import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:url_launcher/url_launcher.dart";
import "../../core/constants/legal_links.dart";
import "../../core/theme/app_colors.dart";
import "../../core/theme/app_typography.dart";
import "../../i18n/app_localizations.dart";
import "../../services/account_linking_service.dart";
import "package:flutter_application/diag68.dart";

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
    diag68("page: register init");
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
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil("/onboarding/consent", (r) => false);
  }

  Future<void> _oauth(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      debugPrint("register oauth failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t(context, (e is AuthException && (e.message.toLowerCase().contains("already linked") || e.message.contains("identity_already_exists"))) ? "onboarding.register.exists" : "ask.error"))));
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

  Widget _opt(IconData i, String k, VoidCallback? f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          alignment: Alignment.centerLeft,
          foregroundColor: AppColors.textPrimary,
        ),
        icon: Icon(i),
        label: Text(t(context, k)),
        onPressed: f,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final link = AppTextStyles.bodyMd(color: AppColors.textPrimary)
        .copyWith(decoration: TextDecoration.underline, fontWeight: FontWeight.bold);
    final plain = AppTextStyles.bodyMd(color: AppColors.textMuted);
    final btn = TextButton.styleFrom(minimumSize: const Size(48, 48));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Text(t(context, "onboarding.register.title"),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLg(color: AppColors.textPrimary).copyWith(fontSize: 30)),
            const SizedBox(height: 8),
            Text(t(context, "onboarding.register.subtitle"), textAlign: TextAlign.center, style: plain),
            const SizedBox(height: 32),
            _opt(Icons.mail_outline, "onboarding.register.email",
                _busy ? null : () => Navigator.pushNamed(context, "/onboarding/email")),
            _opt(Icons.g_mobiledata, "onboarding.register.google",
                _busy ? null : () => _oauth(AccountLinkingService.linkGoogle)),
            _opt(Icons.apple, "onboarding.register.apple",
                _busy ? null : () => _oauth(AccountLinkingService.linkApple)),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _busy ? null : _next,
              child: Text(t(context, "onboarding.register.guest"), style: link),
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(t(context, "onboarding.register.have_account"), style: plain),
                TextButton(
                  style: btn,
                  onPressed: _busy ? null : () => Navigator.pushNamed(context, "/signin"),
                  child: Text(t(context, "onboarding.register.signin"), style: link),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(t(context, "onboarding.register.trouble"), style: plain),
                TextButton(
                  style: btn,
                  onPressed: _contact,
                  child: Text(t(context, "onboarding.register.contact"), style: link),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
