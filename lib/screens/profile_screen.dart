import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/localization/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/app_update.dart';
import '../widgets/shirazi_emblem.dart';
import 'settings_byok_screen.dart';
import 'sign_in_screen.dart';
import 'admin_audit_log_screen.dart';
import 'welcome_screen.dart';

/// Real scholar profile: view identity, scholarship, research activity and
/// edit name / madhhab / rank. Persists through Firebase Auth + Firestore via
/// [FirebaseAuthService.updateScholarProfile]; guests get an honest guest card.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _madhhabs = ['Hanafi', 'Maliki', "Shafi'i", 'Hanbali'];
  static const _ranks = [
    'Muhaqqiq',
    'Mufti',
    'Qadi',
    'Professor',
    'Researcher',
    'Student',
  ];

  bool _editing = false;
  bool _saving = false;
  String? _error;
  late TextEditingController _nameController;
  late String _selectedMadhhab;
  late String _selectedRank;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _nameController = TextEditingController(text: settings.scholarName);
    _selectedMadhhab = settings.scholarMadhhab;
    _selectedRank = settings.scholarRank;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final authService = context.read<FirebaseAuthService>();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = strings.enterNamePrompt);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await authService.updateScholarProfile(
      scholarName: name,
      madhhab: _selectedMadhhab,
      scholarlyRank: _selectedRank,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      settings.refreshProfile();
      setState(() => _editing = false);
      messenger.showSnackBar(
        SnackBar(content: Text(strings.profileSavedSuccess)),
      );
    } else {
      setState(() => _error =
          (result['message'] as String?) ?? strings.genericErrorLabel);
    }
  }

  String _madhhabLabel(String m, AppStrings strings) {
    switch (m) {
      case 'Maliki':
        return strings.lang == 'ur'
            ? 'مالکی'
            : strings.lang == 'ar'
                ? 'مالكي'
                : 'Maliki';
      case "Shafi'i":
        return strings.lang == 'ur'
            ? "شافعی"
            : strings.lang == 'ar'
                ? 'شافعي'
                : "Shafi'i";
      case 'Hanbali':
        return strings.lang == 'ur'
            ? 'حنبلی'
            : strings.lang == 'ar'
                ? 'حنبلي'
                : 'Hanbali';
      default:
        return strings.lang == 'ur'
            ? 'حنفی'
            : strings.lang == 'ar'
                ? 'حنفي'
                : 'Hanafi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = context.watch<SettingsProvider>();
    final firebaseUser = context.watch<FirebaseAuthService>().currentUser;
    final isGuest = firebaseUser == null || firebaseUser.isAnonymous;

    return Scaffold(
      backgroundColor: ShiraziColors.background,
      appBar: AppBar(
        backgroundColor: ShiraziColors.background,
        foregroundColor: ShiraziColors.onSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          strings.scholarProfileTitle,
          style: ShiraziTypography.dynamicHeadline(
            strings.lang,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: ShiraziColors.onSurface,
          ),
        ),
        actions: [
          if (!isGuest && !_editing)
            IconButton(
              tooltip: strings.editProfileAction,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () {
                setState(() {
                  _editing = true;
                  _error = null;
                  _nameController.text = settings.scholarName;
                  _selectedMadhhab = settings.scholarMadhhab;
                  _selectedRank = settings.scholarRank;
                });
              },
            ),
        ],
      ),
      body: Directionality(
        textDirection: strings.direction,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 640;
            final maxWidth = wide ? 560.0 : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 8 : 16,
                    vertical: 16,
                  ),
                  children: [
                    _buildIdentityHeader(context, settings, strings, isGuest),
                    const SizedBox(height: 16),
                    if (_editing)
                      _buildEditForm(context, strings)
                    else ...[
                      _buildAccountSection(context, settings, strings, isGuest),
                      const SizedBox(height: 14),
                      _buildScholarshipSection(context, settings, strings),
                      const SizedBox(height: 14),
                      _buildStatsSection(context, strings),
                      const SizedBox(height: 14),
                      _buildMoreSection(context, strings),
                      const SizedBox(height: 20),
                      if (!isGuest) _buildSignOutButton(context, strings),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Identity header ──────────────────────────────────────────────────
  Widget _buildIdentityHeader(
    BuildContext context,
    SettingsProvider settings,
    AppStrings strings,
    bool isGuest,
  ) {
    final name = isGuest ? strings.guestScholar : settings.scholarName;
    final initial = name.trim().isEmpty ? '؟' : name.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            ShiraziColors.primary.withValues(alpha: 0.16),
            ShiraziColors.secondary.withValues(alpha: 0.08),
            ShiraziColors.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: ShiraziColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [ShiraziColors.primary, ShiraziColors.secondaryFixedDim],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: ShiraziColors.primary.withValues(alpha: 0.4),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Center(
              child: isGuest
                  ? const ShiraziEmblem(size: 40)
                  : Text(
                      initial,
                      style: ShiraziTypography.dynamicHeadline(
                        strings.lang,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: ShiraziColors.onPrimary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: ShiraziTypography.dynamicHeadline(
                    strings.lang,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: ShiraziColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGuest
                        ? ShiraziColors.outline.withValues(alpha: 0.15)
                        : ShiraziColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isGuest ? strings.guestMode : settings.scholarRank,
                    style: ShiraziTypography.dynamicLabel(
                      strings.lang,
                      fontSize: 11,
                      color: ShiraziColors.primary,
                    ),
                  ),
                ),
                if (!isGuest && settings.scholarEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    settings.scholarEmail,
                    style: ShiraziTypography.dynamicBody(
                      strings.lang,
                      fontSize: 12,
                      color: ShiraziColors.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Account ──────────────────────────────────────────────────────────
  Widget _buildAccountSection(
    BuildContext context,
    SettingsProvider settings,
    AppStrings strings,
    bool isGuest,
  ) {
    return _SectionCard(
      title: strings.accountSectionTitle,
      icon: Icons.person_outline_rounded,
      children: [
        if (isGuest) ...[
          _InfoRow(
            label: strings.guestMode,
            value: strings.guestContinueHint,
            strings: strings,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(
                strings.signInAction,
                style: ShiraziTypography.dynamicLabel(
                  strings.lang,
                  fontSize: 13,
                  color: ShiraziColors.onPrimary,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: ShiraziColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ] else ...[
          _InfoRow(
              label: strings.nameFieldLabel,
              value: settings.scholarName,
              strings: strings),
          _InfoRow(
              label: strings.emailFieldLabel,
              value: settings.scholarEmail.isEmpty ? '—' : settings.scholarEmail,
              strings: strings),
          _InfoRow(
              label: strings.roleFieldLabel,
              value: settings.scholarRank,
              strings: strings),
        ],
      ],
    );
  }

  // ── Scholarship ──────────────────────────────────────────────────────
  Widget _buildScholarshipSection(
    BuildContext context,
    SettingsProvider settings,
    AppStrings strings,
  ) {
    return _SectionCard(
      title: strings.scholarshipSectionTitle,
      icon: Icons.school_outlined,
      children: [
        _InfoRow(
          label: strings.madhhabFieldLabel,
          value: _madhhabLabel(settings.scholarMadhhab, strings),
          strings: strings,
        ),
        _InfoRow(
          label: strings.scholarlyRankFieldLabel,
          value: settings.scholarRank,
          strings: strings,
        ),
      ],
    );
  }

  // ── Stats ────────────────────────────────────────────────────────────
  Widget _buildStatsSection(BuildContext context, AppStrings strings) {
    final settings = context.read<SettingsProvider>();
    final conversations =
        context.watch<ChatProvider>().conversations.length;
    final savedKeys = [
      settings.geminiKey,
      settings.groqKey,
      settings.openRouterKey,
    ].where((k) => k.trim().isNotEmpty).length;
    final langLabel = settings.language == 'ur'
        ? 'اردو'
        : settings.language == 'ar'
            ? 'العربية'
            : 'English';
    return _SectionCard(
      title: strings.researchActivityTitle,
      icon: Icons.analytics_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.forum_outlined,
                value: '$conversations',
                label: strings.conversationsStatLabel,
                strings: strings,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.key_outlined,
                value: '$savedKeys',
                label: strings.personalKeysStatLabel,
                strings: strings,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.language_outlined,
                value: langLabel,
                label: strings.languageStatLabel,
                strings: strings,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SettingsByokScreen()),
              );
            },
            icon: const Icon(Icons.vpn_key_outlined, size: 17),
            label: Text(
              strings.manageApiKeysAction,
              style: ShiraziTypography.dynamicLabel(
                strings.lang,
                fontSize: 12.5,
                color: ShiraziColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ShiraziColors.primary,
              side: BorderSide(
                  color: ShiraziColors.primary.withValues(alpha: 0.45)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreSection(BuildContext context, AppStrings strings) {
    return _SectionCard(
      title: strings.moreSectionTitle,
      icon: Icons.apps_rounded,
      children: [
        _LinkRow(
          icon: Icons.system_update_outlined,
          label: strings.updateCheckLabel,
          strings: strings,
          onTap: () => manualUpdateCheck(context),
        ),
        _LinkRow(
          icon: Icons.admin_panel_settings_outlined,
          label: strings.adminOversightLabel,
          strings: strings,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminAuditLogScreen()),
            );
          },
        ),
        _LinkRow(
          icon: Icons.menu_book_outlined,
          label: strings.manifestoOverviewLabel,
          strings: strings,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const WelcomeScreen(isStandalone: true)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context, AppStrings strings) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final authService = context.read<FirebaseAuthService>();
          final messenger = ScaffoldMessenger.of(context);
          await authService.signOut();
          if (!context.mounted) return;
          context.read<SettingsProvider>().refreshProfile();
          messenger.showSnackBar(
            SnackBar(content: Text(strings.signedOutSuccess)),
          );
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(
          strings.signOutAction,
          style: ShiraziTypography.dynamicLabel(
            strings.lang,
            fontSize: 13,
            color: ShiraziColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: ShiraziColors.error,
          side: BorderSide(color: ShiraziColors.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ── Edit form ──────────────────────────────────────────────────────
  Widget _buildEditForm(
    BuildContext context,
    AppStrings strings,
  ) {
    return _SectionCard(
      title: strings.editProfileAction,
      icon: Icons.edit_outlined,
      children: [
        TextField(
          controller: _nameController,
          textDirection: strings.direction,
          style: ShiraziTypography.dynamicBody(
            strings.lang,
            color: ShiraziColors.onSurface,
          ),
          decoration: InputDecoration(
            labelText: strings.fullNameFieldLabel,
            labelStyle: ShiraziTypography.dynamicLabel(
              strings.lang,
              color: ShiraziColors.outline,
            ),
            filled: true,
            fillColor: ShiraziColors.surfaceContainerHighest
                .withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Dropdown(
          label: strings.madhhabFieldLabel,
          value: _selectedMadhhab,
          display: _madhhabLabel(_selectedMadhhab, strings),
          items: _madhhabs,
          displayOf: (m) => _madhhabLabel(m, strings),
          strings: strings,
          onChanged: (v) {
            if (v != null) setState(() => _selectedMadhhab = v);
          },
        ),
        const SizedBox(height: 12),
        _Dropdown(
          label: strings.scholarlyRankFieldLabel,
          value: _selectedRank,
          display: _selectedRank,
          items: _ranks,
          displayOf: (r) => r,
          strings: strings,
          onChanged: (v) {
            if (v != null) setState(() => _selectedRank = v);
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: ShiraziTypography.dynamicLabel(
              strings.lang,
              color: ShiraziColors.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          _editing = false;
                          _error = null;
                        }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  strings.cancelAction,
                  style: ShiraziTypography.dynamicLabel(
                    strings.lang,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () => _saveProfile(
                          context,
                          context.read<SettingsProvider>(),
                        ),
                style: FilledButton.styleFrom(
                  backgroundColor: ShiraziColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        strings.saveChangesAction,
                        style: ShiraziTypography.dynamicLabel(
                          strings.lang,
                          fontSize: 13,
                          color: ShiraziColors.onPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Building blocks ──────────────────────────────────────────────────

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppStrings strings;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ShiraziColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: ShiraziTypography.dynamicBody(
                  strings.lang,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: ShiraziColors.onSurface,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: ShiraziColors.outline),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ShiraziColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: ShiraziColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: ShiraziTypography.dynamicHeadline(
                  s.lang,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ShiraziColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AppStrings strings;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: ShiraziTypography.dynamicLabel(
                strings.lang,
                fontSize: 11.5,
                color: ShiraziColors.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: ShiraziTypography.dynamicBody(
                strings.lang,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: ShiraziColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final AppStrings strings;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: ShiraziColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: ShiraziTypography.dynamicHeadline(
              strings.lang,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ShiraziColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: ShiraziTypography.dynamicLabel(
              strings.lang,
              fontSize: 10,
              color: ShiraziColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final String display;
  final List<String> items;
  final String Function(String) displayOf;
  final AppStrings strings;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.display,
    required this.items,
    required this.displayOf,
    required this.strings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items
          .map(
            (m) => DropdownMenuItem(
              value: m,
              child: Text(
                displayOf(m),
                style: ShiraziTypography.dynamicBody(
                  strings.lang,
                  color: ShiraziColors.onSurface,
                ),
              ),
            ),
          )
          .toList(),
      style: ShiraziTypography.dynamicBody(
        strings.lang,
        color: ShiraziColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ShiraziTypography.dynamicLabel(
          strings.lang,
          color: ShiraziColors.outline,
        ),
        filled: true,
        fillColor:
            ShiraziColors.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: ShiraziColors.surfaceContainerHigh,
    );
  }
}
