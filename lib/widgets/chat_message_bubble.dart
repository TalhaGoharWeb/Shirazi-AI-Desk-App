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

/// Chat-style message rendering for the Shirazi conversational interface.
///
/// - User turns: compact gold-tinted bubble, end-aligned (RTL aware).
/// - Assistant turns: emblem avatar + name header, full-width clean content
///   column (no heavy card), collapsible reasoning & citations, slim action
///   footer.
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
    final msg = widget.message;
    return msg.isUser ? _buildUserBubble(context, msg) : _buildAssistantBubble(context, msg);
  }

  // ── User turn ──────────────────────────────────────────────────────────
  Widget _buildUserBubble(BuildContext context, ShiraziChatMessage msg) {
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 6, 12, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3A2F10), Color(0xFF2A2410)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(
                  color: ShiraziColors.primary.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScholarlyMarkdownView(content: msg.content),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(msg.timestamp),
                    style: ShiraziTypography.dynamicLabel(
                      strings.lang,
                      fontSize: 10,
                      color: ShiraziColors.outline.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Assistant turn ─────────────────────────────────────────────────────
  Widget _buildAssistantBubble(BuildContext context, ShiraziChatMessage msg) {
    final strings = AppStrings.of(context);
    final isRtl = strings.isRtl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: emblem avatar + name + provider chip + latency
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: ShiraziColors.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ShiraziColors.primary.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33D4AF37), blurRadius: 8),
                  ],
                ),
                child: const Center(child: ShiraziEmblem(size: 20)),
              ),
              const SizedBox(width: 8),
              Text(
                'SHIRAZI',
                style: ShiraziTypography.dynamicHeadline(
                  strings.lang,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: msg.isError ? Colors.amber : ShiraziColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ShiraziColors.surfaceContainerHigh.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    msg.isError
                        ? (isRtl
                            ? (strings.lang == 'ur' ? 'سروس دستیابی' : 'سعة الخادم')
                            : 'Gateway Limit')
                        : (msg.byokProvider ?? 'Cloud Inference'),
                    style: ShiraziTypography.dynamicLabel(
                      strings.lang,
                      fontSize: 10,
                      color: msg.isError ? Colors.amber : ShiraziColors.secondaryFixedDim,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Spacer(),
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
          const SizedBox(height: 8),

          // Body
          if (msg.messageType == ShiraziMessageType.madhhabClarification) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 38),
              child: ScholarlyMarkdownView(content: msg.content),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MadhhabChip(label: 'حنفی', sublabel: 'Hanafi', madhhab: 'Hanafi'),
                _MadhhabChip(label: 'مالکی', sublabel: 'Maliki', madhhab: 'Maliki'),
                _MadhhabChip(label: 'شافعی', sublabel: "Shafi'i", madhhab: "Shafi'i"),
                _MadhhabChip(label: 'حنبلی', sublabel: 'Hanbali', madhhab: 'Hanbali'),
                _MadhhabChip(label: 'فقہ مقارن', sublabel: 'Comparative (All 4)', madhhab: 'Comparative'),
              ],
            ),
          ] else ...[
            // Collapsible reasoning trace
            if (msg.reasoningSteps.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 38),
                child: _CollapsibleSection(
                  icon: msg.isError ? Icons.alt_route : Icons.psychology_outlined,
                  title: msg.isError
                      ? (strings.lang == 'ur'
                          ? 'فال بیک نظام کی تفصیلات'
                          : (strings.lang == 'ar' ? 'مسار استدعاء الخوادم' : 'Fallback Engine Diagnostics'))
                      : strings.reasoningPipelineTitle,
                  accent: msg.isError ? Colors.amber : ShiraziColors.secondary,
                  expanded: _isReasoningExpanded,
                  onToggle: () => setState(() => _isReasoningExpanded = !_isReasoningExpanded),
                  child: ReasoningStepper(steps: msg.reasoningSteps),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Main content — clean, full width, no card
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 38),
              child: ScholarlyMarkdownView(content: msg.content),
            ),

            // Error recovery actions
            if (msg.isError && msg.canRetry) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 38),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.read<ChatProvider>().retryMessage(msg),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        strings.lang == 'ur'
                            ? 'دوبارہ کوشش کریں'
                            : (strings.lang == 'ar' ? 'إعادة المحاولة' : 'Retry'),
                        style: ShiraziTypography.dynamicLabel(
                          strings.lang,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ShiraziColors.onPrimary,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: ShiraziColors.primary,
                        foregroundColor: ShiraziColors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                            ? 'ذاتی API Key'
                            : (strings.lang == 'ar' ? 'مفتاح شخصي' : 'Personal API Key'),
                        style: ShiraziTypography.dynamicLabel(
                          strings.lang,
                          fontSize: 12,
                          color: ShiraziColors.onSurface,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Urdu annotation note
            if (msg.urduAnnotation != null && msg.urduAnnotation!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 38),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ShiraziColors.primary.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
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
              ),
            ],

            // Citations
            if (msg.citations.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 38),
                child: _CollapsibleSection(
                  icon: Icons.menu_book_rounded,
                  title: '${strings.citationsTitle} (${msg.citations.length})',
                  accent: ShiraziColors.primary,
                  expanded: _isCitationsExpanded,
                  onToggle: () => setState(() => _isCitationsExpanded = !_isCitationsExpanded),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: msg.citations
                        .map(
                          (c) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ShiraziColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: ShiraziColors.outlineVariant.withValues(alpha: 0.4),
                              ),
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
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ],

          // Slim action footer
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 30),
            child: Row(
              children: [
                _ActionIcon(
                  icon: Icons.copy_rounded,
                  tooltip: strings.copyAction,
                  onTap: () => _copy(context, msg.content, strings.copiedNotification),
                ),
                _ActionIcon(
                  icon: Icons.share_outlined,
                  tooltip: strings.shareAction,
                  onTap: () => _copy(context, msg.content, 'Inquiry text copied for sharing.'),
                ),
                _ActionIcon(
                  icon: Icons.volume_up_outlined,
                  tooltip: strings.listenAction,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Audio recitation starting...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const Spacer(),
                Text(
                  _formatTime(msg.timestamp),
                  style: ShiraziTypography.dynamicLabel(
                    strings.lang,
                    fontSize: 10,
                    color: ShiraziColors.outline.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String text, String note) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(note), duration: const Duration(seconds: 2)),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }
}

/// Slim collapsible section used for reasoning traces and citations.
class _CollapsibleSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleSection({
    required this.icon,
    required this.title,
    required this.accent,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ShiraziColors.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: ShiraziTypography.dynamicLabel(
                      strings.lang,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: ShiraziColors.outline,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          child,
        ],
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 15, color: ShiraziColors.outline.withValues(alpha: 0.9)),
      ),
    );
  }
}

/// Quick-reply chip for madhhab selection.
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
        onTap: () => context.read<ChatProvider>().selectMadhhabAndProceed(madhhab),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2510), Color(0xFF1E1C0E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ShiraziColors.primary.withValues(alpha: 0.45),
              width: 1.0,
            ),
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
