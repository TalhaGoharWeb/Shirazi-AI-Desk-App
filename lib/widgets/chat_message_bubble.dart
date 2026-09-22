import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/localization/app_strings.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../screens/settings_byok_screen.dart';
import 'shirazi_emblem.dart';
import 'reasoning_stepper.dart';
import 'scholarly_markdown_view.dart';

class ChatMessageBubble extends StatefulWidget {
  final ShiraziChatMessage message;
  final bool isLatestAssistant;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isLatestAssistant = false,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isReasoningExpanded = false;
  bool _isCitationsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final msg = widget.message;

    if (msg.isUser) {
      return _buildUserBubble(context, msg, strings);
    } else {
      return _buildAssistantBubble(context, msg, strings);
    }
  }

  // 1. User Query Bubble
  Widget _buildUserBubble(
    BuildContext context,
    ShiraziChatMessage msg,
    AppStrings strings,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ShiraziColors.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  topRight: Radius.circular(4),
                ),
                border: Border.all(
                  color: ShiraziColors.primary.withValues(alpha: 0.35),
                  width: 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ScholarlyMarkdownView(content: msg.content),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(msg.timestamp),
                        style: ShiraziTypography.dynamicLabel(
                          strings.lang,
                          fontSize: 10,
                          color: ShiraziColors.outline,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.copiedNotification),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Icon(Icons.copy_rounded, size: 13, color: ShiraziColors.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: ShiraziColors.surfaceContainerHigh,
            child: const Icon(Icons.person, size: 16, color: ShiraziColors.primary),
          ),
        ],
      ),
    );
  }

  // 2. Shirazi AI Scholarly Assistant Bubble
  Widget _buildAssistantBubble(
    BuildContext context,
    ShiraziChatMessage msg,
    AppStrings strings,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shirazi Emblem Avatar
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: ShiraziColors.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x66D4AF37), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x33D4AF37), blurRadius: 6),
              ],
            ),
            child: const Center(child: ShiraziEmblem(size: 22)),
          ),
          const SizedBox(width: 10),

          // Main Response Enclave
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShiraziColors.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  topLeft: Radius.circular(4),
                ),
                border: Border.all(
                  color: const Color(0x334D4635),
                  width: 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Response Header: Brand, Latency, BYOK Provider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'SHIRAZI AI',
                            style: ShiraziTypography.dynamicHeadline(
                              strings.lang,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: msg.isError ? Colors.amber : ShiraziColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: msg.isError
                                  ? Colors.amber.withOpacity(0.15)
                                  : ShiraziColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                              border: msg.isError
                                  ? Border.all(color: Colors.amber.withOpacity(0.4), width: 0.8)
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (msg.isError) ...[
                                  const Icon(Icons.info_outline, size: 10, color: Colors.amber),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  msg.isError
                                      ? (strings.lang == 'ur'
                                          ? 'سروس دستیابی'
                                          : (strings.lang == 'ar' ? 'سعة الخادم' : 'Gateway Limit'))
                                      : (msg.byokProvider ?? 'Cloud Inference'),
                                  style: ShiraziTypography.dynamicLabel(
                                    strings.lang,
                                    fontSize: 9,
                                    color: msg.isError ? Colors.amber : ShiraziColors.secondaryFixedDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (msg.latencyMs != null && !msg.isError)
                        Text(
                          '${msg.latencyMs}ms',
                          style: ShiraziTypography.dynamicLabel(
                            strings.lang,
                            fontSize: 10,
                            color: ShiraziColors.outline,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Madhhab Clarification Chips ──────────────────────────
                  // Rendered when Shirazi needs the user to specify their
                  // jurisprudential school before answering (Rule 2).
                  if (msg.messageType == ShiraziMessageType.madhhabClarification) ...[
                    ScholarlyMarkdownView(
                      content: msg.content,
                    ),
                    const SizedBox(height: 16),
                    const Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MadhhabChip(
                          label: 'حنفی',
                          sublabel: 'Hanafi',
                          madhhab: 'Hanafi',
                        ),
                        _MadhhabChip(
                          label: 'مالکی',
                          sublabel: 'Maliki',
                          madhhab: 'Maliki',
                        ),
                        _MadhhabChip(
                          label: 'شافعی',
                          sublabel: "Shafi'i",
                          madhhab: "Shafi'i",
                        ),
                        _MadhhabChip(
                          label: 'حنبلی',
                          sublabel: 'Hanbali',
                          madhhab: 'Hanbali',
                        ),
                        _MadhhabChip(
                          label: 'فقہ مقارن',
                          sublabel: 'Comparative (All 4)',
                          madhhab: 'Comparative',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                  // ── Normal content rendering ─────────────────────────────

                  // Collapsible Reasoning Pipeline (like DeepSeek / Claude Thinking)
                  if (msg.reasoningSteps.isNotEmpty) ...[
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isReasoningExpanded = !_isReasoningExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ShiraziColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              msg.isError ? Icons.alt_route : Icons.psychology_outlined,
                              size: 14,
                              color: msg.isError ? Colors.amber : ShiraziColors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                msg.isError
                                    ? (strings.lang == 'ur'
                                        ? 'فال بیک نظام کی تفصیلات'
                                        : (strings.lang == 'ar' ? 'مسار استدعاء الخوادم' : 'Fallback Engine Diagnostics'))
                                    : strings.reasoningPipelineTitle,
                                style: ShiraziTypography.dynamicLabel(
                                  strings.lang,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: msg.isError ? Colors.amber : ShiraziColors.secondary,
                                ),
                              ),
                            ),
                            Icon(
                              _isReasoningExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 16,
                              color: ShiraziColors.outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isReasoningExpanded) ...[
                      const SizedBox(height: 8),
                      ReasoningStepper(steps: msg.reasoningSteps),
                    ],
                    const SizedBox(height: 12),
                  ],

                  // Complete, un-truncated Scholarly Response rendered with rich typography & RTL/LTR detection
                  ScholarlyMarkdownView(content: msg.content),

                  // Graceful Exhaustion Action Bar: 1-Tap Retry & BYOK Config Shortcut
                  if (msg.isError && msg.canRetry) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<ChatProvider>().retryMessage(msg);
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(
                            strings.lang == 'ur'
                                ? 'دوبارہ کوشش کریں'
                                : (strings.lang == 'ar' ? 'إعادة المحاولة' : 'Retry Query'),
                            style: ShiraziTypography.dynamicLabel(
                              strings.lang,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ShiraziColors.onPrimary,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ShiraziColors.primary,
                            foregroundColor: ShiraziColors.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsByokScreen()),
                            );
                          },
                          icon: const Icon(Icons.key, size: 16, color: ShiraziColors.secondary),
                          label: Text(
                            strings.lang == 'ur'
                                ? 'ذاتی API Key درج کریں'
                                : (strings.lang == 'ar' ? 'إعداد مفتاح شخصي' : 'Configure Fallback Keys'),
                            style: ShiraziTypography.dynamicLabel(
                              strings.lang,
                              fontSize: 12,
                              color: ShiraziColors.onSurface,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: ShiraziColors.outlineVariant.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Urdu Annotation / Summary note if available
                  if (msg.urduAnnotation != null && msg.urduAnnotation!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x33D4AF37), width: 0.8),
                      ),
                      child: Text(
                        msg.urduAnnotation!,
                        style: ShiraziTypography.urdu(
                          fontSize: 14,
                          color: ShiraziColors.primaryFixedDim,
                          height: 1.8,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],

                  // Expandable Primary Sources & Citations
                  if (msg.citations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isCitationsExpanded = !_isCitationsExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ShiraziColors.surfaceContainerHigh.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 14, color: ShiraziColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${strings.citationsTitle} (${msg.citations.length})',
                                style: ShiraziTypography.dynamicLabel(
                                  strings.lang,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: ShiraziColors.primary,
                                ),
                              ),
                            ),
                            Icon(
                              _isCitationsExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 16,
                              color: ShiraziColors.outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isCitationsExpanded) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: msg.citations.map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ShiraziColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0x334D4635)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bookmark_border, size: 12, color: ShiraziColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                c,
                                style: ShiraziTypography.dynamicLabel(
                                  strings.lang,
                                  fontSize: 11,
                                  color: ShiraziColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                  ],

                  ], // end of else (non-madhhabClarification content)

                  const SizedBox(height: 14),
                  const Divider(color: Color(0x224D4635), height: 1),
                  const SizedBox(height: 6),

                  // Actions Footer: Copy, Share, Audio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16, color: ShiraziColors.outline),
                            tooltip: strings.copyAction,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: msg.content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(strings.copiedNotification),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, size: 16, color: ShiraziColors.outline),
                            tooltip: strings.shareAction,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: msg.content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Inquiry text copied for sharing.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up_outlined, size: 16, color: ShiraziColors.outline),
                            tooltip: strings.listenAction,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Audio recitation starting...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        _formatTime(msg.timestamp),
                        style: ShiraziTypography.dynamicLabel(
                          strings.lang,
                          fontSize: 10,
                          color: ShiraziColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }
}

/// Quick-reply chip for madhhab selection.
/// Displayed when Shirazi asks the user to specify their jurisprudential school.
class _MadhhabChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final String madhhab;

  const _MadhhabChip({
    required this.label,
    required this.sublabel,
    required this.madhhab,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<ChatProvider>().selectMadhhabAndProceed(madhhab);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2510), Color(0xFF1E1C0E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0x88D4AF37),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44D4AF37),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Noto Nastaliq Urdu',
                  fontSize: 16,
                  color: Color(0xFFD4AF37),
                  height: 1.4,
                ),
                textDirection: TextDirection.rtl,
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  color: Color(0xFFB8A060),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
