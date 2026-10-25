// lib/screens/onboarding/onboarding_chat_page.dart
// S10c — son sohbet: sıralı balonlar, seçenekler, bildirim izni, puan isteği.
// Bildirim GÖNDERİLMEZ: yalnız izin istenir. Serbest metin kutusu yoktur.

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../models/onboarding_profile.dart';
import '../../presentation/widgets/components/cosmic_background.dart';
import '../../presentation/widgets/components/cosmic_chip.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../redesign/ask/star_typing.dart';
import '../../services/ad_service.dart';

// ── Sabit anahtar tabloları (id → tam anahtar; birleştirme yok) ──────────

const Map<String, String> _c1Opt = {
  'self': 'onboarding.chat.c1.opt.self',
  'intentions': 'onboarding.chat.c1.opt.intentions',
  'soulmate': 'onboarding.chat.c1.opt.soulmate',
  'love': 'onboarding.chat.c1.opt.love',
  'horoscope': 'onboarding.chat.c1.opt.horoscope',
  'learn': 'onboarding.chat.c1.opt.learn',
  'other': 'onboarding.chat.c1.opt.other',
};

const Map<String, String> _c1Reply = {
  'self': 'onboarding.chat.c1.reply.self',
  'intentions': 'onboarding.chat.c1.reply.intentions',
  'soulmate': 'onboarding.chat.c1.reply.soulmate',
  'love': 'onboarding.chat.c1.reply.love',
  'horoscope': 'onboarding.chat.c1.reply.horoscope',
  'learn': 'onboarding.chat.c1.reply.learn',
  'other': 'onboarding.chat.c1.reply.other',
};

const Map<String, String> _c2Opt = {
  'love': 'onboarding.chat.c2.opt.love',
  'career': 'onboarding.chat.c2.opt.career',
  'money': 'onboarding.chat.c2.opt.money',
  'family': 'onboarding.chat.c2.opt.family',
  'confidence': 'onboarding.chat.c2.opt.confidence',
  'decision': 'onboarding.chat.c2.opt.decision',
};

const Map<String, String> _c2Reply = {
  'love': 'onboarding.chat.c2.reply.love',
  'career': 'onboarding.chat.c2.reply.career',
  'money': 'onboarding.chat.c2.reply.money',
  'family': 'onboarding.chat.c2.reply.family',
  'confidence': 'onboarding.chat.c2.reply.confidence',
  'decision': 'onboarding.chat.c2.reply.decision',
};

const Map<String, String> _c3Opt = {
  'act': 'onboarding.chat.c3.opt.act',
  'wait': 'onboarding.chat.c3.opt.wait',
  'consult': 'onboarding.chat.c3.opt.consult',
  'withdraw': 'onboarding.chat.c3.opt.withdraw',
};

const Map<String, String> _c3Reply = {
  'act': 'onboarding.chat.c3.reply.act',
  'wait': 'onboarding.chat.c3.reply.wait',
  'consult': 'onboarding.chat.c3.reply.consult',
  'withdraw': 'onboarding.chat.c3.reply.withdraw',
};

const Map<String, String> _c7Opt = {
  'soft': 'onboarding.chat.c7.opt.soft',
  'direct': 'onboarding.chat.c7.opt.direct',
};

/// C7 dönüşü: seçilen tonun kendisi anahtarı belirler.
const Map<String, String> _c7ReplyByTone = {
  'soft': 'onboarding.chat.c7.reply.soft',
  'direct': 'onboarding.chat.c7.reply.direct',
};

const Map<String, String> _c5Opt = {
  'hard_days': 'onboarding.chat.c5.opt.hard_days',
  'regret': 'onboarding.chat.c5.opt.regret',
  'right_time': 'onboarding.chat.c5.opt.right_time',
  'all': 'onboarding.chat.c5.opt.all',
};

/// C5 dönüşü: hem seçenek hem ton anahtarı belirler.
const Map<String, Map<String, String>> _c5ReplyByTone = {
  'hard_days': {
    'soft': 'onboarding.chat.c5.reply.hard_days.soft',
    'direct': 'onboarding.chat.c5.reply.hard_days.direct',
  },
  'regret': {
    'soft': 'onboarding.chat.c5.reply.regret.soft',
    'direct': 'onboarding.chat.c5.reply.regret.direct',
  },
  'right_time': {
    'soft': 'onboarding.chat.c5.reply.right_time.soft',
    'direct': 'onboarding.chat.c5.reply.right_time.direct',
  },
  'all': {
    'soft': 'onboarding.chat.c5.reply.all.soft',
    'direct': 'onboarding.chat.c5.reply.all.direct',
  },
};

