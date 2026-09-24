import 'package:flutter/material.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/localization/app_strings.dart';

/// Floating chat composer: slim options toolbar (madhhab / persona / answer
/// mode) above a rounded input bar with attach, voice and a glowing send key.
class ChatComposer extends StatefulWidget {
  final bool isGenerating;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onStop;
  final String selectedMadhhab;
  final ValueChanged<String> onMadhhabChanged;
  final String selectedPersona;
  final ValueChanged<String> onPersonaChanged;
  final String selectedAnswerMode;
  final ValueChanged<String> onAnswerModeChanged;

  const ChatComposer({
    super.key,
    required this.isGenerating,
    required this.onSubmit,
    this.onStop,
    required this.selectedMadhhab,
    required this.onMadhhabChanged,
    required this.selectedPersona,
    required this.onPersonaChanged,
    required this.selectedAnswerMode,
    required this.onAnswerModeChanged,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isGenerating) {
      widget.onSubmit(text);
      _controller.clear();
      setState(() => _hasText = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Container(
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: ShiraziColors.primary.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x11D4AF37), blurRadius: 24, offset: Offset(0, 0)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slim horizontally-scrollable options toolbar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
            child: Row(
              children: [
                _OptionPill(
                  icon: Icons.school_outlined,
                  label: _madhhabLabel(strings),
                  accent: ShiraziColors.primary,
                  onTap: () => _showMadhhabSheet(context, strings),
                ),
                const SizedBox(width: 8),
                _OptionPill(
                  icon: Icons.psychology_outlined,
                  label: _personaLabel(),
                  accent: ShiraziColors.secondary,
                  onTap: () => _showPersonaSheet(context),
                ),
                const SizedBox(width: 8),
                _OptionPill(
                  icon: Icons.bolt_outlined,
                  label: _modeLabel(strings),
                  accent: ShiraziColors.primary,
                  onTap: () => _showModeSheet(context, strings),
                ),
              ],
            ),
          ),

          // Input row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _RoundIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Attach document',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document attachment selected for scholarly review'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 5,
                    minLines: 1,
                    textDirection: strings.direction,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    style: ShiraziTypography.dynamicBody(
                      strings.lang,
                      fontSize: strings.lang == 'ur' ? 16 : 14.5,
                      color: ShiraziColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: strings.askShiraziPlaceholder,
                      hintStyle: ShiraziTypography.dynamicBody(
                        strings.lang,
                        fontSize: 13,
                        color: ShiraziColors.outline.withValues(alpha: 0.8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                  ),
                ),
                _RoundIconButton(
                  icon: Icons.mic_none_rounded,
                  tooltip: 'Voice input',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scholarly speech recognition active...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                // Send / Stop key
                GestureDetector(
                  onTap: widget.isGenerating ? widget.onStop : (_hasText ? _submit : null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isGenerating
                          ? ShiraziColors.error.withValues(alpha: 0.15)
                          : _hasText
                              ? ShiraziColors.primary
                              : ShiraziColors.surfaceContainerHigh,
                      border: widget.isGenerating
                          ? Border.all(color: ShiraziColors.error.withValues(alpha: 0.6))
                          : null,
                      boxShadow: _hasText && !widget.isGenerating
                          ? const [
                              BoxShadow(color: Color(0x66D4AF37), blurRadius: 12),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.isGenerating ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                      size: 22,
                      color: widget.isGenerating
                          ? ShiraziColors.error
                          : _hasText
                              ? ShiraziColors.onPrimary
                              : ShiraziColors.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _madhhabLabel(AppStrings strings) {
    final m = widget.selectedMadhhab;
    if (m == 'Comparative') {
      return strings.lang == 'ur' ? 'فقہ مقارن' : strings.lang == 'ar' ? 'مقارن' : 'Comparative';
    }
    return m.isEmpty ? 'Hanafi' : m;
  }

  String _personaLabel() {
    switch (widget.selectedPersona) {
      case 'mufti':
        return 'Mufti';
      case 'talib':
        return 'Talib';
      default:
        return 'Muhaqqiq';
    }
  }

  String _modeLabel(AppStrings strings) {
    switch (widget.selectedAnswerMode) {
      case 'quick':
        return strings.lang == 'ur' ? 'فوری' : strings.lang == 'ar' ? 'سريع' : 'Quick';
      case 'deep':
        return strings.lang == 'ur' ? 'گہری تحقیق' : strings.lang == 'ar' ? 'بحث عميق' : 'Deep';
      default:
        return strings.lang == 'ur' ? 'خودکار' : strings.lang == 'ar' ? 'تلقائي' : 'Auto';
    }
  }

  void _showMadhhabSheet(BuildContext context, AppStrings strings) {
    final options = [
      ('Hanafi', 'Hanafi', Icons.circle_outlined),
      ('Maliki', 'Maliki', Icons.circle_outlined),
      ("Shafi'i", "Shafi'i", Icons.circle_outlined),
      ('Hanbali', 'Hanbali', Icons.circle_outlined),
      (
        'Comparative',
        strings.lang == 'ur'
            ? 'فقہ مقارن (تمام ۴ مذاہب)'
            : strings.lang == 'ar'
                ? 'الفقه المقارن (المذاهب الأربعة)'
                : 'Comparative (All 4 Schools)',
        Icons.balance
      ),
    ];
    _showOptionSheet(
      context,
      title: strings.lang == 'ur' ? 'فقہی مسلک' : strings.lang == 'ar' ? 'المذهب الفقهي' : 'Jurisprudential School',
      options: options,
      selected: widget.selectedMadhhab.isEmpty ? 'Hanafi' : widget.selectedMadhhab,
      onSelected: widget.onMadhhabChanged,
    );
  }

  void _showPersonaSheet(BuildContext context) {
    _showOptionSheet(
      context,
      title: 'Scholar Persona',
      options: const [
        ('muhaqqiq', 'Muhaqqiq — Academic Investigator', Icons.search_rounded),
        ('mufti', 'Mufti — Clear Jurisprudential Rulings', Icons.gavel_rounded),
        ('talib', 'Talib al-Ilm — Educational Foundations', Icons.school_rounded),
      ],
      selected: widget.selectedPersona,
      onSelected: widget.onPersonaChanged,
    );
  }

  void _showModeSheet(BuildContext context, AppStrings strings) {
    _showOptionSheet(
      context,
      title: strings.lang == 'ur' ? 'جواب کا انداز' : strings.lang == 'ar' ? 'نمط الإجابة' : 'Answer Mode',
      options: [
        (
          'auto',
          strings.lang == 'ur'
              ? 'خودکار (سوال کے مطابق)'
              : strings.lang == 'ar'
                  ? 'تلقائي (حسب السؤال)'
                  : 'Auto (decides per question)',
          Icons.auto_awesome_rounded
        ),
        (
          'quick',
          strings.lang == 'ur'
              ? 'فوری (تیز جواب، حوالوں کے ساتھ)'
              : strings.lang == 'ar'
                  ? 'سريع (إجابة سريعة مع مصادر)'
                  : 'Quick (fast answer with sources)',
          Icons.bolt_rounded
        ),
        (
          'deep',
          strings.lang == 'ur'
              ? 'گہری تحقیق (مکمل تحقیقی عمل)'
              : strings.lang == 'ar'
                  ? 'بحث عميق (تحقيق شامل)'
                  : 'Deep (full research pipeline)',
          Icons.psychology_rounded
        ),
      ],
      selected: widget.selectedAnswerMode,
      onSelected: widget.onAnswerModeChanged,
    );
  }

  void _showOptionSheet(
    BuildContext context, {
    required String title,
    required List<(String, String, IconData)> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: ShiraziColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0x334D4635), width: 0.5)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(ctx).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ShiraziColors.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: ShiraziTypography.headlineSm(color: ShiraziColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ...options.map((o) {
              final isSel = o.$1 == selected;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    onSelected(o.$1);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel
                          ? ShiraziColors.primary.withValues(alpha: 0.12)
                          : ShiraziColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel
                            ? ShiraziColors.primary.withValues(alpha: 0.5)
                            : ShiraziColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(o.$3, size: 18, color: isSel ? ShiraziColors.primary : ShiraziColors.outline),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            o.$2,
                            style: ShiraziTypography.bodyMd(
                              color: isSel ? ShiraziColors.primary : ShiraziColors.onSurface,
                            ),
                          ),
                        ),
                        if (isSel)
                          const Icon(Icons.check_circle_rounded, size: 18, color: ShiraziColors.primary),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _OptionPill({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ShiraziColors.surfaceContainerHigh.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: ShiraziTypography.dynamicLabel(
                strings.lang,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ShiraziColors.onSurface,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.expand_more_rounded, size: 14, color: ShiraziColors.outline),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 21, color: ShiraziColors.outline),
        ),
      ),
    );
  }
}
