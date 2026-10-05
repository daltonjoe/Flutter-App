import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_colors.dart';
import '../i18n/app_localizations.dart';

/// Argümanlar: event (daily-events events[] elemanı), locale, title (today_page'in
/// zaten çözdüğü "Transit · açı · natal" etiketi; isim çözümü burada tekrarlanmaz).
class TransitDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final String locale;
 final String title;
  final String? profileId;
  final String? day; // yyyy-MM-dd (Today'de seçili gün)
  const TransitDetailPage({
    super.key,
    required this.event,
    required this.locale,
    required this.title,
    this.profileId,
    this.day,
  });

  @override
  State<TransitDetailPage> createState() => _TransitDetailPageState();
}

class _TransitDetailPageState extends State<TransitDetailPage> {
  String? _body;
  String? _valence;
  bool _loading = true;
 bool _failed = false;
  String? _bodyLocale;
  int? _vote;
  bool _voting = false;

  bool get _canVote =>
      !_failed &&
      _body != null &&
      _bodyLocale != null &&
      widget.profileId != null &&
      widget.day != null &&
      widget.event['template_id'] != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tid = widget.event['template_id'];
    if (tid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final db = Supabase.instance.client;
      final tpl = await db
          .from('snippet_templates')
          .select('valence')
          .eq('id', tid)
          .maybeSingle();
      final tr = await db
          .from('snippet_translations')
          .select('locale,body')
          .eq('template_id', tid)
          .inFilter('locale', [widget.locale, 'en']);
String? body;
      String? bodyLoc;
      for (final loc in [widget.locale, 'en']) {
        for (final r in (tr as List)) {
          if (r['locale'] == loc &&
              (r['body'] as String?)?.isNotEmpty == true) {
            body = r['body'] as String;
            bodyLoc = loc;
            break;
          }
        }
        if (body != null) break;
      }
      int? vote;
      if (body != null && widget.profileId != null && widget.day != null) {
        try {
          final fb = await db
              .from('snippet_feedback')
              .select('felt_true')
              .eq('profile_id', widget.profileId!)
              .eq('day', widget.day!)
              .eq('template_id', tid)
              .maybeSingle();
          vote = (fb?['felt_true'] as num?)?.toInt();
        } catch (e) {
          debugPrint('feedback read error: $e');
        }
      }
      if (!mounted) return;
      setState(() {
        _valence = tpl?['valence'] as String?;
        _body = body;
        _bodyLocale = bodyLoc;
        _vote = vote;
        _loading = false;
      });
    } catch (e) {
      debugPrint('TransitDetail load error: $e');
       if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }
    Future<void> _setVote(int v) async {
    final tid = widget.event['template_id'];
    if (_voting || !_canVote) return;
    final prev = _vote;
    final remove = prev == v;
    setState(() {
      _voting = true;
      _vote = remove ? null : v;
    });
    try {
      final tbl = Supabase.instance.client.from('snippet_feedback');
      if (remove) {
        await tbl
            .delete()
            .eq('profile_id', widget.profileId!)
            .eq('day', widget.day!)
            .eq('template_id', tid);
      } else {
        await tbl.upsert({
          'profile_id': widget.profileId,
          'day': widget.day,
          'template_id': tid,
          'locale': _bodyLocale,
          'felt_true': v,
        }, onConflict: 'profile_id,day,template_id');
      }
    } catch (e) {
      debugPrint('feedback write error: $e');
      if (mounted) {
        setState(() => _vote = prev);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t(context, 'feedback.error'))));
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Color _valenceColor(String? v) {
    switch (v) {
      case 'power':
        return AppColors.tealSuccess;
      case 'pressure':
        return AppColors.amberTransit;
      case 'trouble':
        return AppColors.roseAccent;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orb = (widget.event['orb'] as num?)?.toDouble();
    final applying = widget.event['applying'] == true;
    final vColor = _valenceColor(_valence);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t(context, 'today.events'),
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_valence != null)
                      _chip(t(context, 'valence.$_valence'), vColor),
                    if (orb != null)
                      _chip(
                        '${t(context, 'transit.orb')}: ${orb.toStringAsFixed(1)}°',
                        AppColors.textSecondary,
                      ),
                    _chip(
                      t(
                        context,
                        applying ? 'transit.applying' : 'transit.separating',
                      ),
                      AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _failed
                      ? t(context, 'today.error')
                      : (_body ?? t(context, 'transit.no_text')),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: _failed || _body == null
   ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
                if (_canVote) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t(context, 'feedback.prompt'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: t(context, 'feedback.helpful'),
                        icon: Icon(
                          _vote == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: _vote == 1
                              ? AppColors.tealSuccess
                              : AppColors.textMuted,
                        ),
                        onPressed: _voting ? null : () => _setVote(1),
                      ),
                      IconButton(
                        tooltip: t(context, 'feedback.not_helpful'),
                        icon: Icon(
                          _vote == -1
                              ? Icons.thumb_down
                              : Icons.thumb_down_outlined,
                          color: _vote == -1
                              ? AppColors.amberTransit
                              : AppColors.textMuted,
                        ),
                        onPressed: _voting ? null : () => _setVote(-1),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _chip(String label, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: c.withValues(alpha: 0.5)),
    ),
    child: Text(label, style: TextStyle(fontSize: 12, color: c)),
  );
}
