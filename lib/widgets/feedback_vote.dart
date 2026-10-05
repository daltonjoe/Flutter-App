import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_colors.dart';
import '../i18n/app_localizations.dart';

/// snippet_feedback 👍/👎. Aynı butona tekrar basınca oy silinir.
/// Parent bunu ValueKey('$pid|$day|$templateId') ile oluşturmalı.
class FeedbackVote extends StatefulWidget {
  final String profileId;
  final String day; // yyyy-MM-dd
  final int templateId;
  final String locale; // gösterilen metnin dili
  const FeedbackVote({
    super.key,
    required this.profileId,
    required this.day,
    required this.templateId,
    required this.locale,
  });

  @override
  State<FeedbackVote> createState() => _FeedbackVoteState();
}

class _FeedbackVoteState extends State<FeedbackVote> {
  int? _vote;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    try {
      final fb = await Supabase.instance.client
          .from('snippet_feedback')
          .select('felt_true')
          .eq('profile_id', widget.profileId)
          .eq('day', widget.day)
          .eq('template_id', widget.templateId)
          .maybeSingle();
      if (!mounted) return;
      setState(() => _vote = (fb?['felt_true'] as num?)?.toInt());
    } catch (e) {
      debugPrint('feedback read error: $e');
    }
  }

  Future<void> _set(int v) async {
    if (_busy) return;
    final prev = _vote;
    final remove = prev == v;
    setState(() {
      _busy = true;
      _vote = remove ? null : v;
    });
    try {
      final tbl = Supabase.instance.client.from('snippet_feedback');
      if (remove) {
        await tbl
            .delete()
            .eq('profile_id', widget.profileId)
            .eq('day', widget.day)
            .eq('template_id', widget.templateId);
      } else {
        await tbl.upsert({
          'profile_id': widget.profileId,
          'day': widget.day,
          'template_id': widget.templateId,
          'locale': widget.locale,
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            t(context, 'feedback.prompt'),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: t(context, 'feedback.helpful'),
          icon: Icon(
            _vote == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 20,
            color: _vote == 1 ? AppColors.tealSuccess : AppColors.textMuted,
          ),
          onPressed: _busy ? null : () => _set(1),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: t(context, 'feedback.not_helpful'),
          icon: Icon(
            _vote == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
            size: 20,
            color: _vote == -1 ? AppColors.amberTransit : AppColors.textMuted,
          ),
          onPressed: _busy ? null : () => _set(-1),
        ),
      ],
    );
  }
}