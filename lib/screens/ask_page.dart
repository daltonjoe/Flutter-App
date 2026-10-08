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
import '../providers/active_profile_provider.dart';
import '../providers/ask_draft.dart';
import 'package:flutter/cupertino.dart';

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
  String? _loc;
  bool _langReset = false;
  int _gen = 0;
  String _mode = 'natal';
  String? _fMonth; // YYYY-MM

  @override
  void initState() {
    super.initState();
    askDraft.addListener(_onDraft);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onDraft());
  }

  void _onDraft() {
    final d = askDraft.value;
    if (d == null || !mounted) return;
    _ctl.text = d;
    _ctl.selection = TextSelection.collapsed(offset: d.length);
    askDraft.value = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc =
        Provider.of<LanguageProvider>(context).locale.languageCode;
    if (_loc != null && _loc != loc) {
      _gen++;
      _messages.clear();
      _waiting = false;
      _failed = false;
      _langReset = true;
    }
    _loc = loc;
  }

  @override
  void dispose() {
    askDraft.removeListener(_onDraft);
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
       profileId: context.read<ActiveProfileProvider>().activeProfileId,
       mode: _mode,
       forecastMonth: _mode == 'forecast' ? _fMonth : null,
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
    if (_mode == 'forecast' && _fMonth == null) {
      _pickMonth();
      return;
    }
    HapticFeedback.selectionClick();
    _ctl.clear();
 final gen = _gen;
    final retry = override != null && _failed;
    setState(() {
      if (!retry) _messages.add(_Msg(true, text));
      _waiting = true;
      _failed = false;
      _langReset = false;
    });
    try {
      final r = await _reply(text);
      if (!mounted || gen != _gen) return;
      setState(() {
        _messages.add(_Msg(false, r));
        _waiting = false;
      });
    } catch (e) {
      debugPrint('AskPage reply failed: $e');
      if (!mounted || gen != _gen) return;
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

    Future<void> _pickMonth() async {
    final now = DateTime.now();
    var m = _fMonth == null ? now.month : int.parse(_fMonth!.substring(5));
    var y = _fMonth == null ? now.year : int.parse(_fMonth!.substring(0, 4));
    const y0 = 2020, y1 = 2099;
    final mc = FixedExtentScrollController(initialItem: m - 1);
    final yc = FixedExtentScrollController(initialItem: y - y0);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Row(children: [
              Expanded(
                child: CupertinoPicker(
                  scrollController: mc,
                  itemExtent: 40,
                  onSelectedItemChanged: (i) {
                    m = i + 1;
                    HapticFeedback.selectionClick();
                  },
                  children: [
                    for (var i = 1; i <= 12; i++)
                      Center(
                          child: Text(i.toString().padLeft(2, '0'),
                              style: AppTextStyles.bodyLg(
                                  color: AppColors.textPrimary)))
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: yc,
                  itemExtent: 40,
                  onSelectedItemChanged: (i) {
                    y = y0 + i;
                    HapticFeedback.selectionClick();
                  },
                  children: [
                    for (var i = y0; i <= y1; i++)
                      Center(
                          child: Text('$i',
                              style: AppTextStyles.bodyLg(
                                  color: AppColors.textPrimary)))
                  ],
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(t(ctx, 'settings.save')),
              ),
            ),
          ),
        ]),
      ),
    );
    mc.dispose();
    yc.dispose();
    if (ok != true || !mounted) return;
    final v = '$y-${m.toString().padLeft(2, '0')}';
    if (v == _fMonth) return;
    setState(() {
      _fMonth = v;
      _gen++;
      _messages.clear();
      _waiting = false;
      _failed = false;
    });
  }

  Widget _empty(BuildContext context) {
    final sugg = [
      t(context, 'ask.suggest.$_mode.1'),
      t(context, 'ask.suggest.$_mode.2'),
      t(context, 'ask.suggest.$_mode.3'),
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.auto_awesome_outlined,
            size: 40, color: AppColors.violetPrimary),
        const SizedBox(height: 16),
        Text(
          t(context, 'ask.empty_title.$_mode'),
          textAlign: TextAlign.center,
          style: AppTextStyles.h3(),
        ),
        const SizedBox(height: 8),
        Text(
          t(context, 'ask.empty_body.$_mode'),
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
             Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: 'natal', label: Text(t(context, 'ask.mode.natal'))),
                  ButtonSegment(
                      value: 'forecast',
                      label: Text(t(context, 'ask.mode.forecast'))),
                ],
                selected: {_mode},
                          onSelectionChanged: (s) {
                if (s.first == _mode) return;
                setState(() {
                  _gen++;
                  _mode = s.first;
                  _fMonth = null;
                  _messages.clear();
                  _waiting = false;
                  _failed = false;
                  _langReset = false;
                  _lastText = '';
                });
              },
              ),
            ),
            if (_mode == 'forecast')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ActionChip(
                  avatar:
                      const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(_fMonth == null
                      ? t(context, 'ask.forecast.pick')
                      : '${t(context, 'ask.forecast.for')}: ${_fMonth!.substring(5)}-${_fMonth!.substring(0, 4)}'),
                  onPressed: _pickMonth,
                ),
              ),
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
                      onPressed: () => _send(_lastText),
                      child: Text(t(context, 'ask.retry')),
                    ),
                  ],
                ),
              ),
              if (_langReset)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  t(context, 'ask.lang_reset'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm(),
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