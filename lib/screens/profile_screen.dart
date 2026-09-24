import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/localization/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/geometric_pattern.dart';
import 'settings_byok_screen.dart';
import 'sign_in_screen.dart';
import 'admin_audit_log_screen.dart';
import 'welcome_screen.dart';

/// Scholar profile: view state with account + scholarship details and
/// research stats, plus an edit state (name, madhhab, scholarly rank)
/// that persists through the real auth/Firestore path.
///
/// Guests see an honest guest card with a sign-in entry point — no
/// fabricated identity.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  String? _error;

  late TextEditingController _nameController;
  String _selectedMadhhab = 'Hanafi';
  String _selectedRank = 'Talib al-Ilm';

  static const _madhhabs = ['Hanafi', 'Maliki', "Shafi'i", 'Hanbali'];
  static const _ranks = [
    'Talib al-Ilm',
    'Muhaqqiq',
    'Mufti',
    'Qadi',
    'Professor',
    'Researcher',
  ];

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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final strings = AppStrings.of(context);
    final isGuest = !settings.isAuthenticated;

    return Scaffold(
      backgroundColor: ShiraziColors.background,
      appBar: AppBar(
        backgroundColor: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ShiraziColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          strings.lang == 'ur'
              ? 'اسکالر پروفائل'
              : strings.lang == 'ar'
                  ? 'الملف الشخصي'
                  : 'Scholar Profile',
          style: ShiraziTypography.dynamicHeadline(
            strings.lang,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ShiraziColors.onSurface,
          ),
        ),
        actions: [
          if (!isGuest && !_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: ShiraziColors.primary),
              tooltip: strings.lang == 'ur'
                  ? 'پروفائل میں ترمیم'
                  : strings.lang == 'ar'
                      ? 'تعديل'
                      : 'Edit profile',
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: GeometricPattern(opacity: 0.03)),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIdentityHeader(context, settings, strings, isGuest),
                const SizedBox(height: 20),
                if (isGuest)
                  _buildGuestCard(context, strings)
                else if (_editing)
                  _buildEditForm(context, strings)
                else ...[
                  _buildAccountSection(context, settings, strings),
                  const SizedBox(height: 14),
                  _buildScholarshipSection(context, settings, strings),
                  const SizedBox(height: 14),
                  _buildStatsSection(context, strings),
                  const SizedBox(height: 14),
                  _buildMoreSection(context, strings),
                  const SizedBox(height: 20),
                  _buildSignOutButton(context, strings),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Identity header ────────────────────────────────────────────────
  Widget _buildIdentityHeader(
    BuildContext context,
    SettingsProvider settings,
    AppStrings strings,
    bool isGuest,
  ) {
    final name = isGuest
        ? (strings.lang == 'ur'
            ? 'مہمان اسکالر'
            : strings.lang == 'ar'
                ? 'ضيف'
                : 'Guest Scholar')
        : settings.scholarName;

    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF3A2F10), Color(0xFF1E1C0E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: ShiraziColors.primary.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x44D4AF37), blurRadius: 20),
            ],
          ),
          child: Center(
            child: Text(
              _initial(name),
              style: ShiraziTypography.headlineMd(
                color: ShiraziColors.primary,
                fontWeight: FontWeight.bold,
              ).copyWith(fontSize: 36),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: ShiraziTypography.dynamicHeadline(
            strings.lang,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ShiraziColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: ShiraziColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ShiraziColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            isGuest
                ? (strings.lang == 'ur'
                    ? 'مہمان موڈ'
                    : strings.lang == 'ar'
                        ? 'وضع الضيف'
                        : 'Guest Mode')
                : settings.scholarRank,
            style: ShiraziTypography.dynamicLabel(
              strings.lang,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ShiraziColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Guest card ─────────────────────────────────────────────────────
  Widget _buildGuestCard(BuildContext context, AppStrings strings) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ShiraziColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_outline_rounded, size: 40, color: ShiraziColors.primary),
          const SizedBox(height: 12),
          Text(
            strings.lang == 'ur'
                ? 'آپ مہمان کے طور پر جاری ہیں'
                : strings.lang == 'ar'
                    ? 'أنت تتابع كضيف'
                    : 'You are continuing as a guest',
            style: ShiraziTypography.dynamicHeadline(
              strings.lang,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ShiraziColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            strings.lang == 'ur'
                ? 'سائن ان کریں تاکہ آپ کی پروفائل، مسلک اور تحقیقی ترجیحات تمام آلات پر محفوظ رہیں۔'
                : strings.lang == 'ar'
                    ? 'سجّل الدخول لحفظ ملفك ومذهبك وتفضيلاتك على جميع الأجهزة.'
                    : 'Sign in to keep your profile, madhhab and research preferences synced across devices.',
            style: ShiraziTypography.dynamicBody(
              strings.lang,
              fontSize: 13,
              color: ShiraziColors.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              );
            },
            icon: const Icon(Icons.login_rounded, size: 18),
            label: Text(
              strings.lang == 'ur' ? 'سائن ان' : strings.lang == 'ar' ? 'تسجيل الدخول' : 'Sign In',
              style: ShiraziTypography.dynamicLabel(
                strings.lang,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ShiraziColors.onPrimary,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ShiraziColors.primary,
              foregroundColor: ShiraziColors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  // ── View sections ──────────────────────────────────────────────────
  Widget _buildAccountSection(
    BuildContext context,
    SettingsProvider settings,
    AppStrings strings,
  ) {
    return _SectionCard(
      title: strings.lang == 'ur'
          ? 'اکاؤنٹ'
          : strings.lang == 'ar'
              ? 'الحساب'
              : 'Account',
      icon: Icons.person_rounded,
      children: [
        _InfoRow(
          label: strings.lang == 'ur' ? 'نام' : strings.lang == 'ar' ? 'الاسم' : 'Name',
          value: settings.scholarName,
        ),
        _InfoRow(
          label: strings.lang == 'ur' ? 'ای میل' : strings.lang == 'ar' ? 'البريد' : 'Email',
          value: settings.scholarEmail.isEmpty ? '—' : settings.scholarEmail,
        ),
        _InfoRow(
          label: strings.lang == 'ur' ? 'کردار' : strings.lang == 'ar' ? 'الدور' : 'Role',
          value: settings.scholarRole,
        ),
      ],
    );
  }

  Widget _buildScholarshipSection(
    BuildContext context,
    SettingsProvider settings,
    AppStrings strings,
  ) {
    return _SectionCard(
      title: strings.lang == 'ur'
          ? 'علمی شناخت'
          : strings.lang == 'ar'
              ? 'الهوية العلمية'
              : 'Scholarship',
      icon: Icons.school_rounded,
      children: [
        _InfoRow(
          label: strings.lang == 'ur'
              ? 'فقہی مسلک'
              : strings.lang == 'ar'
                  ? 'المذهب'
                  : 'Madhhab',
          value: settings.scholarMadhhab,
          valueAccent: true,
        ),
        _InfoRow(
          label: strings.lang == 'ur'
              ? 'علمی رتبہ'
              : strings.lang == 'ar'
                  ? 'الرتبة العلمية'
                  : 'Scholarly Rank',
          value: settings.scholarRank,
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, AppStrings strings) {
    final chat = context.watch<ChatProvider>();
    final settings = context.watch<SettingsProvider>();
    final keyCount = [
      settings.geminiKey,
      settings.groqKey,
      settings.openRouterKey,
    ].where((k) => k.isNotEmpty).length;

    return _SectionCard(
      title: strings.lang == 'ur'
          ? 'تحقیقی سرگرمی'
          : strings.lang == 'ar'
              ? 'النشاط البحثي'
              : 'Research Activity',
      icon: Icons.analytics_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: '${chat.conversations.length}',
                label: strings.lang == 'ur'
                    ? 'گفتگوئیں'
                    : strings.lang == 'ar'
                        ? 'المحادثات'
                        : 'Conversations',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value: '$keyCount',
                label: strings.lang == 'ur'
                    ? 'ذاتی API Keys'
                    : strings.lang == 'ar'
                        ? 'مفاتيح API'
                        : 'Personal Keys',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value: settings.language.toUpperCase(),
                label: strings.lang == 'ur'
                    ? 'زبان'
                    : strings.lang == 'ar'
                        ? 'اللغة'
                        : 'Language',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsByokScreen()),
              );
            },
            icon: const Icon(Icons.key_rounded, size: 16, color: ShiraziColors.secondary),
            label: Text(
              strings.lang == 'ur'
                  ? 'API Keys کا نظم کریں'
                  : strings.lang == 'ar'
                      ? 'إدارة مفاتيح API'
                      : 'Manage API Keys',
              style: ShiraziTypography.dynamicLabel(
                strings.lang,
                fontSize: 13,
                color: ShiraziColors.onSurface,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreSection(BuildContext context, AppStrings strings) {
    return _SectionCard(
      title: strings.lang == 'ur'
          ? 'مزید'
          : strings.lang == 'ar'
              ? 'المزيد'
              : 'More',
      icon: Icons.apps_rounded,
      children: [
        _LinkRow(
          icon: Icons.admin_panel_settings_outlined,
          label: strings.lang == 'ur'
              ? 'ایڈمن تحقیقی نگرانی'
              : strings.lang == 'ar'
                  ? 'لوحة الإشراف البحثي'
                  : 'Admin Research Oversight',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminAuditLogScreen()),
            );
          },
        ),
        _LinkRow(
          icon: Icons.menu_book_outlined,
          label: strings.lang == 'ur'
              ? 'علمی منشور و نظام کا تعارف'
              : strings.lang == 'ar'
                  ? 'البيان العلمي ونظرة على النظام'
                  : 'Scholarly Manifesto & Overview',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WelcomeScreen(isStandalone: true)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context, AppStrings strings) {
    return TextButton.icon(
      onPressed: () async {
        final authService = context.read<FirebaseAuthService>();
        await authService.signOut();
        if (context.mounted) {
          context.read<SettingsProvider>().refreshProfile();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                strings.lang == 'ur'
                    ? 'آپ کامیابی سے سائن آؤٹ ہو گئے'
                    : strings.lang == 'ar'
                        ? 'تم تسجيل الخروج بنجاح'
                        : 'Signed out successfully',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      icon: const Icon(Icons.logout_rounded, size: 18, color: ShiraziColors.error),
      label: Text(
        strings.lang == 'ur' ? 'سائن آؤٹ' : strings.lang == 'ar' ? 'تسجيل الخروج' : 'Sign Out',
        style: ShiraziTypography.dynamicLabel(
          strings.lang,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ShiraziColors.error,
        ),
      ),
    );
  }

  // ── Edit form ──────────────────────────────────────────────────────
  Widget _buildEditForm(
    BuildContext context,
    AppStrings strings,
  ) {
    final nameLabel = strings.lang == 'ur' ? 'پورا نام' : strings.lang == 'ar' ? 'الاسم الكامل' : 'Full Name';
    final madhhabLabel = strings.lang == 'ur' ? 'فقہی مسلک' : strings.lang == 'ar' ? 'المذهب الفقهي' : 'Jurisprudential School';
    final rankLabel = strings.lang == 'ur' ? 'علمی رتبہ' : strings.lang == 'ar' ? 'الرتبة العلمية' : 'Scholarly Rank';

    return _SectionCard(
      title: strings.lang == 'ur'
          ? 'پروفائل میں ترمیم'
          : strings.lang == 'ar'
              ? 'تعديل الملف'
              : 'Edit Profile',
      icon: Icons.edit_rounded,
      children: [
        Text(
          nameLabel,
          style: ShiraziTypography.dynamicLabel(
            strings.lang,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ShiraziColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: ShiraziColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ShiraziColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          madhhabLabel,
          style: ShiraziTypography.dynamicLabel(
            strings.lang,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ShiraziColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        _Dropdown(
          value: _selectedMadhhab,
          items: _madhhabs,
          onChanged: (v) => setState(() => _selectedMadhhab = v!),
        ),
        const SizedBox(height: 14),
        Text(
          rankLabel,
          style: ShiraziTypography.dynamicLabel(
            strings.lang,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ShiraziColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        _Dropdown(
          value: _selectedRank,
          items: _ranks,
          onChanged: (v) => setState(() => _selectedRank = v!),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: ShiraziTypography.labelMd(color: ShiraziColors.error),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(() => _editing = false),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  strings.lang == 'ur' ? 'منسوخ' : strings.lang == 'ar' ? 'إلغاء' : 'Cancel',
                  style: ShiraziTypography.dynamicLabel(
                    strings.lang,
                    fontSize: 14,
                    color: ShiraziColors.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                  foregroundColor: ShiraziColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        strings.lang == 'ur'
                            ? 'محفوظ کریں'
                            : strings.lang == 'ar'
                                ? 'حفظ'
                                : 'Save Changes',
                        style: ShiraziTypography.dynamicLabel(
                          strings.lang,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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

  Future<void> _saveProfile(BuildContext context, SettingsProvider settings) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final authService = context.read<FirebaseAuthService>();
    final result = await authService.updateScholarProfile(
      scholarName: _nameController.text,
      madhhab: _selectedMadhhab,
      scholarlyRank: _selectedRank,
    );

    if (!context.mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      settings.refreshProfile();
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result['message'] as String?) ?? 'Profile updated.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _error = (result['message'] as String?) ?? 'Update failed.');
    }
  }

  String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '؟';
    return String.fromCharCode(t.runes.first).toUpperCase();
  }
}

// ── Building blocks ──────────────────────────────────────────────────

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
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
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: ShiraziColors.outline),
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
    final strings = AppStrings.of(context);
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
                  strings.lang,
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
  final bool valueAccent;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: ShiraziTypography.dynamicLabel(
                strings.lang,
                fontSize: 12,
                color: ShiraziColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: ShiraziTypography.dynamicBody(
                strings.lang,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueAccent ? ShiraziColors.primary : ShiraziColors.onSurface,
              ),
              textDirection: strings.direction,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: ShiraziTypography.headlineSm(color: ShiraziColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ShiraziTypography.dynamicLabel(
              strings.lang,
              fontSize: 10,
              color: ShiraziColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ShiraziColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          dropdownColor: ShiraziColors.surfaceContainerHigh,
          style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
