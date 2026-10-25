import 'dart:async';
import 'dart:ui' show ImageFilter;
import '../paywall/paywall_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/ask_bridge.dart';
import 'package:flutter/services.dart';
import '../services/reference_names_service.dart';
import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_typography.dart';
import '../i18n/app_localizations.dart';
import '../providers/ask_context_provider.dart';
import '../providers/language_provider.dart';
import '../services/ask_service.dart';
import '../services/chat_store.dart';
import '../services/ad_service.dart';
import '../services/astro_service.dart';
import '../providers/active_profile_provider.dart';
import '../providers/ask_draft.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../services/user_settings_service.dart';
import '../presentation/widgets/components/cosmic_background.dart';
import '../presentation/widgets/components/cosmic_card.dart';
import '../presentation/widgets/components/cosmic_cta_button.dart';
import '../presentation/widgets/components/cosmic_segmented.dart';
import '../presentation/widgets/components/glyph.dart';
import '../presentation/widgets/components/profile_avatar_button.dart';
import '../redesign/ask/ask_hero.dart';
import '../redesign/ask/star_typing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notes_page.dart';
import 'chat_history_page.dart';

class _Msg {
  final bool mine;
  final String text;
  bool animate; // K34: yalnız yeni gelen yanıt, bitince false
  final List<String>? bubbles; // AV: balon dizisi

  /// Güvenlik / kota / hata kaynaklı sistem mesajı: aksiyon satırı gösterilmez.
  final bool system;

  /// V4c2: mesaj zamani (ms); eski kayitlarda null.
  int? ts;
  _Msg(
    this.mine,
    this.text, {
    this.animate = false,
    this.bubbles,
    this.system = false,
    this.ts,
  });
}