const Map<String, String> _notifPromptByTone = {
  'soft': 'onboarding.chat.notif.prompt.soft',
  'direct': 'onboarding.chat.notif.prompt.direct',
};

const Map<String, String> _notifGrantedByTone = {
  'soft': 'onboarding.chat.notif.granted.soft',
  'direct': 'onboarding.chat.notif.granted.direct',
};

const Map<String, String> _notifDeniedByTone = {
  'soft': 'onboarding.chat.notif.denied.soft',
  'direct': 'onboarding.chat.notif.denied.direct',
};

const Map<String, String> _reviewPromptByTone = {
  'soft': 'onboarding.chat.review.prompt.soft',
  'direct': 'onboarding.chat.review.prompt.direct',
};

const Map<String, String> _reviewThanksByTone = {
  'soft': 'onboarding.chat.review.thanks.soft',
  'direct': 'onboarding.chat.review.thanks.direct',
};

const Map<String, String> _reviewSkipByTone = {
  'soft': 'onboarding.chat.review.skip.soft',
  'direct': 'onboarding.chat.review.skip.direct',
};

const Map<String, String> _closeByTone = {
  'soft': 'onboarding.chat.close.soft',
  'direct': 'onboarding.chat.close.direct',
};

/// Notlarım'a yazılan cümleler: alan → seçenek id → anahtar. C7 (ton) ve
/// bildirim tercihi yazılmaz; C1 "other" için not yok.
const Map<String, String> _noteC1 = {
  'self': 'onboarding.chat.note.c1.self',
  'intentions': 'onboarding.chat.note.c1.intentions',
  'soulmate': 'onboarding.chat.note.c1.soulmate',
  'love': 'onboarding.chat.note.c1.love',
  'horoscope': 'onboarding.chat.note.c1.horoscope',
  'learn': 'onboarding.chat.note.c1.learn',
};

const Map<String, String> _noteC2 = {
  'love': 'onboarding.chat.note.c2.love',
  'career': 'onboarding.chat.note.c2.career',
  'money': 'onboarding.chat.note.c2.money',
  'family': 'onboarding.chat.note.c2.family',
  'confidence': 'onboarding.chat.note.c2.confidence',
  'decision': 'onboarding.chat.note.c2.decision',
};

const Map<String, String> _noteC3 = {
  'act': 'onboarding.chat.note.c3.act',
  'wait': 'onboarding.chat.note.c3.wait',
  'consult': 'onboarding.chat.note.c3.consult',
  'withdraw': 'onboarding.chat.note.c3.withdraw',
};

const Map<String, String> _noteC5 = {
  'hard_days': 'onboarding.chat.note.c5.hard_days',
  'regret': 'onboarding.chat.note.c5.regret',
  'right_time': 'onboarding.chat.note.c5.right_time',
  'all': 'onboarding.chat.note.c5.all',
};

/// Yazım sırası C1, C2, C3, C5 (map literal sırası korunur).
const Map<String, Map<String, String>> _noteByField = {
  'goal': _noteC1,
  'area': _noteC2,
  'reaction': _noteC3,
  'alert': _noteC5,
};

/// Notlarım'ı açıklayan balon (ton C7'de seçilir).
const Map<String, String> _notesExplainByTone = {
  'soft': 'onboarding.chat.notes.explain.soft',
  'direct': 'onboarding.chat.notes.explain.direct',
};

const String _kWelcome = 'onboarding.chat.c0.welcome';
const String _kIntro = 'onboarding.chat.c0.intro';
const String _kCta = 'onboarding.chat.close.continue';
const String _kNotifAllow = 'onboarding.chat.notif.allow';
const String _kNotifLater = 'onboarding.chat.notif.later';
const String _kReviewYes = 'onboarding.chat.review.yes';
const String _kReviewNo = 'onboarding.chat.review.no';

