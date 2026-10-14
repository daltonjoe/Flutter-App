import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_application/paywall/paywall_service.dart";
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import '../../core/constants/auth_redirect.dart';
import "../../core/theme/app_colors.dart";
import "../../core/theme/app_typography.dart";
import "../../i18n/app_localizations.dart";
import "../../providers/active_profile_provider.dart";
import "package:flutter_application/diag68.dart";
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
    diag68("signin after", "pid=${s68(pid)}");
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
      nav.pushNamedAndRemoveUntil("/onboarding", (r) => false,
          arguments: {"isFirstProfile": true});
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
    await Supabase.instance.client.auth
        .signInWithPassword(email: _email.text.trim(), password: _pw.text);
    await _after();
  }

  Future<void> _oauth(OAuthProvider p) async {
    final sp70 = await SharedPreferences.getInstance();
    await sp70.setString("auth_intent", "signin");
    await Supabase.instance.client.auth
        .signInWithOAuth(p, redirectTo: kAuthRedirectUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(context, "auth.signin.title"))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(t(context, "auth.signin.description"),
                style: AppTextStyles.bodyMd(color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t(context, "onboarding.link_account.email_label")),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pw,
              obscureText: true,
              decoration: InputDecoration(labelText: t(context, "onboarding.link_account.password_label")),
            ),
            if (_err) ...[
              const SizedBox(height: 12),
              Text(t(context, "auth.signin.error"),
                  style: AppTextStyles.bodyMd(color: AppColors.roseAccent)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: _busy ? null : () => _run(_signIn),
              child: Text(t(context, "auth.signin.button")),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: const Icon(Icons.g_mobiledata),
              label: Text(t(context, "onboarding.link_account.google_button")),
              onPressed: _busy ? null : () => _run(() => _oauth(OAuthProvider.google)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: const Icon(Icons.apple),
              label: Text(t(context, "onboarding.link_account.apple_button")),
              onPressed: _busy ? null : () => _run(() => _oauth(OAuthProvider.apple)),
            ),
          ],
        ),
      ),
    );
  }
}
