import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/reference_names_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../providers/ask_context_provider.dart';
import '../providers/language_provider.dart';
import '../services/ask_service.dart';
import '../services/astro_service.dart';

class _Msg {
  final bool mine;
  final String text;
  const _Msg(this.mine, this.text);
}

class AskPage extends StatefulWidget {
  const AskPage({super.key});
  @override
  State<AskPage> createState() => _AskPageState();
}

class _AskPageState extends State<AskPage> {
  final TextEditingController _ctl = TextEditingController();
  final List<_Msg> _messages = [];
  bool _waiting = false;
  bool _failed = false;
  String _lastText = '';
  String _errKey = 'ask.error';

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

Future<String> _reply(String text) async {
    // context'i await'ten önce kullan (lint)
    final loc = context.read<LanguageProvider>().locale.languageCode;
    final safe = {
      'crisis': t(context, 'ask.safety.crisis'),
      'redirect': t(context, 'ask.safety.redirect'),
      'fallback': t(context, 'ask.safety.fallback'),
    };
    final prev = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <_Msg>[];
    final last = prev.length > 6 ? prev.sublist(prev.length - 6) : prev;
    final res = await AskService.send(
      message: text,
      contexts: askContext.items.map((e) => e.toServer()).toList(),
      locale: loc,
      history: [
        for (final m in last)
          {'role': m.mine ? 'user' : 'assistant', 'text': m.text}
      ],
    );
    final s = res.safety;
    if (s != null) return res.reply ?? (safe[s] ?? safe['fallback']!);
    final rp = res.reply;
    if (rp == null || rp.trim().isEmpty) return safe['fallback']!;
    return rp;
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _ctl.text).trim();
    if (text.isEmpty || _waiting) return;
    HapticFeedback.selectionClick();
    _ctl.clear();
    setState(() => _messages.add(_Msg(true, text)));
    await _ask(text);
  }

  Future<void> _ask(String text) async {
    setState(() {
      _waiting = true;
      _failed = false;
    });
    try {
      final r = await _reply(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(false, r));
        _waiting = false;
      });
    } catch (e) {
    debugPrint('AskPage reply failed: $e');
      if (!mounted) return;
      setState(() {
        _waiting = false;
        _failed = true;
        _lastText = text;
        _errKey = (e is AstroServiceException && e.code == 'RATE_LIMITED')
            ? 'ask.error.rate'
            : 'ask.error';
      });
    }
  }

  Widget _empty(BuildContext context) {
    final sugg = [
      t(context, 'ask.suggest_1'),
      t(context, 'ask.suggest_2'),
      t(context, 'ask.suggest_3'),
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.auto_awesome_outlined,
            size: 40, color: AppColors.violetPrimary),
        const SizedBox(height: 16),
        Text(
          t(context, 'ask.empty_title'),
          textAlign: TextAlign.center,
          style: AppTextStyles.h3(),
        ),
        const SizedBox(height: 8),
        Text(
          t(context, 'ask.empty_body'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd(),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in sugg)
              ActionChip(
                label: Text(s, style: AppTextStyles.chip()),
                onPressed: () => _send(s),
              ),
          ],
        ),
      ],
    );
  }

  Widget _bubble(BuildContext context, _Msg m) {
    final maxW = MediaQuery.of(context).size.width * 0.82;
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: m.mine
            ? BoxDecoration(
                color: AppColors.violetPrimary.withAlpha(64),
                borderRadius: BorderRadius.circular(16),
              )
            : AppDecorations.cosmicCard(),
        child: Text(
          m.text,
          style: m.mine ? AppTextStyles.bodyLg() : AppTextStyles.bodyMd(),
        ),
      ),
    );
  }

  Widget _typing(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(t(context, 'ask.typing'), style: AppTextStyles.bodySm()),
      ),
    );
  }

  Widget _contextStrip(BuildContext context) {
    return ListenableBuilder(
      listenable: askContext,
      builder: (context, _) {
        final items = askContext.items;
        if (items.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Center(
              child: InputChip(
                label: Text(
                  items[i].displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.chip(),
                ),
                deleteButtonTooltipMessage: t(context, 'ask.context.remove'),
                onDeleted: () {
                  HapticFeedback.selectionClick();
                  askContext.remove(items[i].id);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _composer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _ctl,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              style: AppTextStyles.bodyLg(),
              decoration: InputDecoration(
                hintText: t(context, 'ask.placeholder'),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: t(context, 'ask.send'),
              onPressed: _waiting ? null : _send,
              icon: const Icon(Icons.arrow_upward_rounded,
                  color: AppColors.violetPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ReferenceNamesService>();
    final msgs = _messages.reversed.toList();
    final extra = _waiting ? 1 : 0;
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'ask.title'))),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: (_messages.isEmpty && !_waiting)
                  ? _empty(context)
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: msgs.length + extra,
                      itemBuilder: (c, i) {
                        if (_waiting && i == 0) return _typing(c);
                        return _bubble(c, msgs[i - extra]);
                      },
                    ),
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                           t(context, _errKey),
                        style: AppTextStyles.bodySm(color: AppColors.errorRed),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _ask(_lastText),
                      child: Text(t(context, 'ask.retry')),
                    ),
                  ],
                ),
              ),
            _contextStrip(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                t(context, 'ask.disclaimer'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyXs(),
              ),
            ),
            _composer(context),
          ],
        ),
      ),
    );
  }
}