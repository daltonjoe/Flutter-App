import 'dart:async';
import 'dart:ui' show ImageFilter;
import '../paywall/paywall_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/ask_bridge.dart';
import 'package:flutter/services.dart';
import '../services/reference_names_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
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
import '../services/user_settings_service.dart';
import '../presentation/widgets/components/cosmic_background.dart';
import '../presentation/widgets/components/cosmic_card.dart';
import '../presentation/widgets/components/cosmic_segmented.dart';
import '../presentation/widgets/components/glyph.dart';
import '../presentation/widgets/components/profile_avatar_button.dart';
import '../redesign/ask/ask_hero.dart';
import '../redesign/ask/star_typing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notes_page.dart';

class _Msg {
  final bool mine;
  final String text;
  bool animate; // K34: yalnız yeni gelen yanıt, bitince false
  final List<String>? bubbles; // AV: balon dizisi

  /// Güvenlik / kota / hata kaynaklı sistem mesajı: aksiyon satırı gösterilmez.
  final bool system;
  _Msg(
    this.mine,
    this.text, {
    this.animate = false,
    this.bubbles,
    this.system = false,
  });
}

class AskPage extends StatefulWidget {
  const AskPage({super.key});
  @override
  State<AskPage> createState() => _AskPageState();
}

class _AskPageState extends State<AskPage> {
  final TextEditingController _ctl = TextEditingController();
  late final FocusNode _inputFocus = FocusNode(onKeyEvent: _onInputKey);
  final ScrollController _scroll = ScrollController();
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
  bool _showFirstNote = false; // B7: boş durumda bir kez göster

