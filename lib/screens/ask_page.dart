import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/ask_bridge.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../services/ai_consent_service.dart';
import '../services/user_settings_service.dart';
import 'notes_page.dart';

class _Msg {
  final bool mine;
  final String text;
  bool animate; // K34: yalnız yeni gelen yanıt, bitince false
  final List<String>? bubbles; // AV: balon dizisi
  _Msg(this.mine, this.text, {this.animate = false, this.bubbles});
}

class AskPage extends StatefulWidget {
  const AskPage({super.key});
  @override
  State<AskPage> createState() => _AskPageState();
}

class _AskPageState extends State<AskPage> {
  final TextEditingController _ctl = TextEditingController();
  late final FocusNode _inputFocus = FocusNode(onKeyEvent: _onInputKey);
  final List<_Msg> _messages = [];
  bool _waiting = false;
  bool _failed = false;
  String _lastText = '';
  String _errKey = 'ask.error';
  String? _loc;
  bool _langReset = false;
  int _gen = 0;
   String _mode = askMode.value;
  String? _fMonth; // YYYY-MM
  bool _av = false; // feature_flags.ask_avatars
  String? _partnerId;
  String? _partnerName;
  List<Map<String, dynamic>> _partners = [];
  bool _partnersLoaded = false;

  @override
  void initState() {
    super.initState();
    askDraft.addListener(_onDraft);
    askMode.addListener(_onMode);
    askBridgeReq.addListener(_onBridge);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onBridge());
    UserSettingsService.isFlagEnabled('ask_avatars').then((v) {
      if (!mounted) return;
      askAvatarsEnabled.value = v;
      setState(() => _av = v);
      if (v && _mode == 'synastry') _autoPartner();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onDraft());
  }

    void _onBridge() {
    final r = askBridgeReq.value;
    if (r == null || r.length < 3 || !mounted) return;
    askBridgeReq.value = null;
    final act = context.read<ActiveProfileProvider>().activeProfileId;
    if (act == null || act != r[0]) {
      askMode.value = 'natal';
      askDraft.value = r[2];
      return;
    }
    askAvatarsEnabled.value = true;
    if (!_av) setState(() => _av = true);
    askMode.value = 'synastry';
    () async {
      final l = await _loadPartners();
      if (!mounted) return;
      setState(() {
        _partners = l;
        _partnersLoaded = true;
      });
      for (final p in l) {
        if ('${p['id']}' == r[1]) {
          _setPartner(p);
          break;
        }
      }
      askDraft.value = r[2];
    }();
  }

  void _onMode() {
    final m = askMode.value;
    if (!mounted || m == _mode) return;
    if (m == 'synastry') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoPartner());
    }
    setState(() {
      _gen++;
      _mode = m;
      _fMonth = null;
      _messages.clear();
      _waiting = false;
      _failed = false;
      _langReset = false;
      _lastText = '';
    });
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
    askMode.removeListener(_onMode);
    askBridgeReq.removeListener(_onBridge);
    _ctl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

