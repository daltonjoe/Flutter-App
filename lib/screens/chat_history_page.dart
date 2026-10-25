import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../presentation/widgets/components/cosmic_background.dart';
import '../providers/language_provider.dart';
import '../services/chat_store.dart';

/// V4b: gecmis ekraninda secilen kayit; deleted = kisi silinmis (yalniz okunur).
class HistoryPick {
  const HistoryPick(this.rec, this.deleted);

  final ChatRecord rec;
  final bool deleted;
}

/// V4b: bir moda ait kayitli sohbetlerin listesi (K4, K8, K9, K11, K14).
class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key, required this.mode});

  final String mode;

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final Set<String> _sel = <String>{};
  List<MapEntry<String, ChatRecord>> _items = [];
  Set<String> _alive = <String>{};
  bool _aliveKnown = false;
  bool _loading = true;
  bool _selecting = false;

  String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      _loading = false;
      return;
    }
    final items = await ChatStore.listArch(uid, widget.mode);
    var alive = <String>{};
    var known = false;
    try {
      final rows = await Supabase.instance.client
          .from('user_profiles')
          .select('id')
          .eq('user_id', uid);
      alive = {for (final r in rows) '${r['id']}'};
      known = true;
    } catch (e) {
      debugPrint('ChatHistory profiles failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _alive = alive;
      _aliveKnown = known;
      _loading = false;
    });
  }

  /// K8: kayittaki kisilerden biri profil listesinde yoksa silinmis sayilir.
  bool _gone(ChatRecord r) {
    if (!_aliveKnown) return false;
    for (final id in [r.pa, r.pb]) {
      if (id != null && !_alive.contains(id)) return true;
    }
    return false;
  }

  String _date(DateTime d, String loc) {
    try {
      return DateFormat.yMMMd(loc).format(d);
    } catch (_) {
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '$dd.$mm.${d.year}';
    }
  }

  void _tap(MapEntry<String, ChatRecord> e, bool gone) {
    if (_selecting) {
      setState(() {
        if (!_sel.remove(e.key)) _sel.add(e.key);
      });
      return;
    }
    Navigator.pop(context, HistoryPick(e.value, gone));
  }

  Future<void> _rename(MapEntry<String, ChatRecord> e) async {
    final sid = e.value.sid;
    final uid = _uid;
    if (sid == null || uid == null) return;
    final ctl = TextEditingController(text: e.value.title ?? '');
    final v = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t(c, 'ask.rename')),
        content: TextField(controller: ctl, autofocus: true, maxLength: 60),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(t(c, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, ctl.text.trim()),
            child: Text(t(c, 'common.ok')),
          ),
        ],
      ),
    );
    if (!mounted || v == null || v.isEmpty) return;
    await ChatStore.rename(uid, widget.mode, sid, v);
    await _load();
  }

  Future<void> _delete() async {
    final uid = _uid;
    if (uid == null || _sel.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(t(c, 'ask.delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t(c, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(t(c, 'ask.delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final e in _items) {
      final sid = e.value.sid;
      if (_sel.contains(e.key) && sid != null) {
        await ChatStore.deleteSaved(uid, widget.mode, sid);
      }
    }
    _sel.clear();
    _selecting = false;
    await _load();
  }

  Widget _card(BuildContext context, MapEntry<String, ChatRecord> e, String loc) {
    final r = e.value;
    final gone = _gone(r);
    final picked = _sel.contains(e.key);
    final date = _date(DateTime.fromMillisecondsSinceEpoch(r.updated), loc);
    return Material(
      color: AppColors.navyDeep.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _tap(e, gone),
        onLongPress: (_selecting || gone) ? null : () => _rename(e),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (_selecting)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: Icon(
                    picked ? Icons.check_circle_rounded : Icons.circle_outlined,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLg(),
                    ),
                    const SizedBox(height: 4),
                    Text(r.pn ?? '', style: AppTextStyles.bodyMd()),
                    Text(date, style: AppTextStyles.bodyMd()),
                    if (gone)
                      Text(
                        t(context, 'ask.person_deleted'),
                        style: AppTextStyles.bodyMd().copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                gone ? Icons.visibility_outlined : Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, String loc) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            t(context, 'ask.history_empty'),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd(),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _items.length,
      separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (c, i) => _card(c, _items[i], loc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LanguageProvider>(context).locale.languageCode;
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t(context, 'ask.history')),
          actions: [
            if (_items.isNotEmpty)
              TextButton(
                onPressed: () => setState(() {
                  _selecting = !_selecting;
                  _sel.clear();
                }),
                child: Text(t(context, _selecting ? 'common.cancel' : 'ask.select')),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: _list(context, loc)),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  t(context, 'ask.history_note'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd(),
                ),
              ),
              if (_selecting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _sel.isEmpty ? null : _delete,
                      child: Text(t(context, 'ask.delete')),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
