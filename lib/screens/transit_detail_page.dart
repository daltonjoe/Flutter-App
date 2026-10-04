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
  const TransitDetailPage({
    super.key,
    required this.event,
    required this.locale,
    required this.title,
  });

  @override
  State<TransitDetailPage> createState() => _TransitDetailPageState();
}

class _TransitDetailPageState extends State<TransitDetailPage> {
  String? _body;
  String? _valence;
  bool _loading = true;
  bool _failed = false;

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
      for (final loc in [widget.locale, 'en']) {
        for (final r in (tr as List)) {
          if (r['locale'] == loc &&
              (r['body'] as String?)?.isNotEmpty == true) {
            body = r['body'] as String;
            break;
          }
        }
        if (body != null) break;
      }
      if (!mounted) return;
      setState(() {
        _valence = tpl?['valence'] as String?;
        _body = body;
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