Future<_Msg> _reply(String text) async {
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
      contexts: _mode == 'synastry'
          ? <Map<String, dynamic>>[
              {
                'type': 'synastry_pair',
                'refs': {
                  'profile_a':
                      context.read<ActiveProfileProvider>().activeProfileId,
                  'profile_b': _partnerId,
                },
              }
            ]
          : askContext.itemsFor(_mode).map((e) => e.toServer()).toList(),
      locale: loc,
      bubbles: _av,
      history: [
        for (final m in last)
          {'role': m.mine ? 'user' : 'assistant', 'text': m.text}
      ],
       profileId: context.read<ActiveProfileProvider>().activeProfileId,
       mode: _mode,
       forecastMonth: _mode == 'forecast' ? _fMonth : null,
    );
    final s = res.safety;
    if (s != null) {
      return _Msg(false, res.reply ?? (safe[s] ?? safe['fallback']!),
          animate: true);
    }
    final rp = res.reply;
    if (rp == null || rp.trim().isEmpty) {
      return _Msg(false, safe['fallback']!, animate: true);
    }
    final bl = res.bubbles;
    return _Msg(false, rp,
        animate: true,
        bubbles: (_av && bl != null && bl.isNotEmpty) ? bl : null);
  }

    KeyEventResult _onInputKey(FocusNode node, KeyEvent e) {
    final enter = e.logicalKey == LogicalKeyboardKey.enter ||
        e.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (e is KeyDownEvent && enter && !HardwareKeyboard.instance.isShiftPressed) {
      _send();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
Future<void> _send([String? override]) async {
    final text = (override ?? _ctl.text).trim();
        if (text.isEmpty || _waiting) return;
    if (_mode == 'forecast' && _fMonth == null) {
      _pickMonth();
      return;
    }
    if (_mode == 'synastry' && !_pairOk()) {
      _pickPartner();
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
        _messages.add(r);
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
            : (e is AstroServiceException && e.code == 'QUOTA')
                ? 'ask.error.quota'
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
    if (!m.mine && m.bubbles != null && m.bubbles!.isNotEmpty) {
      return _bubbleSeq(context, m);
    }
    if (m.mine && _av) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _remember(m.text),
        child: _bubbleBase(context, m),
      );
    }
    return _bubbleBase(context, m);
  }

  Widget _bubbleBase(BuildContext context, _Msg m) {
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
                  child: (!m.mine && m.animate)
              ? _Typewriter(
                  key: ObjectKey(m),
                  text: m.text,
                  style: AppTextStyles.bodyMd(),
                  onDone: () => m.animate = false,
                )
              : Text(
                  m.text,
                  style: m.mine
                      ? AppTextStyles.bodyLg()
                      : AppTextStyles.bodyMd(),
                ),
      ),
    );
  }

  Widget _bubbleSeq(BuildContext context, _Msg m) {
    return _BubbleSeq(
      key: ObjectKey(m),
      texts: m.bubbles!,
      animate: m.animate,
      onAllDone: () => m.animate = false,
      item: (txt, anim, done, k) => _box(context, txt, anim, done, k),
    );
  }

  Widget _box(BuildContext context, String text, bool animate,
      VoidCallback onDone, Key k) {
    final maxW = MediaQuery.of(context).size.width * 0.82;
    return Align(
      key: k,
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: AppDecorations.cosmicCard(),
        child: animate
            ? _Typewriter(
                text: text, style: AppTextStyles.bodyMd(), onDone: onDone)
            : Text(text, style: AppTextStyles.bodyMd()),
      ),
    );
  }

  bool _pairOk() {
    final act = context.read<ActiveProfileProvider>().activeProfileId;
    return _partnerId != null && act != null && _partnerId != act;
  }

  Future<List<Map<String, dynamic>>> _loadPartners() async {
    final act = context.read<ActiveProfileProvider>().activeProfileId;
    try {
      final rows = await Supabase.instance.client
          .from('user_profiles')
          .select('id,display_name');
      final list = <Map<String, dynamic>>[];
      for (final r in rows) {
        final m = Map<String, dynamic>.from(r);
        if ('${m['id']}' != act) list.add(m);
      }
      return list;
    } catch (e) {
      debugPrint('AskPage partners failed: $e');
      return [];
    }
  }

  void _setPartner(Map<String, dynamic> p) {
    setState(() {
      _partnerId = '${p['id']}';
      _partnerName = '${p['display_name'] ?? ''}';
      _gen++;
      _messages.clear();
      _waiting = false;
      _failed = false;
    });
  }

  Future<void> _autoPartner() async {
    final l = await _loadPartners();
    if (!mounted) return;
    setState(() {
      _partners = l;
      _partnersLoaded = true;
    });
    if (l.length == 1 && !_pairOk()) _setPartner(l.first);
  }

  Future<void> _pickPartner() async {
    final l = await _loadPartners();
    if (!mounted) return;
    setState(() {
      _partners = l;
      _partnersLoaded = true;
    });
    if (l.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(t(context, 'ask.avatar.synastry.need_profile'))),
      );
      return;
    }
    if (l.length == 1) {
      _setPartner(l.first);
      return;
    }
    final p = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final x in l)
              ListTile(
                title: Text('${x['display_name'] ?? ''}'),
                onTap: () => Navigator.pop(ctx, x),
              ),
          ],
        ),
      ),
    );
    if (p != null && mounted) _setPartner(p);
  }

  Future<void> _remember(String raw) async {
    final sm = ScaffoldMessenger.of(context);
    final savedMsg = t(context, 'ask.remember.saved');
    final ctl = TextEditingController(
        text: raw.length > 150 ? raw.substring(0, 150) : raw);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(ctx, 'ask.remember')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t(ctx, 'ask.remember.hint'), style: AppTextStyles.bodySm()),
            const SizedBox(height: 8),
            TextField(controller: ctl, maxLength: 150, minLines: 1, maxLines: 4),
          ],
        ),
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
      if (!await AiConsentService.hasAi()) {
        if (!mounted) return;
        final yes = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(t(ctx, 'ask.remember.consent_title')),
            content: Text(t(ctx, 'ask.remember.consent_body')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(t(ctx, 'ask.remember.consent_accept')),
              ),
            ],
          ),
        );
        if (yes != true || !await AiConsentService.grantAi()) return;
      }
      await AskService.memoryAdd(text);
      sm.showSnackBar(SnackBar(content: Text(savedMsg)));
    } catch (e) {
      debugPrint('AskPage remember failed: $e');
      if (!mounted) return;
      sm.showSnackBar(
          SnackBar(content: Text(t(context, AskService.memoryErrKey(e)))));
    }
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
      listenable: Listenable.merge([askContext, askMode]),
      builder: (context, _) {
        final items = askContext.itemsFor(askMode.value);
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
              textInputAction: TextInputAction.send,
              focusNode: _inputFocus,
              onSubmitted: (_) => _send(),
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
      appBar: AppBar(
        title: Text(t(context, 'ask.title')),
        actions: [
          if (_av)
            IconButton(
              tooltip: t(context, 'notes.title'),
              icon: const Icon(Icons.bookmark_border_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotesPage()),
              ),
            ),
        ],
      ),
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
                      value: 'natal',
                      label: Text(_av
                          ? t(context, 'ask.avatar.natal.name')
                          : t(context, 'ask.mode.natal'))),
                  ButtonSegment(
                      value: 'forecast',
                      label: Text(_av
                          ? t(context, 'ask.avatar.forecast.name')
                          : t(context, 'ask.mode.forecast'))),
                  if (_av)
                    ButtonSegment(
                        value: 'synastry',
                        label: Text(t(context, 'ask.avatar.synastry.name'))),
                ],
                selected: {_mode},
                          onSelectionChanged: (s) {
                askMode.value = s.first; // sıfırlama _onMode'da
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
            if (_av)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(t(context, 'ask.avatar.$_mode.tag'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm()),
              ),
            if (_av && _mode == 'synastry')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: (_partnersLoaded && _partners.isEmpty)
                    ? Text(t(context, 'ask.avatar.synastry.need_profile'),
                        style: AppTextStyles.bodySm())
                    : ActionChip(
                        avatar: const Icon(Icons.people_outline, size: 18),
                        label: Text(_partnerName == null
                            ? t(context, 'ask.avatar.partner.pick')
                            : '${t(context, 'ask.avatar.partner.for')}: $_partnerName'),
                        onPressed: _pickPartner,
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
                    if (_errKey != 'ask.error.quota')
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
/// K34: harf harf görünür; dokununca tamamlanır; reduce-motion'da anında.
class _Typewriter extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback onDone;
  const _Typewriter(
      {super.key, required this.text, this.style, required this.onDone});

  @override
  State<_Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<_Typewriter> {
  Timer? _timer;
  int _n = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations || widget.text.isEmpty) {
      _n = widget.text.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return;
    }
     _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted) return;
      var next = _n + 2;
      if (next >= widget.text.length) {
        _finish();
        return;
      }
      // surrogate çiftini (emoji) bölme
      final c = widget.text.codeUnitAt(next - 1);
      if (c >= 0xD800 && c <= 0xDBFF) next++;
      setState(() => _n = next.clamp(0, widget.text.length));
    });
  }

  void _finish() {
    _timer?.cancel();
    if (_n != widget.text.length) setState(() => _n = widget.text.length);
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _n >= widget.text.length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: done ? null : _finish,
      child: Text(widget.text.substring(0, _n), style: widget.style),
    );
  }
}


