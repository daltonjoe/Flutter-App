import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../i18n/app_localizations.dart';
import '../../services/account_linking_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';

class OnboardingLinkAccountPage extends StatefulWidget {
const OnboardingLinkAccountPage({super.key});

  @override
  State<OnboardingLinkAccountPage> createState() =>
      _OnboardingLinkAccountPageState();
}

class _OnboardingLinkAccountPageState extends State<OnboardingLinkAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _emailAlreadyLinked = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Google/Apple OAuth tarayıcı akışı dönünce (deep-link) buradan yakalanır.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
          if (!mounted) return;
      final identities = state.session?.user.identities ?? [];
      final hasOAuth = identities.any((i) => i.provider != 'anonymous');
      _goHome();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _navigated = false;
    void _goHome() {
      if (_navigated || !mounted) return;
      _navigated = true;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    if (!_emailAlreadyLinked) {
      try {
        await AccountLinkingService.linkEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        _emailAlreadyLinked = true;
      } on AuthException catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        final isRateLimit = e.message.toLowerCase().contains('rate limit');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRateLimit
                  ? t(context, 'onboarding.link_account.rate_limit_error')
                  : e.message,
            ),
          ),
        );
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(context, 'common.unknown_error'))),
        );
        return;
      }
    }

    _goHome();
  }

  Future<void> _onOAuth(Future<void> Function() linkFn) async {
    setState(() => _isSubmitting = true);
    try {
      await linkFn();
    } catch (e, st) {
      debugPrint('OAuth link error: $e\n$st');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, 'common.unknown_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_emailAlreadyLinked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t(context, 'onboarding.link_account.title')),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t(context, 'onboarding.link_account.description'),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: t(
                        context,
                        'onboarding.link_account.email_label',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return t(
                          context,
                          'onboarding.link_account.email_invalid',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: t(
                        context,
                        'onboarding.link_account.password_label',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return t(
                          context,
                          'onboarding.link_account.password_too_short',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _onSave,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(t(context, 'onboarding.link_account.save_button')),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(t(context, 'onboarding.link_account.or_divider'))),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.g_mobiledata),
                    label: Text(t(context, 'onboarding.link_account.google_button')),
                    onPressed: _isSubmitting ? null : () => _onOAuth(AccountLinkingService.linkGoogle),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.apple),
                    label: Text(t(context, 'onboarding.link_account.apple_button')),
                    onPressed: _isSubmitting ? null : () => _onOAuth(AccountLinkingService.linkApple),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isSubmitting ? null : _goHome,
                    child: Text(t(context, 'onboarding.link_account.skip_button')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}