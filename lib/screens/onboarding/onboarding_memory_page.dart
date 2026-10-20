import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_background.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../providers/active_profile_provider.dart';
import '../../providers/language_provider.dart';
import '../../redesign/ask/star_typing.dart';
import '../../services/ai_consent_service.dart';
import '../../services/ask_service.dart';
import '../../services/astro_service.dart';

const String _k = 'onboarding.memory.';
const String _fq = 'onboarding.first_question.';

/// S14 — Hafıza anı: bir not bırak, ardından notu kullanabilecek tek bir soru sor.
/// AI onayı yoksa sayfa bir şey göstermeden akışı devam ettirir.
class OnboardingMemoryPage extends StatefulWidget {
  const OnboardingMemoryPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingMemoryPage> createState() => _OnboardingMemoryPageState();
}

class _OnboardingMemoryPageState extends State<OnboardingMemoryPage> {
  final TextEditingController _note = TextEditingController();
  final TextEditingController _free = TextEditingController();
  bool _ready = false;
  bool _busy = false;
  bool _saved = false;
  bool _quotaHit = false;
  String? _errKey;
  String? _question;
  String? _reply;

  @override
  void initState() {
    super.initState();
    _gate();
  }

  @override
  void dispose() {
    _note.dispose();
    _free.dispose();
    super.dispose();
  }

  Future<void> _gate() async {
    final has = await AiConsentService.hasAi();
    if (!mounted) return;
    if (has) {
      setState(() => _ready = true);
    } else {
      widget.onDone();
    }
  }

  Future<void> _save() async {
    final text = _note.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _errKey = null;
    });
    try {
      await AskService.memoryAdd(text);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _busy = false;
        _saved = true;
      });
    } catch (e) {
      debugPrint('Memory note failed: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errKey = AskService.memoryErrKey(e);
      });
    }
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    final loc = context.read<LanguageProvider>().locale.languageCode;
    final pid = context.read<ActiveProfileProvider>().activeProfileId;
    final safe = <String, String>{
      'crisis': t(context, 'ask.safety.crisis'),
      'redirect': t(context, 'ask.safety.redirect'),
      'fallback': t(context, 'ask.safety.fallback'),
    };
    HapticFeedback.selectionClick();
    _free.clear();
    setState(() {
      _busy = true;
      _errKey = null;
      _question = text;
      _reply = null;
    });
    try {
      final res = await AskService.send(
        message: text,
        contexts: const <Map<String, dynamic>>[],
        locale: loc,
        history: const [],
        profileId: pid,
        mode: 'natal',
      );
      if (!mounted) return;
      final s = res.safety;
      final rp = res.reply;
      final String reply;
      if (s != null) {
        reply = rp ?? (safe[s] ?? safe['fallback']!);
      } else if (rp == null || rp.trim().isEmpty) {
        reply = safe['fallback']!;
      } else {
        reply = rp;
      }
      setState(() {
        _reply = reply;
        _busy = false;
      });
    } catch (e) {
      debugPrint('Memory proof ask failed: $e');
      if (!mounted) return;
      final code = e is AstroServiceException ? e.code : '';
      setState(() {
        _busy = false;
        if (code == 'QUOTA') {
          _quotaHit = true;
          _errKey = '${_fq}quota';
        } else if (code == 'RATE_LIMITED') {
          _errKey = 'ask.error.rate';
        } else {
          _errKey = 'ask.error';
        }
      });
    }
  }

  Widget _chip(String text, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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

  Widget _field(
    TextEditingController c, {
    int? maxLength,
    String? hint,
    String? helper,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.hairline),
    );
    return TextField(
      controller: c,
      maxLength: maxLength,
      minLines: 1,
      maxLines: 4,
      style: AppTextStyles.bodyMd(color: AppColors.starlight),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMd(color: AppColors.mist),
        helperText: helper,
        helperMaxLines: 3,
        helperStyle: AppTextStyles.bodySm(color: AppColors.mist),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.bgSurface,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.gold),
        ),
      ),
    );
  }

  Widget _bubble(String text, {required bool mine}) {
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: mine
              ? AppColors.gold.withValues(alpha: 0.12)
              : AppColors.bgSurface,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Text(text,
            style: AppTextStyles.bodyMd(color: AppColors.starlight)),
      ),
    );
  }

  Widget _noteStep() {
    final examples = [
      t(context, '${_k}chip_job'),
      t(context, '${_k}chip_relationship'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Text(
          t(context, '${_k}title'),
          textAlign: TextAlign.center,
          style: AppTextStyles.heroTitle(),
        ),
        const SizedBox(height: 12),
        Text(
          t(context, '${_k}hint'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd(color: AppColors.mist),
        ),
        const SizedBox(height: 24),
        _field(
          _note,
          maxLength: 150,
          helper: t(context, 'ask.remember.hint'),
        ),
        const SizedBox(height: 16),
        for (final c in examples)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _chip(c, () {
              _note.value = TextEditingValue(
                text: c,
                selection: TextSelection.collapsed(offset: c.length),
              );
              setState(() {});
            }),
          ),
      ],
    );
  }

  Widget _proofStep() {
    final chipText = t(context, '${_k}proof_chip');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Text(
          t(context, 'ask.remember.saved'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm(color: AppColors.gold),
        ),
        const SizedBox(height: 12),
        Text(
          t(context, '${_k}proof_title'),
          textAlign: TextAlign.center,
          style: AppTextStyles.heroTitle(),
        ),
        const SizedBox(height: 24),
        if (_question == null) ...[
          _chip(chipText, _busy ? null : () => _send(chipText)),
          const SizedBox(height: 16),
          _field(
            _free,
            hint: t(context, '${_k}proof_hint'),
            suffix: IconButton(
              tooltip: t(context, 'ask.send'),
              onPressed: (_busy || _free.text.trim().isEmpty)
                  ? null
                  : () => _send(_free.text),
              icon: const Icon(Icons.arrow_upward, color: AppColors.gold),
            ),
          ),
        ] else ...[
          _bubble(_question!, mine: true),
          if (_reply != null) _bubble(_reply!, mine: false),
          if (_busy) _waiting(),
        ],
      ],
    );
  }

  Widget _waiting() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const StarTyping(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t(context, '${_fq}status3'),
                style: AppTextStyles.bodySm(color: AppColors.mist)),
          ),
        ],
      ),
    );
  }

  Widget _error() {
    final canRetry = _saved && !_quotaHit && _question != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(t(context, _errKey!),
                style: AppTextStyles.bodySm(color: AppColors.mist)),
          ),
          if (canRetry)
            TextButton(
              onPressed: _busy ? null : () => _send(_question!),
              child: Text(t(context, 'ask.retry'),
                  style: AppTextStyles.ctaSecondary()),
            ),
        ],
      ),
    );
  }

  Widget _skip() {
    return TextButton(
      onPressed: _busy ? null : widget.onDone,
      child: Text(t(context, '${_k}skip'), style: AppTextStyles.ctaSecondary()),
    );
  }

  Widget _bottom() {
    if (!_saved) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CosmicCtaButton(
            label: t(context, 'notes.save'),
            onTap: (_busy || _note.text.trim().isEmpty) ? null : _save,
          ),
          _skip(),
        ],
      );
    }
    if (_reply != null || _quotaHit) {
      return CosmicCtaButton(
        label: t(context, 'common.next'),
        onTap: _busy ? null : widget.onDone,
      );
    }
    return _skip();
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
              child: !_ready
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: _saved ? _proofStep() : _noteStep(),
                          ),
                        ),
                        if (_errKey != null) _error(),
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