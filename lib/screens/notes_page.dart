import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../core/theme/app_decorations.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../services/ask_service.dart';
import '../services/ai_consent_service.dart';

/// NotlarÄ±m: ask_memories (RLS ile okuma/silme), dÃ¼zenleme PATCH /memory/{id}.
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  bool _err = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sw = Stopwatch()..start();
    try {
      final r = await Supabase.instance.client
          .from('ask_memories')
          .select('id,body')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _rows = [for (final x in r) Map<String, dynamic>.from(x)];
        _loading = false;
        _err = false;
      });
      debugPrint('NotesPage load ms=${sw.elapsedMilliseconds}');
    } catch (e) {
      debugPrint('NotesPage load failed after ms=${sw.elapsedMilliseconds}: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _err = true;
      });
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final sm = ScaffoldMessenger.of(context);
    try {
      await Supabase.instance.client
          .from('ask_memories')
          .delete()
          .eq('id', row['id']);
      await _load();
    } catch (e) {
      debugPrint('NotesPage delete failed: $e');
      if (!mounted) return;
      sm.showSnackBar(SnackBar(content: Text(t(context, 'ask.error'))));
    }
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final sm = ScaffoldMessenger.of(context);
    final raw = '${row['body'] ?? ''}';
    final ctl = TextEditingController(
        text: raw.length > 150 ? raw.substring(0, 150) : raw);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(ctx, 'notes.edit')),
        content: TextField(
            controller: ctl, maxLength: 150, minLines: 1, maxLines: 4),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t(ctx, 'notes.save')),
          ),
        ],
      ),
    );
    final text = ctl.text.trim();
    if (ok != true || text.isEmpty || !mounted) return;
    try {
      await AskService.memoryEdit('${row['id']}', text);
      await _load();
    } catch (e) {
      debugPrint('NotesPage edit failed: $e');
      if (!mounted) return;
      sm.showSnackBar(
          SnackBar(content: Text(t(context, AskService.memoryErrKey(e)))));
    }
  }

  Future<bool> _confirm(String titleKey, String bodyKey) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(ctx, titleKey)),
        content: Text(t(ctx, bodyKey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(ctx, 'notes.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t(ctx, 'notes.delete')),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<bool> _wipe() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      await Supabase.instance.client
          .from('ask_memories')
          .delete()
          .eq('user_id', uid);
      return true;
    } catch (e) {
      debugPrint('NotesPage wipe failed: $e');
      return false;
    }
  }

  Future<void> _clearAll() async {
    final sm = ScaffoldMessenger.of(context);
    if (!await _confirm('notes.clear_all', 'notes.clear_all_body')) return;
    if (!mounted) return;
    final ok = await _wipe();
    if (!mounted) return;
    if (!ok) {
      sm.showSnackBar(SnackBar(content: Text(t(context, 'ask.error'))));
      return;
    }
    await _load();
  }

  Future<void> _withdraw() async {
    final sm = ScaffoldMessenger.of(context);
    if (!await _confirm('notes.withdraw', 'notes.withdraw_body')) return;
    if (!mounted) return;
    final ok = await _wipe() && await AiConsentService.revokeAi();
    if (!mounted) return;
    if (!ok) {
      sm.showSnackBar(SnackBar(content: Text(t(context, 'ask.error'))));
    }
    await _load();
  }
  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_err) {
      body = Center(
          child: Text(t(context, 'ask.error'), style: AppTextStyles.bodyMd()));
    } else if (_rows.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t(context, 'notes.empty'),
              textAlign: TextAlign.center, style: AppTextStyles.bodyMd()),
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (c, i) {
          final r = _rows[i];
          return Container(
            decoration: AppDecorations.cosmicCard(),
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('${r['body'] ?? ''}',
                      style: AppTextStyles.bodyMd()),
                ),
                IconButton(
                  tooltip: t(c, 'notes.edit'),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _edit(r),
                ),
                IconButton(
                  tooltip: t(c, 'notes.delete'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _delete(r),
                ),
              ],
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'notes.title')),
        actions: [
          if (!_loading && !_err)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text('${_rows.length}/10', style: AppTextStyles.bodyMd()),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') {
                _clearAll();
              } else {
                _withdraw();
              }
            },
            itemBuilder: (c) => [
              if (_rows.isNotEmpty)
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Text(t(c, 'notes.clear_all')),
                ),
              PopupMenuItem<String>(
                value: 'withdraw',
                child: Text(t(c, 'notes.withdraw')),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}