/// `credit_status` yanıtı: bakiye ve bugün kalan reklam hakkı (`ad_left_today`).
/// `adLeft` null ise alan yok/ayrıştırılamadı → bilinmiyor, reklam açık kalır.
typedef _CreditStatus = ({int? balance, int? adLeft, String? tier, int? dailyLeft});

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
  bool _creditsDialogOpen = false; // tek aktif reklam akışı kilidi
  String _lastText = '';
  String _errKey = 'ask.error';
  String? _loc;
  bool _langReset = false;
  String? _sid; // V4: kayitliysa sohbet kimligi
  String? _title;
  bool _purged = false;
  String? _ovA; // V4b: acilan kayitli sohbetin profilleri (global profil degismez)
  String? _ovB;
  String? _ovName;
  bool _ro = false; // V4b: silinmis kisi, yalniz okunur
  int _gen = 0;
  String _mode = askMode.value;
  String? _fMonth; // YYYY-MM
  bool _av = false; // feature_flags.ask_avatars
  String? _partnerId;
  String? _partnerName;
  String? _act; // V3: aktif profil degisimini izler
  bool _actSet = false;
  List<Map<String, dynamic>> _partners = [];
  bool _partnersLoaded = false;
  _CreditStatus? _credit; // K39 kalan hak notu
  bool _showFirstNote = false; // B7: boş durumda bir kez göster

  @override
  void initState() {
    super.initState();
    askDraft.addListener(_onDraft);
    askMode.addListener(_onMode);
    askBridgeReq.addListener(_onBridge);
    _inputFocus.addListener(_onFocus);
    _refreshCredit();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onBridge());
    UserSettingsService.isFlagEnabled('ask_avatars').then((v) {
      if (!mounted) return;
      askAvatarsEnabled.value = v;
      setState(() => _av = v);
      if (v && _mode == 'synastry') _autoPartner();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onDraft());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChat());
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
    if (_locked) return;
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

  /// Y1: cevap beklenirken ve yazilirken mod sekmeleri kilitli.
  bool get _locked =>
      _waiting ||
      (_messages.isNotEmpty && !_messages.last.mine && _messages.last.animate);

  /// Y1: yazimi biten mesaj kilidi acar; yeniden cizim istenir.
  void _animDone(_Msg m) {
    m.animate = false;
    Future<void>.microtask(() {
      if (mounted) setState(() {});
    });
  }

  void _onMode() {
    final m = askMode.value;
    if (!mounted || m == _mode) return;
    if (_locked) {
      askMode.value = _mode;
      return;
    }
    if (m == 'synastry') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoPartner());
    }
    setState(() {
      _gen++;
      _mode = m;
      _clearOv();
      _fMonth = null;
      _messages.clear();
      _waiting = false;
      _refreshCredit();
      _failed = false;
      _langReset = false;
      _lastText = '';
    });
    _loadChat();
  }

  /// V3: sohbet anahtari (hesap, mod, profil veya sirali cift); null = saklama yok.
  /// V4c: kayitli sohbetin gorulen profil surumu.
  String? _pv;

  /// V4c: birth_date, birth_time, birth_time_known, latitude, longitude, timezone birlesimi; okunamazsa null.
  Future<String?> _pvNow() async {
    const cols = <String>[
      'birth_date',
      'birth_time',
      'birth_time_known',
      'latitude',
      'longitude',
      'timezone',
    ];
    try {
      final ids = <String?>[_a(), if (_mode == 'synastry') _b()];
      final parts = <String>[];
      for (final id in ids) {
        if (id == null) return null;
        final row = await Supabase.instance.client
            .from('user_profiles')
            .select(cols.join(', '))
            .eq('id', id)
            .maybeSingle();
        if (row == null) return null;
        parts.add([for (final k in cols) '${row[k]}'].join('|'));
      }
      return parts.join('#');
    } catch (e) {
      debugPrint('AskPage pv failed: $e');
      return null;
    }
  }

  /// V4c: kayitli surum guncelden farkliysa bir kez uyarir; eski mesajlar degismez.
  Future<void> _checkPv() async {
    if (_ro) return;
    final old = _pv;
    final gen = _gen;
    final cur = await _pvNow();
    if (!mounted || gen != _gen || cur == null || cur == old) return;
    if (old != null) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(t(c, 'ask.profile_updated')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(t(c, 'ask.profile_updated_ok')),
            ),
          ],
        ),
      );
      if (!mounted || gen != _gen) return;
    }
    _pv = cur;
    final k = _chatKey();
    final ak = _archKey();
    if (k != null) await ChatStore.setPv(k, cur, _sid);
    if (ak != null) await ChatStore.setPv(ak, cur, _sid);
  }

  /// V4c2: msgs ters sirali; j. mesaj onceki mesajdan farkli gunde mi.
  bool _newDay(List<_Msg> ms, int j) {
    if (j + 1 >= ms.length) return false;
    final a = ms[j].ts;
    final p = ms[j + 1].ts;
    if (a == null || p == null) return false;
    final x = DateTime.fromMillisecondsSinceEpoch(a);
    final y = DateTime.fromMillisecondsSinceEpoch(p);
    return x.year != y.year || x.month != y.month || x.day != y.day;
  }

  Widget _daySep(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Text('$dd.$mm.${d.year}', style: AppTextStyles.bodySm(color: AppColors.mist)),
      ),
    );
  }

  String? _chatKey() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final act = _a();
    if (uid == null || act == null) {
      return null;
    }
    if (_mode == 'synastry') {
      return _pairOk() ? ChatStore.key(uid, _mode, '${act}_${_b()}') : null;
    }
    return ChatStore.key(uid, _mode, act);
  }

  String _chatNames() {
    if (_ovName != null) return _ovName!;
    final a = context.read<ActiveProfileProvider>().summary?.name ?? '';
    if (_mode != 'synastry') return a;
    return '$a \u2192 ${_partnerName ?? ''}';
  }

  ChatRecord _record() {
    return ChatRecord(
      msgs: [
        for (final m in _messages)
          {'m': m.mine, 't': m.text, 'b': m.bubbles, 's': m.system, 'ts': m.ts},
      ],
      loc: _loc ?? '',
      updated: DateTime.now().millisecondsSinceEpoch,
      month: _fMonth,
      sid: _sid,
      title: _title,
      pa: _a(),
      pb: _mode == 'synastry' ? _b() : null,
      pn: _chatNames(),
      pv: _pv,
    );
  }

  String? _archKey() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final sid = _sid;
    if (uid == null || sid == null) return null;
    return ChatStore.archKey(uid, _mode, sid);
  }

  /// Aktif kaydi ve (kayitliysa) arsiv kaydini yazar.
  Future<void> _flush() async {
    final k = _chatKey();
    if (k == null || _messages.isEmpty) return;
    final pv = _pv ?? await _pvNow();
    if (k != _chatKey() || _messages.isEmpty) return;
    _pv ??= pv;
    final r = _record();
    await ChatStore.save(k, r);
    final ak = _archKey();
    if (ak != null) await ChatStore.save(ak, r);
  }

  void _persist() {
    unawaited(_flush());
  }

  /// V9a: cevap istegi baslatan sohbetin kaydina yazilir; kullanici hala
  /// o sohbetteyse ekrana da duser.
  Future<void> _lateReply(String? ck, String md, _Msg r) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (ck == null || uid == null) return;
    if (_ovA == null && md == _mode && _chatKey() == ck) {
      setState(() {
        _messages.add(r);
      });
      _persist();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
      return;
    }
    await ChatStore.appendMsg(ck, uid, md, {
      'm': r.mine,
      't': r.text,
      'b': r.bubbles,
      's': r.system,
      'ts': r.ts,
    });
  }

  Future<void> _loadChat() async {
    _sid = null;
    _title = null;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (!_purged && uid != null) {
      _purged = true;
      await ChatStore.purgeStale(uid, DateTime.now());
    }
    final k = _chatKey();
    final gen = _gen;
    final rec = k == null ? null : await ChatStore.load(k);
    if (!mounted || gen != _gen || rec == null || rec.loc != _loc) {
      return;
    }
    setState(() {
      _messages
        ..clear()
        ..addAll(_msgsOf(rec));
      if (_mode == 'forecast') {
        _fMonth = rec.month;
      }
      _sid = rec.sid;
      _title = rec.title;
      _pv = rec.pv;
    });
    await _checkPv();
  }

  Future<String?> _lastPartnerId() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final act = context.read<ActiveProfileProvider>().activeProfileId;
    if (uid == null || act == null) {
      return Future<String?>.value(null);
    }
    return ChatStore.lastPartner(uid, act);
  }

  void _rememberPartner() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final act = context.read<ActiveProfileProvider>().activeProfileId;
    final pid = _partnerId;
    if (uid == null || act == null || pid == null) {
      return;
    }
    unawaited(ChatStore.setLastPartner(uid, act, pid));
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
      _refreshCredit();
      _failed = false;
      _langReset = true;
      _clearOv();
      _sid = null;
      _title = null;
      final ck = _chatKey();
      if (ck != null) {
        unawaited(ChatStore.remove(ck));
      }
    }
    final act = Provider.of<ActiveProfileProvider>(context).activeProfileId;
    if (_actSet && act != _act) {
      _gen++;
      _messages.clear();
      _waiting = false;
      _failed = false;
      _fMonth = null;
      _clearOv();
      _partnerId = null;
      _partnerName = null;
      _partners = [];
      _partnersLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _loadChat();
        if (_mode == 'synastry') {
          _autoPartner();
        }
      });
    }
    _act = act;
    _actSet = true;
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
                  'profile_a': _a(),
                  'profile_b': _b(),
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
      profileId: _a(),
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
    final ck = _chatKey();
    final md = _mode;
    final retry = override != null && _failed;
    setState(() {
      if (!retry) {_messages.add(_Msg(true, text, ts: DateTime.now().millisecondsSinceEpoch));}
      _waiting = true;
      _failed = false;
      _langReset = false;
    });
    _persist();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    try {
      final r = await _reply(text);
      if (!mounted) return;
      if (gen != _gen) {
        r.ts = DateTime.now().millisecondsSinceEpoch;
        await _lateReply(ck, md, r);
        return;
      }
      setState(() {
        _messages.add(r..ts = DateTime.now().millisecondsSinceEpoch);
        _waiting = false;
        _refreshCredit();
      });
      _persist();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    } catch (e) {
      debugPrint('AskPage reply failed: $e');
      if (!mounted || gen != _gen) return;
      final code = e is AstroServiceException ? e.code : '';
      setState(() {
        _waiting = false;
        _refreshCredit();
        _failed = true;
        _lastText = text;
        _errKey = AskService.errKeyFor(code);
      });
      if (code == 'QUOTA' || code == 'DAILY_LIMIT_TRIAL') {
        UserSettingsService.isFlagEnabled('paywall').then((on) {
          if (on && mounted) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => const PaywallPage(source: PaywallSource.quota),
              ),
            );
          }
        });
      } else if (code == 'CREDITS_EMPTY') {
        _showCreditsEmptyDialog();
      }
    }
  }

  /// Kredi bittiğinde geçici diyalog (kredi ekranları gelene kadar).
  /// Tek aktif akış: kilit bayrağı ile yeniden açılış engellenir.
  Future<void> _showCreditsEmptyDialog() async {
    if (_creditsDialogOpen) return;
    _creditsDialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => _CreditsEmptyDialog(
          readStatus: _readCreditStatus,
          onGoPremium: _goPremium,
          onSignIn: _goLinkAccount,
          onCredited: _onRewardCredited,
        ),
      );
    } finally {
      _creditsDialogOpen = false;
    }
  }

  /// Sunucu kredi durumunu okur: bakiye + bugün kalan reklam hakkı
  /// (`ad_left_today`). İstemci krediyi ASLA kendi eklemez; yalnızca sunucu
  /// değerini yansıtır. Alan yok/ayrıştırılamazsa null döner (bilinmiyor).
  Future<_CreditStatus> _readCreditStatus() async {
    try {
      final r = await Supabase.instance.client.rpc('credit_status');
      final m = r is Map
          ? r
          : (r is List && r.isNotEmpty && r.first is Map ? r.first : null);
      if (m is Map) {
        final b = m['balance'];
        final a = m['ad_left_today'];
        final dlRaw = m['daily_limit'];
        final duRaw = m['daily_used'];
        final dl = int.tryParse('$dlRaw');
        final du = int.tryParse('$duRaw');
        return (
          balance: b is int ? b : (b == null ? null : int.tryParse('$b')),
          adLeft: a is int ? a : (a == null ? null : int.tryParse('$a')),
          tier: m['tier'] is String ? m['tier'] as String : null,
          dailyLeft: (dl == null || du == null) ? null : (dl - du < 0 ? 0 : dl - du),
        );
      }
    } catch (e) {
      debugPrint('AskPage credit_status failed: $e');
    }
    return (balance: null, adLeft: null, tier: null, dailyLeft: null);
  }

  void _goPremium() {
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

  void _goLinkAccount() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/onboarding/link-account');
  }

  /// Ödül sunucuda doğrulandığında: hata satırını temizleyip girişe odaklanır.
  void _onRewardCredited() {
    _refreshCredit();
    if (!mounted) return;
    setState(() {
      _failed = false;
      _errKey = 'ask.error';
    });
    _inputFocus.requestFocus();
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
      useRootNavigator: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.cardGap),
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
              padding: const EdgeInsets.all(AppSpacing.md),
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
    });
    _persist();
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

  /// Y4: cevabi bos satirla ayrilan paragraflara boler.
  static List<String> _paragraphs(String s) => [
    for (final p in s.split(RegExp(r'\n\s*\n')))
      if (p.trim().isNotEmpty) p.trim(),
  ];

  Widget _bubbleCore(BuildContext context, _Msg m) {
    if (!m.mine) {
      final seq = (m.bubbles != null && m.bubbles!.isNotEmpty)
          ? m.bubbles!
          : _paragraphs(m.text);
      if (seq.length > 1 || (m.bubbles?.isNotEmpty ?? false)) {
        return _bubbleSeq(context, m, seq);
      }
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
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
                      onDone: () => _animDone(m),
                    )
                  : Text(m.text, style: AppTextStyles.bodyLg()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubbleSeq(BuildContext context, _Msg m, List<String> texts) {
    return _BubbleSeq(
      key: ObjectKey(m),
      texts: texts,
      animate: m.animate,
      onAllDone: () => _animDone(m),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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

  /// V4: sohbeti kaydedildi olarak isaretler; baslik ilk sorunun ilk 40 karakteri.
  void _markSaved() {
    if (_messages.isEmpty) return;
    final first =
        _messages.firstWhere((m) => m.mine, orElse: () => _messages.first).text;
    final s = first.replaceAll(RegExp(r'\s+'), ' ').trim();
    setState(() {
      _sid ??= DateTime.now().microsecondsSinceEpoch.toString();
      _title ??= s.length > 40 ? '${s.substring(0, 40).trimRight()}...' : s;
    });
  }

  void _resetChat() {
    final k = _ovA == null ? _chatKey() : null;
    setState(() {
      _clearOv();
      _gen++;
      _messages.clear();
      _waiting = false;
      _failed = false;
      _langReset = false;
      _lastText = '';
      _sid = null;
      _title = null;
    });
    if (k != null) {
      unawaited(ChatStore.remove(k));
    }
  }

  Future<void> _newChat() async {
    if (_messages.isEmpty || _waiting) return;
    if (_sid == null) {
      final r = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(t(c, 'ask.unsaved')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(t(c, 'common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, 'del'),
              child: Text(t(c, 'ask.delete')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, 'save'),
              child: Text(t(c, 'ask.save')),
            ),
          ],
        ),
      );
      if (!mounted || r == null) return;
      if (r == 'save') {
        _markSaved();
        await _flush();
      }
    }
    if (!mounted) return;
    _resetChat();
  }

  String? _a() =>
      _ovA ?? context.read<ActiveProfileProvider>().activeProfileId;

  String? _b() => _ovB ?? _partnerId;

  void _clearOv() {
    _pv = null;
    _ovA = null;
    _ovB = null;
    _ovName = null;
    _ro = false;
  }

  List<_Msg> _msgsOf(ChatRecord r) {
    return [
      for (final m in r.msgs)
        _Msg(
          m['m'] == true,
          '${m['t']}',
          bubbles: (m['b'] as List?)?.map((e) => '$e').toList(),
          system: m['s'] == true,
          ts: (m['ts'] as num?)?.toInt(),
        ),
    ];
  }

  /// V4b: gecmisten secilen kayitli sohbeti, global profili degistirmeden acar.
  void _openSaved(HistoryPick p) {
    final r = p.rec;
    setState(() {
      _gen++;
      _waiting = false;
      _failed = false;
      _langReset = false;
      _lastText = '';
      _ovA = r.pa;
      _ovB = r.pb;
      _ovName = r.pn;
      _ro = p.deleted;
      _sid = r.sid;
      _title = r.title;
      _pv = r.pv;
      if (_mode == 'forecast') _fMonth = r.month;
      _messages
        ..clear()
        ..addAll(_msgsOf(r));
    });
    unawaited(_checkPv());
  }

  Future<void> _openHistory() async {
    if (_messages.isNotEmpty && _sid == null) {
      await _newChat();
      if (!mounted || (_messages.isNotEmpty && _sid == null)) return;
    }
    final nav = Navigator.of(context);
    final pick = await nav.push<HistoryPick>(
      MaterialPageRoute<HistoryPick>(
        builder: (_) => ChatHistoryPage(mode: _mode),
      ),
    );
    if (!mounted) return;
    if (pick != null) {
      _openSaved(pick);
      return;
    }
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final sid = _sid;
    if (uid == null || sid == null) return;
    final rec = await ChatStore.load(ChatStore.archKey(uid, _mode, sid));
    if (!mounted) return;
    if (rec == null) {
      _resetChat();
    } else {
      setState(() => _title = rec.title);
    }
  }

  Widget _roNote(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              t(context, 'ask.person_deleted'),
              style: AppTextStyles.bodyMd(),
            ),
          ),
        ],
      ),
    );
  }

  bool _pairOk() {
    final a = _a();
    final b = _b();
    return b != null && a != null && b != a;
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
      _clearOv();
      _partnerId = '${p['id']}';
      _partnerName = '${p['display_name'] ?? ''}';
      _gen++;
      _messages.clear();
      _waiting = false;
      _refreshCredit();
      _failed = false;
    });
    _loadChat();
    _rememberPartner();
  }

  Future<void> _autoPartner() async {
    final l = await _loadPartners();
    if (!mounted) return;
    setState(() {
      _partners = l;
      _partnersLoaded = true;
    });
    if (_pairOk()) return;
    final lastId = await _lastPartnerId();
    if (!mounted) return;
    for (final p in l) {
      if ('${p['id']}' == lastId) {
        _setPartner(p);
        return;
      }
    }
    if (l.length == 1) _setPartner(l.first);
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

  Future<void> _refreshCredit() async {
    final s = await _readCreditStatus();
    if (!mounted) return;
    setState(() => _credit = s);
  }

  Widget _creditNote(BuildContext context) {
    final c = _credit;
    if (c == null) return const SizedBox.shrink();
    String? key;
    int? n;
    if (c.tier == 'free' || c.balance != null) {
      if ((c.balance ?? 0) > 0) {
        key = 'ask.credits.left';
        n = c.balance;
      } else if (c.balance == 0 && c.adLeft != null) {
        key = 'ask.credits.left_ads';
        n = c.adLeft;
      }
    } else if (c.dailyLeft != null) {
      key = 'ask.credits.left_daily';
      n = c.dailyLeft;
    }
    if (key == null || n == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: Text(
        t(context, key).replaceAll('{n}', '$n'),
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _composer(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_creditNote(context), _composerPill(context)],
    );
  }

  Widget _composerPill(BuildContext context) {
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
            IconButton(
              tooltip: t(context, 'ask.history'),
              icon: const Icon(Icons.history_rounded),
              onPressed: _openHistory,
            ),
            if (_av)
              IconButton(
                tooltip: t(context, 'notes.title'),
                icon: const Icon(Icons.bookmark_border_rounded),
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const NotesPage())),
              ),
            if (_messages.isNotEmpty)
              IconButton(
                tooltip: t(context, _sid == null ? 'ask.save' : 'ask.saved'),
                icon: Icon(
                  _sid == null
                      ? Icons.save_outlined
                      : Icons.check_circle_outline_rounded,
                ),
                onPressed: _sid == null
                    ? () {
                        _markSaved();
                        _persist();
                      }
                    : null,
              ),
            if (_messages.isNotEmpty)
              IconButton(
                tooltip: t(context, 'ask.new_chat'),
                icon: const Icon(Icons.add_comment_outlined),
                onPressed: _waiting ? null : _newChat,
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
                child: IgnorePointer(ignoring: _locked, child: AnimatedOpacity(opacity: _locked ? 0.5 : 1.0, duration: AppMotion.chipFill, child: CosmicSegmented<String>(
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
                ))),
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
                          final m = msgs[i - extra];
                          final bub = _bubble(c, m);
                          if (_mode != 'forecast' || !_newDay(msgs, i - extra)) {
                            return bub;
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [_daySep(m.ts!), bub],
                          );
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
                      if (_errKey != 'ask.error.quota' &&
                          _errKey != 'ask.error.credits' &&
                          _errKey != 'ask.error.daily_trial' &&
                          _errKey != 'ask.error.daily_pro')
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
              _ro ? _roNote(context) : _composer(context),
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
    _timer = Timer.periodic(AppMotion.typewriterTick, (_) {
      if (!mounted) return;
      var next = _n + AppMotion.typewriterCharsPerTick;
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
    _gap = Timer(AppMotion.bubbleGap, () {
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

/// Geçici "kredi bitti" diyaloğu (21c kredi ekranları gelene kadar).
///
/// Desteklenen platform (kayıtlı veya misafir): ödüllü reklam; misafire ayrıca
/// "giriş yap" seçeneği sunulur. Web/masaüstü: yalnızca Premium. Kredi hiçbir
/// durumda istemcide eklenmez; yalnızca sunucu bakiyesi yoklanır.
class _CreditsEmptyDialog extends StatefulWidget {
  final Future<_CreditStatus> Function() readStatus;
  final VoidCallback onGoPremium;
  final VoidCallback onSignIn;
  final VoidCallback onCredited;
  const _CreditsEmptyDialog({
    required this.readStatus,
    required this.onGoPremium,
    required this.onSignIn,
    required this.onCredited,
  });

  @override
  State<_CreditsEmptyDialog> createState() => _CreditsEmptyDialogState();
}

class _CreditsEmptyDialogState extends State<_CreditsEmptyDialog> {
  bool _busy = false; // reklam gösteriliyor / ödül doğrulanıyor
  String? _noteKey; // 'ask.ad.unavailable' | 'ask.credits.verifying'
  int? _adLeft; // bugün kalan reklam hakkı; null = bilinmiyor

  @override
  void initState() {
    super.initState();
    _refreshAdLeft();
  }

  /// Tek seferlik okuma: kalan reklam hakkını öğrenip butonu buna göre kilitler.
  /// Yoklama DÖNGÜSÜ değildir; yalnızca açılışta bir kez okunur.
  Future<void> _refreshAdLeft() async {
    final st = await widget.readStatus();
    if (!mounted || st.adLeft == null) return;
    setState(() => _adLeft = st.adLeft);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isGuest = user?.isAnonymous ?? true;
    // Misafir de kayıtlı gibi reklam izler (K6); giriş yönlendirmesi ek seçenek.
    final canAd = AdService.supported && user?.id != null;
    final guestAd = AdService.supported && isGuest && user?.id != null;
    // Günlük reklam hakkı dolduysa reklam yolu kapanır (Premium/giriş açık).
    final adBlocked = canAd && _adLeft == 0;
    final primaryKey = canAd
        ? 'ask.credits.watch_ad'
        : 'ask.credits.go_premium';
    final noteKey = _noteKey ?? (adBlocked ? 'ask.credits.ad_limit' : null);

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t(context, 'ask.error.credits'), style: AppTextStyles.bodyLg()),
          if (noteKey != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              t(context, noteKey),
              style: AppTextStyles.bodySm(color: AppColors.mist),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          CosmicCtaButton(
            label: t(context, primaryKey),
            disabled: _busy || adBlocked,
            onTap: () {
              if (canAd) {
                _watchAd();
              } else {
                Navigator.of(context).pop();
                widget.onGoPremium();
              }
            },
          ),
          if (canAd) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onGoPremium();
                    },
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                t(context, 'ask.credits.go_premium'),
                style: AppTextStyles.bodySm(color: AppColors.gold),
              ),
            ),
          ],
          // Misafir: reklamın yanında giriş yönlendirmesi (ek seçenek).
          if (guestAd) ...[
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onSignIn();
                    },
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                t(context, 'ask.credits.signin_for_ad'),
                style: AppTextStyles.bodySm(color: AppColors.gold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _watchAd() async {
    if (_busy) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() {
      _busy = true;
      _noteKey = null;
    });
    final st0 = await widget.readStatus();
    if (!mounted) return;
    final before = st0.balance;
    if (st0.adLeft != null) _adLeft = st0.adLeft;
    RewardedResult res;
    try {
      res = await AdService.showRewarded(userId: uid);
    } catch (e) {
      debugPrint('AskPage rewarded failed: $e');
      res = RewardedResult.error;
    }
    if (!mounted) return;
    if (res == RewardedResult.unavailable) {
      setState(() {
        _busy = false;
        _noteKey = 'ask.ad.unavailable';
      });
      return;
    }
    if (res != RewardedResult.shown) {
      setState(() => _busy = false);
      return;
    }
    // Kredi istemcide EKLENMEZ: sunucu SSV ile verir; bakiyeyi kısa aralıklarla
    // en fazla 6 kez (1.5 sn) yokla; artarsa diyalog kapanır.
    setState(() => _noteKey = 'ask.credits.verifying');
    var credited = false;
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      final st = await widget.readStatus();
      if (st.adLeft != null) _adLeft = st.adLeft;
      final now = st.balance;
      if (before != null && now != null && now > before) {
        credited = true;
        break;
      }
    }
    if (!mounted) return;
    if (credited) {
      Navigator.of(context).pop();
      widget.onCredited();
      return;
    }
    setState(() {
      _busy = false;
      // Limit dolduysa (bakiye artmadı, hak kalmadı) doğrulama yerine limit metni.
      _noteKey = _adLeft == 0
          ? 'ask.credits.ad_limit'
          : 'ask.credits.verifying';
    });
  }
}
