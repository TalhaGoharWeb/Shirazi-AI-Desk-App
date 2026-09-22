import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../core/localization/app_strings.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../models/chat_models.dart';
import 'shirazi_emblem.dart';

class ChatHistorySidebar extends StatefulWidget {
  final VoidCallback? onConversationSelected;

  const ChatHistorySidebar({
    super.key,
    this.onConversationSelected,
  });

  @override
  State<ChatHistorySidebar> createState() => _ChatHistorySidebarState();
}

class _ChatHistorySidebarState extends State<ChatHistorySidebar> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final settings = context.watch<SettingsProvider>();
    final strings = AppStrings.of(context);

    // Filter conversations if searching
    List<ShiraziConversation> all = chat.conversations;
    if (_searchQuery.isNotEmpty) {
      all = all.where((c) =>
        c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        c.lastMessagePreview.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerLowest,
        border: Border(
          right: strings.isRtl ? BorderSide.none : const BorderSide(color: Color(0x334D4635), width: 1),
          left: strings.isRtl ? const BorderSide(color: Color(0x334D4635), width: 1) : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          // 1. Sidebar Header with Shirazi Emblem & New Chat Button
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 14, right: 14, bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: ShiraziColors.surfaceContainerHigh,
                        borderRadius: ShiraziRadius.roundedMd,
                        border: Border.all(color: const Color(0x44D4AF37), width: 1),
                      ),
                      child: const Center(child: ShiraziEmblem(size: 24)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.brandTitle,
                            style: ShiraziTypography.dynamicHeadline(
                              strings.lang,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: ShiraziColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Islamic Research Enclave',
                            style: ShiraziTypography.dynamicLabel(
                              strings.lang,
                              fontSize: 10,
                              color: ShiraziColors.primaryFixedDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // New Chat Action Button (inspired by ChatGPT/Claude)
                InkWell(
                  onTap: () {
                    chat.startNewChat();
                    widget.onConversationSelected?.call();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: ShiraziColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ShiraziColors.primary.withValues(alpha: 0.5), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 18, color: ShiraziColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          strings.newChat,
                          style: ShiraziTypography.dynamicHeadline(
                            strings.lang,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ShiraziColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Search Filter Bar
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: ShiraziColors.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 16, color: ShiraziColors.outline),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          style: ShiraziTypography.dynamicBody(
                            strings.lang,
                            fontSize: 12,
                            color: ShiraziColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: strings.searchConversations,
                            hintStyle: ShiraziTypography.dynamicBody(
                              strings.lang,
                              fontSize: 12,
                              color: ShiraziColors.outline,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(Icons.close, size: 14, color: ShiraziColors.outline),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0x224D4635), height: 1),

          // 2. Date-Grouped Conversation List
          Expanded(
            child: all.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        strings.noConversations,
                        style: ShiraziTypography.dynamicBody(
                          strings.lang,
                          fontSize: 12,
                          color: ShiraziColors.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    children: [
                      if (_searchQuery.isNotEmpty) ...[
                        _buildGroupHeader('Results (${all.length})', strings),
                        ...all.map((c) => _buildConversationTile(context, c, chat, strings)),
                      ] else ...[
                        if (chat.todayConversations.isNotEmpty) ...[
                          _buildGroupHeader(strings.todayGroup, strings),
                          ...chat.todayConversations.map((c) => _buildConversationTile(context, c, chat, strings)),
                        ],
                        if (chat.yesterdayConversations.isNotEmpty) ...[
                          _buildGroupHeader(strings.yesterdayGroup, strings),
                          ...chat.yesterdayConversations.map((c) => _buildConversationTile(context, c, chat, strings)),
                        ],
                        if (chat.previous7DaysConversations.isNotEmpty) ...[
                          _buildGroupHeader(strings.previous7DaysGroup, strings),
                          ...chat.previous7DaysConversations.map((c) => _buildConversationTile(context, c, chat, strings)),
                        ],
                        if (chat.olderConversations.isNotEmpty) ...[
                          _buildGroupHeader(strings.olderGroup, strings),
                          ...chat.olderConversations.map((c) => _buildConversationTile(context, c, chat, strings)),
                        ],
                      ],
                    ],
                  ),
          ),

          // 3. Privacy Guarantee Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: ShiraziColors.surfaceContainerLow,
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 13, color: ShiraziColors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    strings.privacyShieldBadge,
                    style: ShiraziTypography.dynamicLabel(
                      strings.lang,
                      fontSize: 10,
                      color: ShiraziColors.secondaryFixedDim,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0x224D4635), height: 1),

          // 4. Researcher Profile Card (Bottom)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: ShiraziColors.surfaceContainerHigh,
                  child: const Icon(Icons.person, size: 18, color: ShiraziColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.isAuthenticated ? settings.scholarName : 'Researcher Node',
                        style: ShiraziTypography.dynamicHeadline(
                          strings.lang,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ShiraziColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        settings.isAuthenticated ? settings.scholarRole : 'Multi-User Isolated',
                        style: ShiraziTypography.dynamicLabel(
                          strings.lang,
                          fontSize: 10,
                          color: ShiraziColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4, left: 8, right: 8),
      child: Text(
        title,
        style: ShiraziTypography.dynamicLabel(
          strings.lang,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: ShiraziColors.primaryFixedDim,
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    ShiraziConversation conv,
    ChatProvider chat,
    AppStrings strings,
  ) {
    final isSelected = chat.currentConversation?.id == conv.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () {
          chat.selectConversation(conv);
          widget.onConversationSelected?.call();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? ShiraziColors.surfaceContainerHigh
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0x55D4AF37) : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 15,
                color: isSelected ? ShiraziColors.primary : ShiraziColors.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conv.title,
                  style: ShiraziTypography.dynamicBody(
                    strings.lang,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? ShiraziColors.onSurface : ShiraziColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Context Options (Rename / Delete)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 15, color: ShiraziColors.outline),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 120),
                color: ShiraziColors.surfaceContainerLowest,
                onSelected: (val) {
                  if (val == 'delete') {
                    chat.deleteConversation(conv.id);
                  } else if (val == 'rename') {
                    _showRenameDialog(context, conv, chat, strings);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 14, color: ShiraziColors.onSurface),
                        const SizedBox(width: 6),
                        Text('Rename', style: ShiraziTypography.dynamicBody(strings.lang, fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 14, color: ShiraziColors.error),
                        const SizedBox(width: 6),
                        Text('Delete', style: ShiraziTypography.dynamicBody(strings.lang, fontSize: 12, color: ShiraziColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    ShiraziConversation conv,
    ChatProvider chat,
    AppStrings strings,
  ) {
    final controller = TextEditingController(text: conv.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShiraziColors.surfaceContainerLow,
        title: Text('Rename Inquiry', style: ShiraziTypography.dynamicHeadline(strings.lang, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: ShiraziTypography.dynamicBody(strings.lang, fontSize: 14, color: ShiraziColors.onSurface),
          decoration: const InputDecoration(
            hintText: 'Enter inquiry title...',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ShiraziColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: ShiraziTypography.dynamicLabel(strings.lang, color: ShiraziColors.outline)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ShiraziColors.primary),
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                chat.renameConversation(conv.id, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: Text('Save', style: ShiraziTypography.dynamicLabel(strings.lang, color: ShiraziColors.onPrimary)),
          ),
        ],
      ),
    );
  }
}
