import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../i18n/app_localizations.dart';
import '../../presentation/widgets/components/cosmic_background.dart';
import '../../presentation/widgets/components/cosmic_cta_button.dart';

const String _k = 'onboarding.memory.';
const String _prefNote = 'onboarding_note';
const String _prefNoteId = 'onboarding_note_id';
const List<String> _pool = ['job', 'relationship', 'move', 'decision', 'goal'];

/// S14: kullanici kendinden bir not birakir. Not yalnizca cihazda tutulur
/// (API yok); secilen cip kimligi S13'un derinlestirici sorusu icin saklanir.
class OnboardingMemoryPage extends StatefulWidget {
  const OnboardingMemoryPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingMemoryPage> createState() => _OnboardingMemoryPageState();
}

class _OnboardingMemoryPageState extends State<OnboardingMemoryPage> {
  final TextEditingController _note = TextEditingController();
  late final List<String> _ids = (List<String>.of(_pool)..shuffle()).take(3).toList();
  String? _selId;
  String? _selText;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _note.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    final id = (_selId != null && _selText == text) ? _selId : null;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefNote, text);
      if (id != null) {
        await p.setString(_prefNoteId, id);
      } else {
        await p.remove(_prefNoteId);
      }
    } catch (e) {
      debugPrint('Onboarding note save failed: $e');
    }
    if (!mounted) return;
    HapticFeedback.lightImpact();
    widget.onDone();
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

  Widget _field() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.hairline),
    );
    return TextField(
      controller: _note,
      minLines: 1,
      maxLines: 4,
      style: AppTextStyles.bodyMd(color: AppColors.starlight),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
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

  Widget _noteStep() {
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
        _field(),
        const SizedBox(height: 16),
        for (final id in _ids)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _chip(t(context, '${_k}chip_$id'), () {
              final c = t(context, '${_k}chip_$id');
              _selId = id;
              _selText = c;
              _note.value = TextEditingValue(
                text: c,
                selection: TextSelection.collapsed(offset: c.length),
              );
              HapticFeedback.selectionClick();
              setState(() {});
            }),
          ),
      ],
    );
  }

  Widget _skip() {
    return TextButton(
      onPressed: _busy ? null : widget.onDone,
      child: Text(t(context, '${_k}skip'), style: AppTextStyles.ctaSecondary()),
    );
  }

  Widget _bottom() {
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
                  Expanded(
                    child: SingleChildScrollView(child: _noteStep()),
                  ),
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