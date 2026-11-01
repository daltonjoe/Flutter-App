import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_background.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../presentation/widgets/components/cosmic_input_field.dart';
import '../../providers/active_profile_provider.dart';
import '../../providers/language_provider.dart';
import '../../redesign/ask/star_typing.dart';
import '../../services/analytics_service.dart';
import '../../services/ask_service.dart';
import '../../services/astro_service.dart';

const String _k = 'onboarding.first_question.';

/// Onboarding'deki canli soru hakki (K1); sunucudaki ucretsiz bakiye de 3.
const int kOnboardingQuestions = 3;

/// Paywall'in kisisel basligi bu anahtarlari okur (PLAN D4).
const String kPrefObName = 'ob_name';
const String kPrefObSun = 'ob_sun';
const String kPrefObHook = 'ob_hook';

/// Son cevabin son satirindan paywall alt basligi icin tek cumle.
String? onboardingHook(String reply) {
  final lines = reply
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (lines.isEmpty) return null;
  final last = lines.last;
  final m = RegExp(r'^.{20,160}?[.!?…؟](?=\s|$)').firstMatch(last);
  if (m != null) return m.group(0);
  if (last.length <= 160) return last;
  return '${last.substring(0, 157).trimRight()}…';
}

class _Line {
  const _Line(this.mine, this.text, {this.system = false});
  final bool mine;
  final String text;
  final bool system;
}

/// S13: ilk 3 soru, gercek /ask cevabi (K1). Sohbet bellekte tutulur.
class OnboardingFirstQuestionPage extends StatefulWidget {
  const OnboardingFirstQuestionPage({
    super.key,
    required this.onDone,
    this.sunSign = '',
    this.moonSign = '',
  });

  final VoidCallback onDone;
  final String sunSign;
  final String moonSign;

  @override
  State<OnboardingFirstQuestionPage> createState() =>
      _OnboardingFirstQuestionPageState();
}

