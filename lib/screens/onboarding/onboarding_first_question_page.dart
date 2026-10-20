import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_background.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../presentation/widgets/components/cosmic_input_field.dart';
import '../../providers/active_profile_provider.dart';
import '../../providers/language_provider.dart';
import '../../redesign/ask/star_typing.dart';
import '../../services/ai_consent_service.dart';
import '../../services/ask_service.dart';
import '../../services/astro_service.dart';

const String _k = 'onboarding.first_question.';

class _Line {
  const _Line(this.mine, this.text, {this.system = false});
  final bool mine;
  final String text;
  final bool system;
}

/// S13 — İlk soru ve AI cevabı. Sohbet bellekte tutulur, kalıcı değildir.
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
  bool _consented = false;
  bool _consentRetried = false;
  bool _quotaHit = false;
  String? _errKey;
  String? _lastText;
  String? _full;
  int _shown = 0;

  bool get _canContinue => _quotaHit || _lines.any((l) => !l.mine);

  @override
  void dispose() {
    _tick?.cancel();
    _type?.cancel();
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
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

  Future<bool> _consentSheet() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDeep,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t(ctx, 'consent.ai.title'), style: AppTextStyles.h2()),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(t(ctx, 'consent.ai.body'),
                      style: AppTextStyles.bodyMd(color: AppColors.mist)),
                ),
              ),
              const SizedBox(height: 20),
              CosmicCtaButton(
                label: t(ctx, 'consent.ai.accept'),
                onTap: () async {
                  final g = await AiConsentService.grantAi();
                  if (ctx.mounted) Navigator.pop(ctx, g);
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(t(ctx, 'consent.ai.decline'),
                    style: AppTextStyles.ctaSecondary()),
              ),
            ],
          ),
        ),
      ),
    );
    return ok ?? false;
  }

  Future<bool> _ensureConsent() async {
    if (_consented) return true;
    final has = await AiConsentService.hasAi();
    if (!mounted) return false;
    if (has) {
      _consented = true;
      return true;
    }
    final ok = await _consentSheet();
    if (!mounted) return false;
    if (ok) {
      _consented = true;
      return true;
    }
    widget.onDone();
    return false;
  }

  Future<void> _ask(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    if (!await _ensureConsent()) return;
    if (!mounted) return;
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
      setState(() {
        _lines.add(_Line(false, reply, system: sys));
        _busy = false;
      });
      _scrollEnd();
      if (!sys) _startTyping(reply);
    } catch (e) {
      debugPrint('FirstQuestion ask failed: $e');
      if (!mounted) return;
      _stopTick();
      final code = e is AstroServiceException ? e.code : '';
      if (code == 'CONSENT' && !_consentRetried) {
        _consentRetried = true;
        _consented = false;
        setState(() => _busy = false);
        final ok = await _consentSheet();
        if (!mounted) return;
        if (ok) {
          _consented = true;
          _errKey = 'ask.error';
          await _ask(text);
          return;
        }
        widget.onDone();
        return;
      }
      setState(() {
        _busy = false;
        _lastText = text;
        if (code == 'QUOTA') {
          _quotaHit = true;
          _errKey = '${_k}quota';
        } else if (code == 'RATE_LIMITED') {
          _errKey = 'ask.error.rate';
        } else {
          _errKey = 'ask.error';
        }
      });
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          if (!_quotaHit && _lastText != null)
            TextButton(
              onPressed: _busy ? null : () => _ask(_lastText!),
              child: Text(t(context, 'ask.retry'),
                  style: AppTextStyles.ctaSecondary()),
            ),
        ],
      ),
    );
  }

  Widget _input() {
    if (_quotaHit) return const SizedBox.shrink();
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
        IconButton(
          tooltip: t(context, 'ask.send'),
          onPressed: _busy ? null : () => _ask(_ctl.text),
          icon: const Icon(Icons.arrow_upward, color: AppColors.gold),
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