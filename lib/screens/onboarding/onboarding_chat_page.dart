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

const String _kWelcome = 'onboarding.chat.c0.welcome';
const String _kIntro = 'onboarding.chat.c0.intro';
const String _kTyping = 'onboarding.chat.typing';
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
  const _Msg(this.mine, this.text);

  final bool mine;
  final String text;
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
  });

  /// Sohbet bittiğinde (close.continue) çağrılır.
  final VoidCallback onDone;

  /// Test için enjekte edilebilir; varsayılan gerçek sistem izni isteği.
  /// `null` dönerse izin hiç sorulmadı (desteklenmeyen platform/istisna).
  final Future<bool?> Function()? requestNotificationPermission;

  /// Test için enjekte edilebilir; varsayılan gerçek inceleme isteği.
  final Future<void> Function()? requestReview;

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

  Duration get _delay =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.enter;

  void _scrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  /// Kısa "yazıyor" arasından sonra rehber balonunu ekler.
  void _reveal(String key, {required VoidCallback after}) {
    setState(() => _typing = true);
    _scrollEnd();
    _timer?.cancel();
    _timer = Timer(_delay, () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _lines.add(_Msg(false, t(context, key)));
      });
      _scrollEnd();
      after();
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
      _closeStep();
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
      after: _reviewStep,
    );
  }

  void _notifLater() {
    if (_typing || _options.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _options = <_Opt>[];
      _answers['notif'] = 'denied';
    });
    _reveal(_notifDeniedByTone[_tone]!, after: _reviewStep);
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
      after: () => setState(() => _canFinish = true),
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

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
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
        if (i == _lines.length) return _typingBubble();
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
            child: Text(
              line.text,
              style: AppTextStyles.bodyMd(color: AppColors.starlight),
            ),
          ),
        );
      },
    );
  }

  Widget _typingBubble() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.innerBr,
            color: AppColors.bgSurface,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Semantics(
            label: t(context, _kTyping),
            child: _TypingDots(animate: !reduce),
          ),
        ),
      ),
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

/// Yazıyor göstergesi — harekete duyarlı kullanıcıda sabit kalır.
class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.animate});

  final bool animate;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.resolution,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant _TypingDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _alpha(int i) {
    final phase = (_c.value - i * 0.2) % 1.0;
    return 0.35 + 0.55 * (1 - (phase * 2 - 1).abs());
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(0.7),
          SizedBox(width: AppSpacing.xs),
          _Dot(0.7),
          SizedBox(width: AppSpacing.xs),
          _Dot(0.7),
        ],
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            _Dot(_alpha(i)),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.alpha);

  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.sm,
      height: AppSpacing.sm,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withValues(alpha: alpha),
      ),
    );
  }
}