/// AV: balonlar sÄ±rayla (balon baÅŸÄ±na daktilo + 450 ms ara); reduce-motion'da anÄ±nda.
class _BubbleSeq extends StatefulWidget {
  final List<String> texts;
  final bool animate;
  final VoidCallback onAllDone;
  final Widget Function(String text, bool animate, VoidCallback onDone, Key key)
      item;
  const _BubbleSeq({
    super.key,
    required this.texts,
    required this.animate,
    required this.onAllDone,
    required this.item,
  });

  @override
  State<_BubbleSeq> createState() => _BubbleSeqState();
}

class _BubbleSeqState extends State<_BubbleSeq> {
  int _shown = 1;
  Timer? _gap;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    if (!widget.animate || MediaQuery.of(context).disableAnimations) {
      _shown = widget.texts.length;
      if (widget.animate) {
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onAllDone());
      }
    }
  }

  void _next() {
    if (!mounted) return;
    if (_shown >= widget.texts.length) {
      widget.onAllDone();
      return;
    }
    _gap?.cancel();
    _gap = Timer(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _shown++);
    });
  }

  @override
  void dispose() {
    _gap?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _shown && i < widget.texts.length; i++)
          widget.item(widget.texts[i], widget.animate && i == _shown - 1, _next,
              ValueKey(i)),
      ],
    );
  }
}
