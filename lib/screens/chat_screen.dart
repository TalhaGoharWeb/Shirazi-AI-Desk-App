import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/localization/app_strings.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/chat_history_sidebar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_composer.dart';
import '../widgets/empty_chat_welcome.dart';
import '../widgets/geometric_pattern.dart';
import '../widgets/reasoning_stepper.dart';
import '../widgets/shirazi_emblem.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const ChatScreen({super.key, this.onProfileTap});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final strings = AppStrings.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 850;
    final isWide = width >= 1100;

    if (chat.isGenerating || chat.messages.isNotEmpty) {
      _scrollToBottom();
    }

    final chatColumn = Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: ShiraziColors.surfaceContainerLowest,
              child: ChatHistorySidebar(
                onConversationSelected: () => Navigator.of(context).pop(),
              ),
            ),
      appBar: _buildAppBar(context, chat, strings, isDesktop),
      body: Stack(
        children: [
          // Message viewport
          Positioned.fill(
            bottom: 118,
            child: (chat.messages.isEmpty && !chat.isGenerating)
                ? EmptyChatWelcome(onPromptSelected: chat.submitQuery)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: chat.messages.length + (chat.isGenerating ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < chat.messages.length) {
                        final msg = chat.messages[index];
                        return ChatMessageBubble(
                          message: msg,
                          isLatestAssistant: msg.isAssistant && index == chat.messages.length - 1,
                        );
                      }
                      // Live thinking state
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const TypingIndicator(),
                                const SizedBox(width: 10),
                                Text(
                                  strings.reasoningPipelineTitle,
                                  style: ShiraziTypography.dynamicLabel(
                                    strings.lang,
                                    fontSize: 11,
                                    color: ShiraziColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ReasoningStepper(steps: chat.currentReasoningSteps),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Floating composer
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: ChatComposer(
              isGenerating: chat.isGenerating,
              onSubmit: chat.submitQuery,
              onStop: chat.cancelCurrentQuery,
              selectedMadhhab: chat.selectedMadhhab,
              onMadhhabChanged: chat.setMadhhab,
              selectedPersona: chat.selectedPersona,
              onPersonaChanged: chat.setPersona,
              selectedAnswerMode: chat.answerMode,
              onAnswerModeChanged: chat.setAnswerMode,
            ),
          ),
        ],
      ),
    );

    final patterned = Stack(
      children: [
        const Positioned.fill(child: GeometricPattern(opacity: 0.035)),
        Positioned.fill(
          child: isWide
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: chatColumn,
                  ),
                )
              : chatColumn,
        ),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: ShiraziColors.background,
        body: Row(
          children: [
            const ChatHistorySidebar(),
            Expanded(child: patterned),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: ShiraziColors.background,
      body: patterned,
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ChatProvider chat,
    AppStrings strings,
    bool isDesktop,
  ) {
    final settings = context.watch<SettingsProvider>();
    final online = chat.serverLatencyMs != null;

    return AppBar(
      backgroundColor: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.85),
      elevation: 0,
      toolbarHeight: 60,
      leading: isDesktop
          ? null
          : IconButton(
              icon: const Icon(Icons.menu_rounded, color: ShiraziColors.onSurface),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ShiraziColors.primary.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: const Center(child: ShiraziEmblem(size: 24)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chat.currentConversation?.title ?? 'Shirazi',
                  style: ShiraziTypography.dynamicHeadline(
                    strings.lang,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ShiraziColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: online ? ShiraziColors.secondary : ShiraziColors.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      online
                          ? '${strings.onlineStatus}${chat.serverLatencyMs != null ? ' • ${chat.serverLatencyMs}ms' : ''}'
                          : strings.connectingStatus,
                      style: ShiraziTypography.dynamicLabel(
                        strings.lang,
                        fontSize: 10,
                        color: ShiraziColors.secondaryFixedDim,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_note_rounded, color: ShiraziColors.primary),
          tooltip: strings.newChat,
          onPressed: chat.startNewChat,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: widget.onProfileTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ShiraziColors.surfaceContainerHigh,
                border: Border.all(
                  color: ShiraziColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Center(
                child: Text(
                  _initial(settings.scholarName),
                  style: ShiraziTypography.dynamicHeadline(
                    strings.lang,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ShiraziColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '؟';
    final rune = t.runes.first;
    return String.fromCharCode(rune).toUpperCase();
  }
}
