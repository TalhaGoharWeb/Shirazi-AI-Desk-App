import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../providers/admin_provider.dart';
import '../providers/research_provider.dart';
import '../models/chat_models.dart';
import 'admin_health_screen.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  int _selectedTab = 0; // 0: Multi-User Conversations, 1: Server Cluster Fatwas
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: ShiraziColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ShiraziColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ADMIN RESEARCH DASHBOARD',
                  style: ShiraziTypography.labelSm(
                    color: ShiraziColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: ShiraziColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Text(
              'Multi-User Oversight & Centralized Audit',
              style: ShiraziTypography.headlineSm(color: ShiraziColors.onSurface).copyWith(fontSize: 15),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: ShiraziColors.primary),
            tooltip: 'Cluster Health & BYOK',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminHealthScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: ShiraziColors.onSurfaceVariant),
            tooltip: 'Refresh Telemetry',
            onPressed: () {
              admin.fetchAuditInquiries();
              admin.refreshDiagnostics();
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: !admin.isAdminVerified
          ? _buildAccessDeniedScreen(context, admin)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: ShiraziSpacing.gutterMobile).copyWith(
                top: 12,
                bottom: 30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Telemetry Banner
                  _buildTelemetryBanner(admin),
                  const SizedBox(height: 14),

                  // 2. Tab Segment Control
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ShiraziColors.surfaceContainerLow,
                      borderRadius: ShiraziRadius.roundedFull,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTab = 0),
                            borderRadius: ShiraziRadius.roundedFull,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? ShiraziColors.primary : Colors.transparent,
                                borderRadius: ShiraziRadius.roundedFull,
                              ),
                              child: Center(
                                child: Text(
                                  'User Inquiries (${admin.filteredConversations.length})',
                                  style: ShiraziTypography.labelMd(
                                    color: _selectedTab == 0 ? ShiraziColors.onPrimary : ShiraziColors.onSurfaceVariant,
                                    fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTab = 1),
                            borderRadius: ShiraziRadius.roundedFull,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? ShiraziColors.primary : Colors.transparent,
                                borderRadius: ShiraziRadius.roundedFull,
                              ),
                              child: Center(
                                child: Text(
                                  'Server Fatwas (${admin.auditInquiries.length})',
                                  style: ShiraziTypography.labelMd(
                                    color: _selectedTab == 1 ? ShiraziColors.onPrimary : ShiraziColors.onSurfaceVariant,
                                    fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Search & Filter Bar
                  _buildFilterBar(admin),
                  const SizedBox(height: 16),

                  // 4. Tab Content
                  if (_selectedTab == 0)
                    _buildUserConversationsView(context, admin)
                  else
                    _buildServerFatwasView(context, admin),
                ],
              ),
            ),
    );
  }

  Widget _buildAccessDeniedScreen(BuildContext context, AdminProvider admin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ShiraziColors.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: ShiraziColors.error),
              ),
              child: const Icon(Icons.gpp_bad, size: 40, color: ShiraziColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              'ACCESS RESTRICTED',
              style: ShiraziTypography.headlineSm(color: ShiraziColors.error).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'This research oversight portal is strictly restricted to verified administrators via Firestore Security Rules.',
              textAlign: TextAlign.center,
              style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Request admin elevation check
                admin.checkAdminStatus();
              },
              icon: const Icon(Icons.verified_user),
              label: const Text('Re-verify Administrative Credentials'),
              style: ElevatedButton.styleFrom(backgroundColor: ShiraziColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryBanner(AdminProvider admin) {
    return Container(
      padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerLow,
        borderRadius: ShiraziRadius.roundedXl,
        border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: ShiraziColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CENTRALIZED AUDIT TELEMETRY',
                        style: ShiraziTypography.labelSm(
                          color: ShiraziColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${admin.filteredConversations.length} User Research Threads',
                        style: ShiraziTypography.headlineSm(color: ShiraziColors.onSurface).copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ShiraziColors.surfaceContainerHighest,
                  borderRadius: ShiraziRadius.roundedFull,
                ),
                child: Text(
                  'Firestore Security Enforced',
                  style: ShiraziTypography.labelSm(color: ShiraziColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AdminProvider admin) {
    return Column(
      children: [
        // Search Input
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: ShiraziColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: ShiraziColors.outline),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: admin.setSearchFilter,
                  style: ShiraziTypography.bodySm(color: ShiraziColors.onSurface),
                  decoration: const InputDecoration(
                    hintText: 'Filter by user, inquiry title, or keyword...',
                    hintStyle: TextStyle(color: ShiraziColors.outline, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    admin.setSearchFilter('');
                  },
                  child: const Icon(Icons.close, size: 16, color: ShiraziColors.outline),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Madhhab Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Hanafi', 'Maliki', 'Shafi\'i', 'Hanbali'].map((m) {
              final isSel = admin.selectedMadhhabFilter == m;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(m),
                  selected: isSel,
                  onSelected: (_) => admin.setMadhhabFilter(m),
                  selectedColor: ShiraziColors.primary,
                  backgroundColor: ShiraziColors.surfaceContainerLow,
                  labelStyle: TextStyle(
                    color: isSel ? ShiraziColors.onPrimary : ShiraziColors.onSurface,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUserConversationsView(BuildContext context, AdminProvider admin) {
    final list = admin.filteredConversations;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No user conversations match the filter.',
            style: ShiraziTypography.bodySm(color: ShiraziColors.outline),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final conv = list[idx];
        return _buildConversationCard(context, conv, admin);
      },
    );
  }

  Widget _buildConversationCard(
    BuildContext context,
    ShiraziConversation conv,
    AdminProvider admin,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x334D4635)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_pin, size: 16, color: ShiraziColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    conv.ownerEmail ?? conv.ownerUid,
                    style: ShiraziTypography.labelSm(
                      color: ShiraziColors.secondaryFixedDim,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ShiraziColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  conv.madhhab,
                  style: ShiraziTypography.labelSm(color: ShiraziColors.primary).copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            conv.title,
            style: ShiraziTypography.headlineSm(color: ShiraziColors.onSurface).copyWith(fontSize: 14),
          ),
          if (conv.lastMessagePreview.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              conv.lastMessagePreview,
              style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant).copyWith(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${conv.messageCount} messages • ${conv.updatedAt.toString().substring(0, 16)}',
                style: ShiraziTypography.labelSm(color: ShiraziColors.outline).copyWith(fontSize: 10),
              ),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.visibility, size: 14, color: ShiraziColors.primary),
                    label: const Text('Inspect', style: TextStyle(color: ShiraziColors.primary, fontSize: 12)),
                    onPressed: () {
                      admin.inspectConversation(conv);
                      _showInspectionModal(context, conv, admin);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: ShiraziColors.error),
                    tooltip: 'Moderate / Delete',
                    onPressed: () => _confirmDelete(context, conv, admin),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInspectionModal(
    BuildContext context,
    ShiraziConversation conv,
    AdminProvider admin,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ShiraziColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<AdminProvider>(
          builder: (context, adm, _) {
            final msgs = adm.inspectedMessages;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ShiraziColors.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'THREAD INSPECTOR: ${conv.title}',
                                  style: ShiraziTypography.headlineSm(color: ShiraziColors.onSurface).copyWith(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Owner: ${conv.ownerEmail ?? conv.ownerUid}',
                                  style: ShiraziTypography.labelSm(color: ShiraziColors.secondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              adm.clearInspection();
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                      const Divider(color: Color(0x334D4635)),

                      // Messages List
                      Expanded(
                        child: msgs.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: msgs.length,
                                itemBuilder: (c, i) {
                                  final m = msgs[i];
                                  final isUser = m.isUser;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? ShiraziColors.surfaceContainerHigh
                                          : ShiraziColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isUser
                                            ? ShiraziColors.primary.withValues(alpha: 0.3)
                                            : const Color(0x334D4635),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              isUser ? 'USER QUESTION' : 'SHIRAZI RESPONSE',
                                              style: ShiraziTypography.labelSm(
                                                color: isUser ? ShiraziColors.primary : ShiraziColors.secondary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              m.timestamp.toString().substring(11, 19),
                                              style: ShiraziTypography.labelSm(color: ShiraziColors.outline).copyWith(fontSize: 10),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        SelectableText(
                                          m.content,
                                          style: ShiraziTypography.bodySm(color: ShiraziColors.onSurface),
                                        ),
                                        if (m.citations.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 4,
                                            children: m.citations.map((cit) => Chip(
                                              label: Text(cit, style: const TextStyle(fontSize: 10)),
                                              backgroundColor: ShiraziColors.surfaceContainerLowest,
                                              visualDensity: VisualDensity.compact,
                                            )).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    ShiraziConversation conv,
    AdminProvider admin,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShiraziColors.surfaceContainerLow,
        title: const Text('Moderate / Delete Conversation?'),
        content: Text('Are you sure you want to delete "${conv.title}" from user ${conv.ownerEmail ?? conv.ownerUid}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ShiraziColors.error),
            onPressed: () {
              admin.moderateDeleteConversation(conv.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildServerFatwasView(BuildContext context, AdminProvider admin) {
    final fatwas = admin.auditInquiries;
    if (fatwas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No server fatwas loaded.',
            style: ShiraziTypography.bodySm(color: ShiraziColors.outline),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fatwas.length,
      itemBuilder: (context, idx) {
        final f = fatwas[idx];
        return Card(
          color: ShiraziColors.surfaceContainerLow,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(f.questionArabic, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${f.dossierRef} • ${f.madhhab}'),
            trailing: TextButton(
              onPressed: () {
                context.read<ResearchProvider>().setActiveInquiry(f);
                Navigator.pop(context);
              },
              child: const Text('Load into Desk'),
            ),
          ),
        );
      },
    );
  }
}
