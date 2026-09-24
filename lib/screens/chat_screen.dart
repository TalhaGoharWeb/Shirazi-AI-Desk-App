import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/localization/app_strings.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_history_sidebar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_composer.dart';
import '../widgets/empty_chat_welcome.dart';
import '../widgets/reasoning_stepper.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

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
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    // Auto-scroll when messages change or generation starts
    if (chat.isGenerating || chat.messages.isNotEmpty) {
      _scrollToBottom();
    }

    final chatContent = Scaffold(
      key: _scaffoldKey,
      backgroundColor: ShiraziColors.background,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: ShiraziColors.surfaceContainerLowest,
              child: ChatHistorySidebar(
                onConversationSelected: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
      appBar: AppBar(
        backgroundColor: ShiraziColors.surfaceContainerLowest,
        elevation: 0,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded, color: ShiraziColors.onSurface),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chat.currentConversation?.title ?? strings.newChat,
              style: ShiraziTypography.dynamicHeadline(
                strings.lang,
                fontSize: 14.5,
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
                  decoration: const BoxDecoration(
                    color: ShiraziColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  chat.serverLatencyMs != null
                      ? 'Shirazi Online Cluster (${chat.serverLatencyMs}ms)'
                      : 'Connecting to Cloud...',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: ShiraziColors.primary),
            tooltip: strings.newChat,
            onPressed: () {
              chat.startNewChat();
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          // Message Viewport or Empty State
          Positioned.fill(
            bottom: 120, // space for elevated composer
            child: (chat.messages.isEmpty && !chat.isGenerating)
                ? EmptyChatWelcome(
                    onPromptSelected: (prompt) {
                      chat.submitQuery(prompt);
                    },
                  )
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
                      } else {
                        // Live Reasoning Stepper while streaming
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(ShiraziColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    strings.reasoningPipelineTitle,
                                    style: ShiraziTypography.dynamicLabel(
                                      strings.lang,
                                      fontSize: 11,
                                      color: ShiraziColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ReasoningStepper(steps: chat.currentReasoningSteps),
                            ],
                          ),
                        );
                      }
                    },
                  ),
          ),

          // Elevated Floating Composer Console
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: ChatComposer(
              isGenerating: chat.isGenerating,
              onSubmit: (text) {
                chat.submitQuery(text);
              },
              onStop: () {
                chat.cancelCurrentQuery();
              },
              selectedMadhhab: chat.selectedMadhhab,
              onMadhhabChanged: chat.setMadhhab,
              selectedPersona: chat.selectedPersona,
              onPersonaChanged: chat.setPersona,
            ),
          ),
        ],
      ),
    );

    // Responsive Desktop Layout with Persistent Sidebar
    if (isDesktop) {
      return Scaffold(
        backgroundColor: ShiraziColors.background,
        body: Row(
          children: [
            const ChatHistorySidebar(),
            Expanded(child: chatContent),
          ],
        ),
      );
    }

    return chatContent;
  }
}