class _OnboardingFirstQuestionPageState
    extends State<OnboardingFirstQuestionPage> {
  final TextEditingController _ctl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Line> _lines = [];
  final Stopwatch _sw = Stopwatch();
  Timer? _tick;
  Timer? _type;
  bool _busy = false;
  bool _empty = false;
  int _answered = 0;
  int? _left;
  String? _errKey;
  String? _lastText;
  String? _full;
  int _shown = 0;

  bool get _done => _empty || _answered >= kOnboardingQuestions || _left == 0;
  bool get _canContinue => _done || _answered > 0;

  @override
  void initState() {
    super.initState();
    _saveHead();
    _readLeft();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _type?.cancel();
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _saveHead() async {
    final name = context.read<ActiveProfileProvider>().summary?.name ?? '';
    try {
      final p = await SharedPreferences.getInstance();
      if (name.isNotEmpty) await p.setString(kPrefObName, name);
      if (widget.sunSign.isNotEmpty) {
        await p.setString(kPrefObSun, widget.sunSign);
      }
    } catch (e) {
      debugPrint('FirstQuestion head save failed: $e');
    }
  }

  /// Kalan hak sunucudan (credit_status); okunamazsa sayac gizli kalir.
  Future<void> _readLeft() async {
    int? b;
    try {
      final r = await Supabase.instance.client.rpc('credit_status');
      final m = r is Map
          ? r
          : (r is List && r.isNotEmpty && r.first is Map ? r.first : null);
      if (m is Map) b = int.tryParse('${m['balance']}');
    } catch (e) {
      debugPrint('FirstQuestion credit_status failed: $e');
    }
    if (!mounted || b == null) return;
    setState(() => _left = b);
  }

  void _scrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _startTick() {
    _sw
      ..reset()
      ..start();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _busy) setState(() {});
    });
  }

  void _stopTick() {
    _tick?.cancel();
    _sw.stop();
  }

  void _startTyping(String text) {
    _type?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(() {
      _full = text;
      _shown = 0;
    });
    _type = Timer.periodic(const Duration(milliseconds: 30), (_) {
      final f = _full;
      if (!mounted || f == null) return;
      var n = _shown + 1;
      final c = f.codeUnitAt(n - 1);
      if (c >= 0xD800 && c <= 0xDBFF) n++;
      if (n >= f.length) {
        _finishTyping();
        return;
      }
      setState(() => _shown = n);
      _scrollEnd();
    });
  }

  void _finishTyping() {
    _type?.cancel();
    if (_full != null && mounted) setState(() => _full = null);
  }

  Future<void> _ask(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy || _done) return;
    final loc = context.read<LanguageProvider>().locale.languageCode;
    final pid = context.read<ActiveProfileProvider>().activeProfileId;
    final safe = <String, String>{
      'crisis': t(context, 'ask.safety.crisis'),
      'redirect': t(context, 'ask.safety.redirect'),
      'fallback': t(context, 'ask.safety.fallback'),
    };
    final retry = _errKey != null &&
        _lines.isNotEmpty &&
        _lines.last.mine &&
        _lastText == text;
    final base =
        retry ? _lines.sublist(0, _lines.length - 1) : List<_Line>.of(_lines);
    final kept = base.where((l) => !l.system).toList();
    final recent = kept.length > 6 ? kept.sublist(kept.length - 6) : kept;
    final n = _lines.where((l) => l.mine).length + (retry ? 0 : 1);
    HapticFeedback.selectionClick();
    _ctl.clear();
    _finishTyping();
    setState(() {
      if (!retry) _lines.add(_Line(true, text));
      _busy = true;
      _errKey = null;
      _lastText = text;
    });
    _startTick();
    _scrollEnd();
    try {
      final res = await AskService.send(
        message: text,
        contexts: const <Map<String, dynamic>>[],
        locale: loc,
        history: [
          for (final l in recent)
            {'role': l.mine ? 'user' : 'assistant', 'text': l.text},
        ],
        profileId: pid,
        mode: 'natal',
      );
      if (!mounted) return;
      _stopTick();
      final s = res.safety;
      final rp = res.reply;
      String reply;
      var sys = false;
      if (s != null) {
        reply = rp ?? (safe[s] ?? safe['fallback']!);
        sys = true;
      } else if (rp == null || rp.trim().isEmpty) {
        reply = safe['fallback']!;
        sys = true;
      } else {
        reply = rp;
      }
      AnalyticsService.track(
          AnalyticsEvents.questionAsked, {'n': n, 'ok': !sys});
      setState(() {
        _lines.add(_Line(false, reply, system: sys));
        _busy = false;
        if (!sys) _answered++;
      });
      _scrollEnd();
      if (!sys) {
        _startTyping(reply);
        _saveHook(reply);
        _readLeft();
      }
    } catch (e) {
      debugPrint('FirstQuestion ask failed: $e');
      if (!mounted) return;
      _stopTick();
      final code = e is AstroServiceException ? e.code : '';
      AnalyticsService.track(
          AnalyticsEvents.questionAsked, {'n': n, 'ok': false});
      setState(() {
        _busy = false;
        if (code == 'CREDITS_EMPTY' ||
            code == 'QUOTA' ||
            code.startsWith('DAILY_LIMIT')) {
          _empty = true;
          _errKey = '${_k}quota';
        } else {
          _errKey = code == 'RATE_LIMITED' ? 'ask.error.rate' : 'ask.error';
        }
      });
    }
  }

  Future<void> _saveHook(String reply) async {
    final h = onboardingHook(reply);
    if (h == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(kPrefObHook, h);
    } catch (e) {
      debugPrint('FirstQuestion hook save failed: $e');
    }
  }

  List<String> _chipTexts() {
    final out = <String>[];
    if (widget.sunSign.isNotEmpty) {
      out.add(t(context, '${_k}chip_sun').replaceAll('{sign}', widget.sunSign));
    }
    if (widget.moonSign.isNotEmpty) {
      out.add(
          t(context, '${_k}chip_moon').replaceAll('{sign}', widget.moonSign));
    }
    out.add(t(context, '${_k}chip_sky'));
    return out;
  }

  Widget _chip(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _busy ? null : () => _ask(text),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.gold.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd(color: AppColors.starlight),
          ),
        ),
      ),
    );
  }

  Widget _intro() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t(context, '${_k}title'),
              textAlign: TextAlign.center,
              style: AppTextStyles.heroTitle(),
            ),
            const SizedBox(height: 24),
            for (final c in _chipTexts())
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _chip(c),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chat() {
    final last = _lines.length - 1;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(top: 16),
      itemCount: _lines.length,
      itemBuilder: (context, i) {
        final l = _lines[i];
        final typing = _full != null && i == last && !l.mine;
        final text =
            typing ? _full!.substring(0, _shown.clamp(0, _full!.length)) : l.text;
        return Align(
          alignment: l.mine
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: GestureDetector(
            onTap: typing ? _finishTyping : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.82),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: l.mine
                    ? AppColors.gold.withValues(alpha: 0.12)
                    : AppColors.bgSurface,
                border: Border.all(color: AppColors.hairline),
              ),
              child: Text(text,
                  style: AppTextStyles.bodyMd(color: AppColors.starlight)),
            ),
          ),
        );
      },
    );
  }

  Widget _waiting() {
    final s = _sw.elapsed.inSeconds;
    final key = s >= 20
        ? 'slow'
        : s < 3
            ? 'status1'
            : s < 8
                ? 'status2'
                : 'status3';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const StarTyping(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t(context, '$_k$key'),
                style: AppTextStyles.bodySm(color: AppColors.mist)),
          ),
        ],
      ),
    );
  }

  Widget _error() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(t(context, _errKey!),
                style: AppTextStyles.bodySm(color: AppColors.mist)),
          ),
          if (!_done && _lastText != null)
            TextButton(
              onPressed: _busy ? null : () => _ask(_lastText!),
              child: Text(t(context, 'ask.retry'),
                  style: AppTextStyles.ctaSecondary()),
            ),
        ],
      ),
    );
  }

  Widget _counter() {
    final left = _left;
    if (left == null || _done) return const SizedBox.shrink();
    final n = left < kOnboardingQuestions - _answered
        ? left
        : kOnboardingQuestions - _answered;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        t(context, '${_k}left', args: {'n': '$n'}),
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySm(color: AppColors.mist),
      ),
    );
  }

  Widget _input() {
    if (_done) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CosmicInputField(
            label: t(context, '${_k}free_label'),
            icon: Icons.auto_awesome_outlined,
            controller: _ctl,
            hint: t(context,
                _lines.isEmpty ? '${_k}free_hint' : '${_k}more_hint'),
            onChanged: (_) {},
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: AppSpacing.fieldBottomGap + (AppSizes.inputHeight - 48) / 2,
          ),
          child: IconButton(
            tooltip: t(context, 'ask.send'),
            onPressed: _busy ? null : () => _ask(_ctl.text),
            icon: const Icon(Icons.arrow_upward, color: AppColors.gold),
          ),
        ),
      ],
    );
  }

  Widget _bottom() {
    if (_canContinue) {
      return CosmicCtaButton(
        label: t(context, 'common.next'),
        onTap: _busy ? null : widget.onDone,
      );
    }
    return TextButton(
      onPressed: widget.onDone,
      child: Text(t(context, '${_k}skip'), style: AppTextStyles.ctaSecondary()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: CosmicBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Expanded(child: _lines.isEmpty ? _intro() : _chat()),
                  if (_busy) _waiting(),
                  if (_errKey != null) _error(),
                  _counter(),
                  _input(),
                  const SizedBox(height: 12),
                  _bottom(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