  @override
  void initState() {
    super.initState();
    askDraft.addListener(_onDraft);
    askMode.addListener(_onMode);
    askBridgeReq.addListener(_onBridge);
    _inputFocus.addListener(_onFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onBridge());
    UserSettingsService.isFlagEnabled('ask_avatars').then((v) {
      if (!mounted) return;
      askAvatarsEnabled.value = v;
      setState(() => _av = v);
      if (v && _mode == 'synastry') _autoPartner();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onDraft());
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      if (!(p.getBool('ask_first_note_seen') ?? false)) {
        setState(() => _showFirstNote = true);
      }
    });
  }

  /// B7: ilk-kez bilgi kartı yalnızca daha önce kapatılmadıysa gösterilir.
  Future<void> _dismissFirstNote() async {
    setState(() => _showFirstNote = false);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('ask_first_note_seen', true);
    } catch (e) {
      debugPrint('AskPage first-note persist failed: $e');
    }
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
    final loc = Provider.of<LanguageProvider>(context).locale.languageCode;
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
    _inputFocus.removeListener(_onFocus);
    _ctl.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
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
                  'profile_a': context
                      .read<ActiveProfileProvider>()
                      .activeProfileId,
                  'profile_b': _partnerId,
                },
              },
            ]
          : askContext.itemsFor(_mode).map((e) => e.toServer()).toList(),
      locale: loc,
      bubbles: _av,
      history: [
        for (final m in last)
          {'role': m.mine ? 'user' : 'assistant', 'text': m.text},
      ],
      profileId: context.read<ActiveProfileProvider>().activeProfileId,
      mode: _mode,
      forecastMonth: _mode == 'forecast' ? _fMonth : null,
    );
    final s = res.safety;
    if (s != null) {
      return _Msg(
        false,
        res.reply ?? (safe[s] ?? safe['fallback']!),
        animate: true,
        system: true,
      );
    }
    final rp = res.reply;
    if (rp == null || rp.trim().isEmpty) {
      return _Msg(false, safe['fallback']!, animate: true, system: true);
    }
    final bl = res.bubbles;
    return _Msg(
      false,
      rp,
      animate: true,
      bubbles: (_av && bl != null && bl.isNotEmpty) ? bl : null,
    );
  }

  KeyEventResult _onInputKey(FocusNode node, KeyEvent e) {
    final enter =
        e.logicalKey == LogicalKeyboardKey.enter ||
        e.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (e is KeyDownEvent &&
        enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _send();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Girişe odaklanınca listenin en yeni mesaja kayması (B4).
  void _onFocus() {
    if (!_inputFocus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
  }

  /// B4: liste `reverse` olduğu için en yeni mesaj offset 0'dadır.
  void _scrollToLatest() {
    if (!mounted || !_scroll.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
      return;
    }
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    try {
      final r = await _reply(text);
      if (!mounted || gen != _gen) return;
      setState(() {
        _messages.add(r);
        _waiting = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
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
      if (e is AstroServiceException && e.code == 'QUOTA') {
        UserSettingsService.isFlagEnabled('paywall').then((on) {
          if (on && mounted) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => const PaywallPage(source: PaywallSource.quota),
              ),
            );
          }
        });
      }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: Row(
                children: [
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
                            child: Text(
                              i.toString().padLeft(2, '0'),
                              style: AppTextStyles.bodyLg(
                                color: AppColors.starlight,
                              ),
                            ),
                          ),
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
                            child: Text(
                              '$i',
                              style: AppTextStyles.bodyLg(
                                color: AppColors.starlight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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
          ],
        ),
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

  /// Öneri kartlarının solundaki gezegen glyph'i — moda göre.
  static const Map<String, List<String>> _suggestGlyphs = {
    'natal': ['sun', 'moon', 'mercury'],
    'forecast': ['jupiter', 'venus', 'saturn'],
    'synastry': ['venus', 'mars', 'moon'],
  };

  Widget _empty(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final glyphs =
        _suggestGlyphs[_mode] ?? const <String>['sun', 'moon', 'mercury'];
    final sugg = [
      t(context, 'ask.suggest.$_mode.1'),
      t(context, 'ask.suggest.$_mode.2'),
      t(context, 'ask.suggest.$_mode.3'),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final minH = (c.maxHeight - AppSpacing.sm - AppSpacing.md).clamp(
          0.0,
          double.infinity,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Klavye açıkken kahraman alanı gizlenir.
                  if (!keyboardOpen)
                    AskHero(
                      mode: _mode,
                      summary: context.watch<ActiveProfileProvider>().summary,
                      month: _fMonth,
                      onPickMonth: _pickMonth,
                      partnerName: _partnerName,
                      partnersEmpty: _partnersLoaded && _partners.isEmpty,
                      onPickPartner: _pickPartner,
                    ),
                  const Spacer(),
                  if (_showFirstNote) ...[
                    _firstNote(context),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  for (var i = 0; i < sugg.length; i++)
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.sm),
                      child: _suggestCard(
                        context,
                        sugg[i],
                        glyphs[i],
                        i,
                        reduce,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _firstNote(BuildContext context) {
    return CosmicCard(
      compact: true,
      blur: false,
      radius: AppRadius.md,
      borderColor: AppColors.borderMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: AskStar(size: 14),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  t(context, 'ask.first_note.body'),
                  style: AppTextStyles.bodySm(color: AppColors.mist),
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _dismissFirstNote,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Text(
                t(context, 'ask.first_note.ok'),
                style: AppTextStyles.bodySm(color: AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestCard(
    BuildContext context,
    String text,
    String glyph,
    int index,
    bool reduce,
  ) {
    final card = CosmicCard(
      compact: true,
      blur: false,
      radius: AppRadius.md,
      padding: EdgeInsets.zero,
      onTap: () => _send(text),
      child: SizedBox(
        height: AppSizes.inputHeight,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            0,
          ),
          child: Row(
            children: [
              Glyph(glyph, size: 20, color: AppColors.gold, decorative: true),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLg(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.mist,
              ),
            ],
          ),
        ),
      ),
    );
    if (reduce) return card;
    // 60 ms kademe, 400 ms süre, 16 px aşağıdan yukarı belirme.
    final dur = 400 + index * 60;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: dur),
      curve: Interval(index * 60 / dur, 1.0, curve: Curves.easeOut),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: card,
    );
  }

  Widget _bubble(BuildContext context, _Msg m) {
    final core = _bubbleCore(context, m);
    // Sistem (güvenlik / hata / kota) mesajlarında aksiyon satırı yoktur.
    if (m.mine || m.text.trim().isEmpty || m.system) return core;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [core, _actions(context, m)],
    );
  }

  /// Normal asistan yanıtının altındaki aksiyon satırı.
  Widget _actions(BuildContext context, _Msg m) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _actionButton(
            context,
            'ask.remember',
            Icons.bookmark_add_outlined,
            () => _remember(m.text),
          ),
          _actionButton(
            context,
            'ask.copy',
            Icons.copy_rounded,
            () => _copy(m.text),
          ),
          TextButton(
            onPressed: () => _reportReply(m),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: Text(
              t(context, 'ask.report'),
              style: AppTextStyles.bodySm(color: AppColors.mist),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String key,
    IconData icon,
    VoidCallback onTap,
  ) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: AppColors.mist),
      label: Text(
        t(context, key),
        style: AppTextStyles.bodySm(color: AppColors.mist),
      ),
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 40),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
    );
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t(context, 'ask.copied'))));
  }

  Future<void> _reportReply(_Msg m) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t(ctx, 'ask.report'), style: AppTextStyles.bodyLg()),
            ),
            for (final r in const [
              'harmful',
              'inaccurate',
              'inappropriate',
              'other',
            ])
              ListTile(
                title: Text(t(ctx, 'ask.report.$r')),
                onTap: () => Navigator.pop(ctx, r),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    final av = _mode == 'forecast'
        ? 'forecast'
        : (_mode == 'synastry' ? 'synastry' : 'natal');
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw StateError('no user');
      var ex = m.text.trim();
      if (ex.length > 600) ex = ex.substring(0, 600);
      await Supabase.instance.client.from('ai_reports').insert({
        'user_id': uid,
        'avatar': av,
        'reason': reason,
        'reply_excerpt': ex,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(context, 'ask.report.sent'))));
    } catch (e) {
      debugPrint('AskPage report failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(context, 'ask.error'))));
    }
  }

  Widget _bubbleCore(BuildContext context, _Msg m) {
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
    final maxW = MediaQuery.of(context).size.width * 0.80;
    if (m.mine) {
      // Kullanıcı mesajı: sağda, Navy Raised hap.
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxW),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.navyRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Text(m.text, style: AppTextStyles.bodyLg()),
        ),
      );
    }
    // Asistan: balonsuz, sola yaslı — üstte küçük altın ✦.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AskStar(size: 14),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: m.animate
                  ? _Typewriter(
                      key: ObjectKey(m),
                      text: m.text,
                      style: AppTextStyles.bodyLg(),
                      onDone: () => m.animate = false,
                    )
                  : Text(m.text, style: AppTextStyles.bodyLg()),
            ),
          ],
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
      item: (i, txt, anim, done, k) => _box(context, i, txt, anim, done, k),
    );
  }

  Widget _box(
    BuildContext context,
    int index,
    String text,
    bool animate,
    VoidCallback onDone,
    Key k,
  ) {
    final maxW = MediaQuery.of(context).size.width * 0.82;
    return Align(
      key: k,
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            index == 0
                ? const AskStar(size: 14)
                : const SizedBox(width: 14, height: 14),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: animate
                  ? _Typewriter(
                      text: text,
                      style: AppTextStyles.bodyMd(),
                      onDone: onDone,
                    )
                  : Text(text, style: AppTextStyles.bodyMd()),
            ),
          ],
        ),
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
        SnackBar(content: Text(t(context, 'ask.avatar.synastry.need_profile'))),
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
      text: raw.length > 150 ? raw.substring(0, 150) : raw,
    );
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
            TextField(
              controller: ctl,
              maxLength: 150,
              minLines: 1,
              maxLines: 4,
            ),
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
      await AskService.memoryAdd(text);
      sm.showSnackBar(SnackBar(content: Text(savedMsg)));
    } catch (e) {
      debugPrint('AskPage remember failed: $e');
      if (!mounted) return;
      sm.showSnackBar(
        SnackBar(content: Text(t(context, AskService.memoryErrKey(e)))),
      );
    }
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => Center(
              child: Container(
                height: AppSizes.chipHeight,
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.cardGap,
                  end: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navyRaised,
                  borderRadius: AppRadius.pillBr,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        items[i].displayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.chip(color: AppColors.gold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Semantics(
                      button: true,
                      label: t(context, 'ask.context.remove'),
                      child: InkWell(
                        borderRadius: AppRadius.pillBr,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          askContext.remove(items[i].id);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.mist,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _composer(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Padding(
      // Alt boşluk composer sütunundaki son SizedBox'a bırakıldı (B2).
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      // Sayfadaki tek BackdropFilter: cam hap.
      child: ClipRRect(
        borderRadius: AppRadius.pillBr,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              0,
              6,
              0,
            ),
            decoration: BoxDecoration(
              color: AppColors.navyDeep.withValues(alpha: 0.80),
              borderRadius: AppRadius.pillBr,
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctl,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    focusNode: _inputFocus,
                    onSubmitted: (_) => _send(),
                    style: AppTextStyles.bodyLg(),
                    decoration: InputDecoration(
                      hintText: t(context, 'ask.placeholder'),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _ctl,
                    builder: (context, v, _) {
                      final active = v.text.trim().isNotEmpty && !_waiting;
                      return Semantics(
                        button: true,
                        enabled: active,
                        label: t(context, 'ask.send'),
                        child: GestureDetector(
                          onTap: active ? () => _send() : null,
                          child: AnimatedContainer(
                            duration: reduce
                                ? Duration.zero
                                : const Duration(milliseconds: 200),
                            width: AppSizes.sectionIconBadge,
                            height: AppSizes.sectionIconBadge,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? AppColors.gold
                                  : AppColors.navyRaised,
                              border: Border.all(
                                color: active
                                    ? AppColors.gold
                                    : AppColors.hairline,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 20,
                              color: active ? AppColors.onGold : AppColors.mist,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ReferenceNamesService>();
    final reduce = MediaQuery.disableAnimationsOf(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final msgs = _messages.reversed.toList();
    final extra = _waiting ? 1 : 0;
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t(context, 'ask.title')),
          actions: [
            if (_av)
              IconButton(
                tooltip: t(context, 'notes.title'),
                icon: const Icon(Icons.bookmark_border_rounded),
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const NotesPage())),
              ),
            const ProfileAvatarButton(),
          ],
        ),
        body: SafeArea(
          top: false,
          // Alt güvenli alan bottomNavInset içinde sayılıyor (B2): çift sayım olmasın.
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: CosmicSegmented<String>(
                  selected: _mode,
                  onChanged: (v) => askMode.value = v, // sıfırlama _onMode'da
                  items: [
                    CosmicSegment(
                      value: 'natal',
                      glyph: 'moon',
                      label: _av
                          ? t(context, 'ask.avatar.natal.name')
                          : t(context, 'ask.mode.natal'),
                    ),
                    CosmicSegment(
                      value: 'forecast',
                      glyph: 'mercury',
                      label: _av
                          ? t(context, 'ask.avatar.forecast.name')
                          : t(context, 'ask.mode.forecast'),
                    ),
                    if (_av)
                      CosmicSegment(
                        value: 'synastry',
                        glyph: 'venus',
                        label: t(context, 'ask.avatar.synastry.name'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: AnimatedSwitcher(
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  child: Text(
                    t(context, 'ask.avatar.$_mode.tag'),
                    key: ValueKey<String>(_mode),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm(color: AppColors.mist),
                  ),
                ),
              ),
              Expanded(
                child: (_messages.isEmpty && !_waiting)
                    ? GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: _empty(context),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        itemCount: msgs.length + extra,
                        itemBuilder: (c, i) {
                          if (_waiting && i == 0) return const StarTyping();
                          return _bubble(c, msgs[i - extra]);
                        },
                      ),
              ),
              if (_failed)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t(context, _errKey),
                          style: AppTextStyles.bodySm(
                            color: AppColors.statusDanger,
                          ),
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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: Text(
                    t(context, 'ask.lang_reset'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm(),
                  ),
                ),
              _contextStrip(context),
              _composer(context),
              // Klavye kapalıyken yüzen çubuğun üstünde 12 px boşluk bırakır
              // (bottomNavInset güvenli alanı da içerir); klavye açıkken
              // Scaffold inset'i klavyeyi karşılar, yalnız 12 px pay kalır.
              SizedBox(
                height: keyboardOpen
                    ? AppSpacing.cardGap
                    : AppSizes.bottomNavInset(context) + AppSpacing.cardGap,
              ),
            ],
          ),
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
  const _Typewriter({
    super.key,
    required this.text,
    this.style,
    required this.onDone,
  });

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
  final Widget Function(
    int index,
    String text,
    bool animate,
    VoidCallback onDone,
    Key key,
  )
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
          widget.item(
            i,
            widget.texts[i],
            widget.animate && i == _shown - 1,
            _next,
            ValueKey(i),
          ),
      ],
    );
  }
}
