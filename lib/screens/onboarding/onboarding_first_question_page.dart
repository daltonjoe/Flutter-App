import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_background.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';
import '../../presentation/widgets/components/cosmic_input_field.dart';
import '../../redesign/ask/star_typing.dart';

const String _k = 'onboarding.first_question.';
const String _prefNoteId = 'onboarding_note_id';
const List<String> _pool = ['job', 'relationship', 'move', 'decision', 'goal'];

class _Line {
  const _Line(this.mine, this.text, {this.sample = false});
  final bool mine;
  final String text;
  final bool sample;
}

/// S13: ilk soru. API yok (K4): cevap statik ve "Ornek yanit" etiketlidir.
/// S14'te secilen notun derinlestirici sorusu (K7) mesaj alanina gelir.
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
  Timer? _wait;
  Timer? _type;
  bool _busy = false;
  bool _loaded = false;
  String? _noteId;
  String? _deepText;
  List<String> _chipIds = const [];
  String? _full;
  int _shown = 0;

  bool get _canContinue => _lines.any((l) => !l.mine);

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _wait?.cancel();
    _type?.cancel();
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    String? id;
    try {
      final p = await SharedPreferences.getInstance();
      id = p.getString(_prefNoteId);
    } catch (e) {
      debugPrint('Onboarding note id read failed: $e');
    }
    if (!mounted) return;
    final nid = (id != null && _pool.contains(id)) ? id : null;
    // S13'te serbest metin yok (K26-A): cevaplar yalniz hazir konu ciplerinden
    // gelir; secilen konu cipin disinda kalan 3 konu alternatif olur.
    final chips = (List<String>.of(_pool)..shuffle())
        .where((e) => e != nid)
        .take(3)
        .toList();
    setState(() {
      _loaded = true;
      _noteId = nid;
      _chipIds = chips;
      if (nid != null) {
        final q = t(context, '${_k}deep_$nid');
        _deepText = q;
        _ctl.value = TextEditingValue(
          text: q,
          selection: TextSelection.collapsed(offset: q.length),
        );
      }
    });
  }

  void _scrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
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

  /// [replyKey] verilirse (konu cipleri) dogrudan o statik yanit doner.
  /// Verilmezse salt okunur kutudaki hazir soru `reply_<not>` dalina gider;
  /// serbest metin reply_generic yolu korunur ama artik erisilemez.
  void _ask(String raw, {String? replyKey}) {
    final text = raw.trim();
    if (text.isEmpty || _busy || _canContinue) return;
    final deep = _noteId != null && text == _deepText;
    final key =
        replyKey ?? (deep ? '${_k}reply_$_noteId' : '${_k}reply_generic');
    HapticFeedback.selectionClick();
    _ctl.clear();
    _finishTyping();
    setState(() {
      _lines.add(_Line(true, text));
      _busy = true;
    });
    _scrollEnd();
    final reduce = MediaQuery.disableAnimationsOf(context);
    _wait?.cancel();
    _wait = Timer(
      reduce ? Duration.zero : const Duration(milliseconds: 1400),
      () {
        if (!mounted) return;
        final reply = t(context, key);
        setState(() {
          _lines.add(_Line(false, reply, sample: true));
          _busy = false;
        });
        _scrollEnd();
        _startTyping(reply);
      },
    );
  }

  Widget _chip(String id) {
    final label = t(context, 'onboarding.memory.chip_$id');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _busy ? null : () => _ask(label, replyKey: '${_k}reply_$id'),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.gold.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
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
            if (_loaded)
              for (final id in _chipIds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _chip(id),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text,
                      style: AppTextStyles.bodyMd(color: AppColors.starlight)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _waiting() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: StarTyping(),
      ),
    );
  }

  Widget _input() {
    // Hazir soru yoksa (S14'te konu secilmediyse) kutu gosterilmez.
    if (_canContinue || _noteId == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          // K26-A: serbest metin yok. Klavye acilmaz, odak/cursor olmaz;
          // S14'te secilen notun derinlestirici sorusu hazir gorunur.
          child: ExcludeFocus(
            child: CosmicInputField(
              label: t(context, '${_k}free_label'),
              icon: Icons.auto_awesome_outlined,
              controller: _ctl,
              readOnly: true,
              hint: t(context, '${_k}free_hint'),
            ),
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
