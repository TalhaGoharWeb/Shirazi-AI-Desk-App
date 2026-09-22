import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/localization/app_strings.dart';

class ChatComposer extends StatefulWidget {
  final bool isGenerating;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onStop;
  final String selectedMadhhab;
  final ValueChanged<String> onMadhhabChanged;
  final String selectedPersona;
  final ValueChanged<String> onPersonaChanged;

  const ChatComposer({
    super.key,
    required this.isGenerating,
    required this.onSubmit,
    this.onStop,
    required this.selectedMadhhab,
    required this.onMadhhabChanged,
    required this.selectedPersona,
    required this.onPersonaChanged,
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
        color: ShiraziColors.surfaceContainerLow.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x44D4AF37), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Settings Header Bar inside the composer (Madhhab & Persona pills)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
            child: Row(
              children: [
                // Madhhab selector popup / pill
                PopupMenuButton<String>(
                  initialValue: widget.selectedMadhhab,
                  color: ShiraziColors.surfaceContainerLowest,
                  onSelected: widget.onMadhhabChanged,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ShiraziColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x33D4AF37)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_outlined, size: 12, color: ShiraziColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          widget.selectedMadhhab == 'Comparative'
                              ? (strings.lang == 'ur'
                                  ? 'فقہ مقارن'
                                  : strings.lang == 'ar'
                                      ? 'مقارن'
                                      : 'Comparative')
                              : (widget.selectedMadhhab.isEmpty ? 'Hanafi' : widget.selectedMadhhab),
                          style: ShiraziTypography.dynamicLabel(
                            strings.lang,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: ShiraziColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, size: 14, color: ShiraziColors.outline),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    'Hanafi',
                    'Maliki',
                    'Shafi\'i',
                    'Hanbali',
                    'Comparative',
                  ].map((m) {
                    final label = m == 'Comparative'
                        ? (strings.lang == 'ur'
                            ? 'فقہ مقارن (تمام ۴ مذاہب)'
                            : strings.lang == 'ar'
                                ? 'الفقه المقارن (المذاهب الأربعة)'
                                : 'Comparative Fiqh (All 4 Schools)')
                        : m;
                    return PopupMenuItem(
                      value: m,
                      child: Row(
                        children: [
                          if (m == 'Comparative') ...[
                            const Icon(Icons.balance, size: 14, color: ShiraziColors.primary),
                            const SizedBox(width: 6),
                          ],
                          Text(label, style: ShiraziTypography.dynamicBody(strings.lang, fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 8),

                // Persona selector popup / pill
                PopupMenuButton<String>(
                  initialValue: widget.selectedPersona,
                  color: ShiraziColors.surfaceContainerLowest,
                  onSelected: widget.onPersonaChanged,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ShiraziColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology, size: 12, color: ShiraziColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          widget.selectedPersona == 'muhaqqiq'
                              ? 'Muhaqqiq (Investigator)'
                              : (widget.selectedPersona == 'mufti'
                                  ? 'Mufti (Rulings)'
                                  : 'Talib (Student)'),
                          style: ShiraziTypography.dynamicLabel(
                            strings.lang,
                            fontSize: 11,
                            color: ShiraziColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, size: 14, color: ShiraziColors.outline),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'muhaqqiq', child: Text('Muhaqqiq (Academic Investigator)')),
                    const PopupMenuItem(value: 'mufti', child: Text('Mufti (Clear Jurisprudential Rulings)')),
                    const PopupMenuItem(value: 'talib', child: Text('Talib al-Ilm (Educational Foundations)')),
                  ],
                ),
              ],
            ),
          ),

          // Main Multiline Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  _submit();
                }
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textDirection: strings.direction,
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
                    color: ShiraziColors.outline,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),

          // Actions Row (Attachment, Voice, Send/Stop)
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file_rounded, size: 20, color: ShiraziColors.outline),
                      tooltip: 'Attach Manuscript or Document',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document attachment selected for scholarly review'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic_none_rounded, size: 20, color: ShiraziColors.outline),
                      tooltip: 'Voice Input',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scholarly speech recognition active...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Send or Stop Generating Button
                if (widget.isGenerating)
                  InkWell(
                    onTap: widget.onStop,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: ShiraziColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ShiraziColors.error.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stop_circle_outlined, size: 16, color: ShiraziColors.error),
                          const SizedBox(width: 6),
                          Text(
                            strings.stopGenerating,
                            style: ShiraziTypography.dynamicLabel(
                              strings.lang,
                              fontSize: 11,
                              color: ShiraziColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: _hasText ? _submit : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _hasText ? ShiraziColors.primary : ShiraziColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          size: 20,
                          color: _hasText ? ShiraziColors.onPrimary : ShiraziColors.outline,
                        ),
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
}
