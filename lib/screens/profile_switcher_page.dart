import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../i18n/app_localizations.dart';
import '../presentation/widgets/components/cosmic_card.dart';
import '../presentation/widgets/components/cosmic_cta_button.dart';
import '../presentation/widgets/components/cosmic_error_state.dart';
import '../presentation/widgets/components/cosmic_loader.dart';
import '../providers/active_profile_provider.dart';
import '../services/account_deletion_service.dart';
import 'edit_birth_time_page.dart';
import 'main_shell.dart' show shellTab, mapPopToRoot;

class ProfileSwitcherPage extends StatefulWidget {
  const ProfileSwitcherPage({super.key});

  @override
  State<ProfileSwitcherPage> createState() => _ProfileSwitcherPageState();
}

class _ProfileSwitcherPageState extends State<ProfileSwitcherPage> {
  bool _isLoading = true;
  bool _isDeletingAccount = false;
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
          .select('id, display_name, birth_date, sun_sign_id, birth_time_known')
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
    mapPopToRoot.value++;
    shellTab.value = 1;
  }

  Future<void> _deleteProfile(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t(context, 'profile_switcher.delete_title')),
        content: Text(t(context, 'profile_switcher.delete_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t(context, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t(context, 'profile_switcher.delete_confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await Supabase.instance.client
          .from('user_profiles')
          .delete()
          .eq('id', id);
      if (!mounted) return;

      final activeProfileProvider = context.read<ActiveProfileProvider>();
      if (activeProfileProvider.activeProfileId == id) {
        await activeProfileProvider.clearActive();
      }
      if (!mounted) return;
      await _loadProfiles();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, 'profile_switcher.delete_error'))),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t(context, 'account_deletion.title')),
        content: Text(t(context, 'account_deletion.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t(context, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t(context, 'account_deletion.confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, 'account_deletion.error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProfileId = context
        .watch<ActiveProfileProvider>()
        .activeProfileId;

    if (_isDeletingAccount) {
      return CosmicLoader(message: t(context, 'account_deletion.loading'));
    }

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
          ? CosmicErrorState(message: t(context, 'profile_switcher.empty'))
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile['display_name'] as String),
                                const SizedBox(height: 4),
                                Text(profile['birth_date'].toString()),
                              ],
                            ),
                          ),
                          if (profile['id'] == activeProfileId)
                            const Icon(Icons.check_circle),
                          if (profile['birth_time_known'] != true)
                            IconButton(
                              icon: const Icon(Icons.access_time),
                              tooltip: t(context, 'birth_time.add'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EditBirthTimePage(
                                    profileId: profile['id'] as String,
                                  ),
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                _deleteProfile(profile['id'] as String),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CosmicCtaButton(
                  label: t(context, 'profile_switcher.add'),
                  onTap: () =>
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        '/onboarding',
                        arguments: {'isFirstProfile': false},
                      ),
                ),
                TextButton(
                  onPressed: _deleteAccount,
                  child: Text(
                    t(context, 'account_deletion.confirm'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
    );
  }
}