/// Sohbet adımları (sırayla).
const List<_Step> _steps = [
  _Step(
    qKey: 'onboarding.chat.c1.q',
    options: _c1Opt,
    replies: _c1Reply,
    field: 'goal',
  ),
  _Step(
    qKey: 'onboarding.chat.c2.q',
    options: _c2Opt,
    replies: _c2Reply,
    field: 'area',
  ),
  _Step(
    qKey: 'onboarding.chat.c3.q',
    options: _c3Opt,
    replies: _c3Reply,
    field: 'reaction',
  ),
  _Step(
    qKey: 'onboarding.chat.c7.q',
    options: _c7Opt,
    replyByTone: _c7ReplyByTone,
    field: 'tone',
  ),
  _Step(
    qKey: 'onboarding.chat.c5.q',
    options: _c5Opt,
    toneReplies: _c5ReplyByTone,
    field: 'alert',
  ),
];

class _Step {
  const _Step({
    required this.qKey,
    required this.options,
    required this.field,
    this.replies,
    this.toneReplies,
    this.replyByTone,
  });

  final String qKey;

  /// Seçenek id → etiket anahtarı.
  final Map<String, String> options;

  /// Profil alanı (goal, area, reaction, tone, alert).
  final String field;

  /// Seçenek id → dönüş anahtarı (tondan bağımsız adımlar).
  final Map<String, String>? replies;

  /// Seçenek id → ton → dönüş anahtarı.
  final Map<String, Map<String, String>>? toneReplies;

  /// Ton → dönüş anahtarı (seçenek id'si tonun kendisi olduğunda).
  final Map<String, String>? replyByTone;
}

class _Msg {
  _Msg(this.mine, this.text, {this.animate = false, this.after});

  /// Runs once the reveal finishes (sequential reveal).
  final VoidCallback? after;

  final bool mine;
  final String text;

  /// Only a newly added guide bubble is revealed character by character; the
  /// flag is cleared once the reveal finishes.
  bool animate;
}

class _Opt {
  const _Opt(this.labelKey, this.onPick);

  final String labelKey;
  final VoidCallback onPick;
}

/// S10c: son sohbet sayfası. Tamamlanınca profili yazar ve [onDone] çağırır.
class OnboardingChatPage extends StatefulWidget {
  const OnboardingChatPage({
    super.key,
    required this.onDone,
    this.requestNotificationPermission,
    this.requestReview,
    this.initAds,
    this.onNotes,
  });

  /// Sohbet bittiğinde (close.continue) çağrılır.
  final VoidCallback onDone;

  /// Test için enjekte edilebilir; varsayılan gerçek sistem izni isteği.
  /// `null` dönerse izin hiç sorulmadı (desteklenmeyen platform/istisna).
  final Future<bool?> Function()? requestNotificationPermission;

  /// Test için enjekte edilebilir; varsayılan gerçek inceleme isteği.
  final Future<void> Function()? requestReview;

  /// Test için enjekte edilebilir; varsayılan `AdService.init`.
  /// Bildirim adımı bittikten sonra await edilir (30 sn üst sınırla).
  final Future<void> Function()? initAds;

  /// Sohbet bitince üretilen not metinleriyle (kayıt sırasıyla) çağrılır.
  /// Not yoksa bos liste gelir.
  final void Function(List<String> notes)? onNotes;

  @override
  State<OnboardingChatPage> createState() => _OnboardingChatPageState();
}

class _OnboardingChatPageState extends State<OnboardingChatPage> {
  final List<_Msg> _lines = <_Msg>[];
  final ScrollController _scroll = ScrollController();
  final Map<String, String> _answers = <String, String>{};

  List<_Opt> _options = <_Opt>[];
  Timer? _timer;
  int _stepIndex = 0;
  bool _typing = false;
  bool _canFinish = false;
  bool _saving = false;
  String _tone = 'soft';

