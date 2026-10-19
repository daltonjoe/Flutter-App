import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:provider/provider.dart";
import "../../providers/active_profile_provider.dart";
import "package:flutter_application/diag68.dart";
import "package:url_launcher/url_launcher.dart";
import "../../core/constants/legal_links.dart";
import "../../core/theme/app_colors.dart";
import "../../core/theme/app_typography.dart";
import "../../i18n/app_localizations.dart";
import '../../presentation/widgets/components/cosmic_loader.dart';

class OnboardingConsentPage extends StatefulWidget {
  const OnboardingConsentPage({super.key});

  @override
  State<OnboardingConsentPage> createState() => _OnboardingConsentPageState();
}

class _OnboardingConsentPageState extends State<OnboardingConsentPage> {
  bool _checking = true;
  bool _priv = false;
  bool _terms = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    diag68("page: consent init");
    _check();
  }

  void _home() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil("/home", (r) => false);
  }

  Future<void> _check() async {
    try {
      final rows = await Supabase.instance.client
          .from("user_consents")
          .select("kind")
          .inFilter("kind", ["privacy", "terms", "ai"]);
      final sp = await SharedPreferences.getInstance();
      await sp.remove("force_consent");
      final k = rows.map((r) => r["kind"]).toSet();
      diag68("consent check", "kinds=${k.length}");
      if (k.contains("privacy") && k.contains("terms") && k.contains("ai")) {
        _home();
        return;
      }
    } catch (e) {
      diag68("consent check ERR", "${e.runtimeType}");
      debugPrint("consent check failed: $e");
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<bool> _ins(String uid, String kind) async {
    final vs = <Map<String, dynamic>>[
      {"user_id": uid, "kind": kind, "version": 1},
      {"user_id": uid, "kind": kind},
    ];
    for (final v in vs) {
      try {
        await Supabase.instance.client.from("user_consents").insert(v);
        return true;
      } on PostgrestException catch (e) {
        if (e.code == "23505") return true;
        debugPrint("consent insert failed: ${e.code}");
      } catch (e) {
        debugPrint("consent insert failed: $e");
      }
    }
    return false;
  }

  Future<void> _go() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _saving = true);
    final ok = await _ins(uid, "privacy") && await _ins(uid, "terms") && await _ins(uid, "ai");
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t(context, "ask.error"))));
      return;
    }
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove("force_consent");
    } catch (e) {
      debugPrint("force_consent clear failed: $e");
    }
    if (!mounted) return;
    _home();
  }

  Future<void> _back() async {
    debugPrint("consent back start");
    diag68("consent back start");
    final nav = Navigator.of(context, rootNavigator: true);
    final prov = context.read<ActiveProfileProvider>();
    var out67 = false;
    final uid69 = Supabase.instance.client.auth.currentUser?.id;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove("force_consent");
      final c = Supabase.instance.client;
      if (c.auth.currentUser?.isAnonymous == false) {
        await c.auth.signOut(scope: SignOutScope.local);
        await c.auth.signInAnonymously();
        out67 = true;
      }
    } catch (e) {
      debugPrint("consent back failed: $e");
    }
    final uidNow69 = Supabase.instance.client.auth.currentUser?.id;
    final changed69 = uid69 != uidNow69;
    diag68("consent back before-push", "out=$out67 changed=$changed69");
    if (out67 || changed69) {
      try {
        await prov.clearActive();
      } catch (e) {
        debugPrint("consent back clear failed: $e");
      }
    }
    nav.pushNamedAndRemoveUntil("/onboarding/link-account", (r) => false);
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("open url failed: $e");
    }
  }

  Widget _box(String linkKey, String checkKey, String url, bool v, ValueChanged<bool> on) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.mist),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CheckboxListTile(
        value: v,
        onChanged: _saving ? null : (b) => on(b ?? false),
        controlAffinity: ListTileControlAffinity.trailing,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: url.isEmpty ? null : () => _open(url),
              child: Text(t(context, linkKey),
                  style: AppTextStyles.bodyMd(color: AppColors.starlight).copyWith(
                      decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Text(t(context, checkKey), style: AppTextStyles.bodyMd(color: AppColors.mist)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const CosmicLoadingScreen();
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _saving ? null : _back,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 48),
              Text(t(context, "onboarding.consent.title"),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLg(color: AppColors.starlight).copyWith(fontSize: 30)),
              const SizedBox(height: 16),
              Text(t(context, "onboarding.consent.body"),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd(color: AppColors.mist)),
              const SizedBox(height: 32),
              _box("onboarding.consent.privacy_link", "onboarding.consent.privacy_check",
                  kPrivacyPolicyUrl, _priv, (b) => setState(() => _priv = b)),
              _box("onboarding.consent.terms_link", "onboarding.consent.terms_check",
                  kTermsUrl, _terms, (b) => setState(() => _terms = b)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: (_priv && _terms && !_saving) ? _go : null,
                child: Text(t(context, "onboarding.consent.cta")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
