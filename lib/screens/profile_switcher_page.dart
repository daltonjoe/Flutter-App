import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../i18n/app_localizations.dart';
import '../presentation/widgets/components/cosmic_card.dart';
import '../presentation/widgets/components/cosmic_cta_button.dart';
import '../presentation/widgets/components/cosmic_error_state.dart';
import '../presentation/widgets/components/cosmic_loader.dart';
import '../providers/active_profile_provider.dart';

class ProfileSwitcherPage extends StatefulWidget {
  const ProfileSwitcherPage({super.key});

  @override
  State<ProfileSwitcherPage> createState() => _ProfileSwitcherPageState();
}

class _ProfileSwitcherPageState extends State<ProfileSwitcherPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = t(context, 'profile_switcher.error');
      });
      return;
    }

    try {
      final rows = await Supabase.instance.client
          .from('user_profiles')
          .select('id, display_name, birth_date, sun_sign_id')
          .eq('user_id', user.id)
          .order('created_at');
      if (!mounted) return;
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(rows);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = t(context, 'profile_switcher.error');
      });
    }
  }

  Future<void> _selectProfile(String id) async {
    await context.read<ActiveProfileProvider>().setActive(id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeProfileId =
        context.watch<ActiveProfileProvider>().activeProfileId;

    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'profile_switcher.title'))),
      body: _isLoading
          ? const CosmicLoader()
          : _error != null
              ? CosmicErrorState(
                  message: _error!,
                  onRetry: _loadProfiles,
                  retryLabel: t(context, 'profile_switcher.retry'),
                )
              : _profiles.isEmpty
                  ? CosmicErrorState(
                      message: t(context, 'profile_switcher.empty'),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        ..._profiles.map(
                          (profile) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CosmicCard(
                              onTap: () => _selectProfile(profile['id'] as String),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(profile['display_name'] as String),
                                        const SizedBox(height: 4),
                                        Text(profile['birth_date'].toString()),
                                      ],
                                    ),
                                  ),
                                  if (profile['id'] == activeProfileId)
                                    const Icon(Icons.check_circle),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CosmicCtaButton(
                          label: t(context, 'profile_switcher.add'),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/onboarding',
                          ),
                        ),
                      ],
                    ),
    );
  }
}