  @override
  void initState() {
    super.initState();
    // MediaQuery yalnızca ilk kare sonrası hazırdır; ilk balonlar bu yüzden
    // post-frame callback ile başlatılır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reveal(_kWelcome, after: () => _reveal(_kIntro, after: _askStep));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  bool get _reduce => MediaQuery.disableAnimationsOf(context);

  void _scrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  /// Kısa "yazıyor" arasından sonra rehber balonunu ekler.
  void _reveal(String key, {required VoidCallback after}) {
    final text = t(context, key);
    if (_reduce) {
      setState(() {
        _typing = false;
        _lines.add(_Msg(false, text));
      });
      _scrollEnd();
      after();
      return;
    }
    setState(() => _typing = true);
    _scrollEnd();
    _timer?.cancel();
    _timer = Timer(AppMotion.typingFor(text.length), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _lines.add(_Msg(false, text, animate: true, after: after));
      });
      _scrollEnd();
    });
  }

  void _askStep() {
    final step = _steps[_stepIndex];
    _reveal(
      step.qKey,
      after: () {
        setState(() {
          _options = step.options.entries
              .map<_Opt>((e) => _Opt(e.value, () => _choose(step, e.key)))
              .toList();
        });
      },
    );
  }

  String _replyKey(_Step step, String id) {
    final replies = step.replies;
    if (replies != null) return replies[id]!;
    final toneReplies = step.toneReplies;
    if (toneReplies != null) return toneReplies[id]![_tone]!;
    return step.replyByTone![_tone]!;
  }

  void _choose(_Step step, String id) {
    if (_typing || _options.isEmpty) return;
    HapticFeedback.selectionClick();
    // C7 dönüşü seçilen tona bağlı olduğu için ton önce güncellenir.
    if (step.field == 'tone') _tone = id;
    final reply = _replyKey(step, id);
    setState(() {
      _lines.add(_Msg(true, t(context, step.options[id]!)));
      _options = <_Opt>[];
      _answers[step.field] = id;
    });
    _scrollEnd();
    _reveal(reply, after: _advance);
  }

  void _advance() {
    _stepIndex++;
    if (_stepIndex < _steps.length) {
      _askStep();
      return;
    }
    // Web'de bildirim ve puan adımları atlanır; izin sorulmadı.
    if (kIsWeb) {
      _answers['notif'] = 'skipped';
      _startAdsThen(_closeStep);
      return;
    }
    _notifStep();
  }

  void _notifStep() {
    _reveal(
      _notifPromptByTone[_tone]!,
      after: () {
        setState(() {
          _options = <_Opt>[
            _Opt(_kNotifAllow, _notifAllow),
            _Opt(_kNotifLater, _notifLater),
          ];
        });
      },
    );
  }

  Future<void> _notifAllow() async {
    if (_typing || _options.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _options = <_Opt>[]);
    final granted =
        await (widget.requestNotificationPermission ??
            _requestNotificationPermission)();
    if (!mounted) return;
    // null: izin sorulmadı; "denied" yalnızca kullanıcı gerçekten reddettiğinde.
    _answers['notif'] = granted == null
        ? 'skipped'
        : (granted ? 'granted' : 'denied');
    _reveal(
      granted == true
          ? _notifGrantedByTone[_tone]!
          : _notifDeniedByTone[_tone]!,
      after: () => _startAdsThen(_reviewStep),
    );
  }

  void _notifLater() {
    if (_typing || _options.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _options = <_Opt>[];
      _answers['notif'] = 'denied';
    });
    _reveal(
      _notifDeniedByTone[_tone]!,
      after: () => _startAdsThen(_reviewStep),
    );
  }

  /// Bildirim adımı bittiğinde (granted/denied/skipped) reklam SDK'sını
  /// başlatır (UMP -> ATT -> initialize); hazır olunca [next] çağrılır.
  /// UMP formu kullanıcı etkileşimi bekleyebildiği için 30 sn üst sınır konur;
  /// üst sınır aşılırsa veya init hata verirse akış yine de [next] ile sürer.
  /// Zaman aşımı init'i iptal ETMEZ (init idempotent, arka planda tamamlanır).
  Future<void> _startAdsThen(VoidCallback next) async {
    try {
      await (widget.initAds ?? AdService.init)().timeout(
        const Duration(seconds: 30),
      );
    } on TimeoutException catch (e) {
      debugPrint('onboarding AdService.init timed out: $e');
    } catch (e) {
      debugPrint('onboarding AdService.init failed: $e');
    }
    if (!mounted) return;
    next();
  }

  void _reviewStep() {
    _reveal(
      _reviewPromptByTone[_tone]!,
      after: () {
        setState(() {
          _options = <_Opt>[
            _Opt(_kReviewYes, _reviewYes),
            _Opt(_kReviewNo, _reviewNo),
          ];
        });
      },
    );
  }

  Future<void> _reviewYes() async {
    if (_typing || _options.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _options = <_Opt>[]);
    await (widget.requestReview ?? _requestReview)();
    if (!mounted) return;
    _reveal(_reviewThanksByTone[_tone]!, after: _closeStep);
  }

  void _reviewNo() {
    if (_typing || _options.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _options = <_Opt>[]);
    _reveal(_reviewSkipByTone[_tone]!, after: _closeStep);
  }

  void _closeStep() {
    _reveal(
      _closeByTone[_tone]!,
      after: () => _reveal(
        _notesExplainByTone[_tone]!,
        after: () => setState(() => _canFinish = true),
      ),
    );
  }

  /// Sistem bildirimi izni — bildirim gönderilmez, yalnız izin istenir.
  /// `null`: bu platformda izin isteği yok (sorulmadı).
  Future<bool?> _requestNotificationPermission() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return null;
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return null;
    }
  }

  /// Uygulama içi inceleme isteği. Pencere garantisi yoktur; hata yutulmaz.
  Future<void> _requestReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (e) {
      debugPrint('In-app review request failed: $e');
    }
  }

  /// C1, C2, C3, C5 seçimlerinden tanıtımda gösterilecek not anahtarları (aynı
  /// sıra; seçim yoksa atlanır). C7 (ton) ve bildirim tercihi not sayılmaz.
  List<String> _noteKeys() {
    final keys = <String>[];
    for (final field in _noteByField.keys) {
      final id = _answers[field];
      final key = id == null ? null : _noteByField[field]![id];
      if (key == null) continue;
      keys.add(key);
    }
    return keys;
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final notes = [for (final k in _noteKeys()) t(context, k)];
    try {
      await OnboardingProfile(
        goal: _answers['goal'] ?? '',
        area: _answers['area'] ?? '',
        reaction: _answers['reaction'] ?? '',
        tone: _tone,
        alert: _answers['alert'] ?? '',
        notif: _answers['notif'] ?? 'skipped',
      ).save();
    } catch (e) {
      debugPrint('Onboarding profile save failed: $e');
    }
    if (!mounted) return;
    widget.onNotes?.call(notes);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.82;
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: Column(
              children: [
                Expanded(child: _bubbles(maxBubbleWidth)),
                _optionsArea(),
                if (_canFinish) ...[
                  const SizedBox(height: AppSpacing.sm),
                  CosmicCtaButton(
                    label: t(context, _kCta),
                    onTap: _saving ? null : _finish,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubbles(double maxBubbleWidth) {
    final count = _lines.length + (_typing ? 1 : 0);
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
      itemCount: count,
      itemBuilder: (context, i) {
        if (i == _lines.length) return const StarTyping();
        final line = _lines[i];
        return Align(
          alignment: line.mine
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            decoration: BoxDecoration(
              borderRadius: AppRadius.innerBr,
              color: line.mine
                  ? AppColors.gold.withValues(alpha: 0.12)
                  : AppColors.bgSurface,
              border: Border.all(color: AppColors.hairline),
            ),
            child: line.animate
                ? _RevealText(
                    key: ObjectKey(line),
                    text: line.text,
                    style: AppTextStyles.bodyMd(color: AppColors.starlight),
                    onTick: _scrollEnd,
                    onDone: () {
                      setState(() => line.animate = false);
                      line.after?.call();
                    },
                  )
                : Text(
                    line.text,
                    style: AppTextStyles.bodyMd(color: AppColors.starlight),
                  ),
          ),
        );
      },
    );
  }

  Widget _optionsArea() {
    if (_options.isEmpty) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.32,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final opt in _options) _option(opt)],
        ),
      ),
    );
  }

  /// Dokunma alanı 48dp: çip görseli 32dp, dikey dolgu ile hedef büyütülür.
  Widget _option(_Opt opt) {
    final label = t(context, opt.labelKey);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.pillBr,
          onTap: opt.onPick,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: CosmicChip(label: label),
          ),
        ),
      ),
    );
  }
}

/// Reveals a guide message character by character with the same AppMotion step
/// as Eya (AskPage); reduce-motion shows the full text at once.
class _RevealText extends StatefulWidget {
  const _RevealText({
    super.key,
    required this.text,
    required this.style,
    required this.onDone,
    this.onTick,
  });

  final String text;
  final TextStyle? style;
  final VoidCallback onDone;

  /// Called on every reveal step so the list can keep the last bubble visible.
  final VoidCallback? onTick;

  @override
  State<_RevealText> createState() => _RevealTextState();
}

class _RevealTextState extends State<_RevealText> {
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
      // Do not split a surrogate pair (emoji).
      final c = widget.text.codeUnitAt(next - 1);
      if (c >= 0xD800 && c <= 0xDBFF) next++;
      setState(() => _n = next.clamp(0, widget.text.length));
      widget.onTick?.call();
    });
  }

  void _finish() {
    _timer?.cancel();
    if (_n != widget.text.length) setState(() => _n = widget.text.length);
    widget.onTick?.call();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text(widget.text.substring(0, _n), style: widget.style);
}
