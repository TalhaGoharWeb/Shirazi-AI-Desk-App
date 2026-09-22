import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../widgets/shirazi_emblem.dart';
import '../services/firebase_auth_service.dart';
import 'main_shell.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'د. أحمد فاروق (Dr. Ahmad Farooq)');
  final TextEditingController _emailController = TextEditingController(text: 'a.farooq@al-azhar.edu');
  final TextEditingController _passphraseController = TextEditingController(text: 'ShiraziPass2026!');
  final TextEditingController _confirmPassphraseController = TextEditingController(text: 'ShiraziPass2026!');

  String _selectedMadhhab = 'Hanafi';
  String _selectedRank = 'mufti';
  bool _obscurePassphrase = true;
  bool _honorCodeAccepted = true;
  bool _localVaultEnabled = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passphraseController.dispose();
    _confirmPassphraseController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<FirebaseAuthService>(context, listen: false);

    final result = await authService.registerScholar(
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : 'a.farooq@al-azhar.edu',
      password: _passphraseController.text.isNotEmpty ? _passphraseController.text : 'ShiraziPass2026!',
      scholarName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'د. أحمد فاروق',
      madhhab: _selectedMadhhab,
      scholarlyRank: _getRankTitle(_selectedRank),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ShiraziColors.surfaceContainerHigh,
            content: Text(
              result['message'] ?? 'Registration complete.',
              style: ShiraziTypography.bodySm(color: ShiraziColors.primary),
            ),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ShiraziColors.error.withValues(alpha: 0.9),
            content: Text(
              result['message'] ?? 'Authentication failed.',
              style: ShiraziTypography.bodySm(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  String _getRankTitle(String rankKey) {
    switch (rankKey) {
      case 'mufti':
        return 'Mufti / Darul Ifta';
      case 'professor':
        return 'Law Professor (أستاذ شريعة وقانون)';
      case 'researcher':
        return 'Hadith Researcher (باحث ومحقق حديثي)';
      case 'seeker':
      default:
        return 'Graduate Seeker (طالب علم متقدم)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShiraziColors.surface,
      appBar: AppBar(
        backgroundColor: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.85),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ShiraziColors.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const ShiraziEmblem(size: 24, strokeWidth: 1.5),
            const SizedBox(width: 8),
            Text(
              'Shirazi',
              style: ShiraziTypography.headlineSm(
                color: ShiraziColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'REGISTRATION',
                style: ShiraziTypography.labelSm(
                  color: ShiraziColors.outline,
                  fontWeight: FontWeight.w600,
                ).copyWith(letterSpacing: 1.0),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ShiraziSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: ShiraziSpacing.spaceMd),

              // Small Center Emblem
              const Center(
                child: ShiraziEmblem(size: 48, strokeWidth: 1.8),
              ),
              const SizedBox(height: 10),

              // Step Indicator Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ShiraziColors.surfaceContainerHigh,
                  borderRadius: ShiraziRadius.roundedFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: ShiraziColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'STEP 1 OF 2 • المرحلة الأولى: بيانات التوثيق',
                      style: ShiraziTypography.labelSm(
                        color: ShiraziColors.secondaryFixed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: ShiraziSpacing.spaceMd),

              Text(
                'Create Scholarly Account',
                style: ShiraziTypography.headlineMd(
                  color: ShiraziColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'منصة البحث والتحقيق الفقهي المعاصر',
                  style: ShiraziTypography.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ShiraziColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Digital manuscript repository and AI-assisted comparative jurisprudence sanctuary.',
                textAlign: TextAlign.center,
                style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
              ),

              const SizedBox(height: ShiraziSpacing.spaceLg),

              // 1. Full Name
              _buildInputLabel('Academic Title & Full Name', 'الاسم الكامل واللقب العلمي'),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.badge_outlined, color: ShiraziColors.outline, size: 20),
                  suffixIcon: const Icon(Icons.check_circle, color: ShiraziColors.secondary, size: 18),
                  filled: true,
                  fillColor: ShiraziColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: const BorderSide(color: ShiraziColors.primary),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2. Scholar Email
              _buildInputLabel('Institutional or Scholar Email', 'البريد الأكاديمي أو الشخصي'),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.alternate_email, color: ShiraziColors.outline, size: 20),
                  filled: true,
                  fillColor: ShiraziColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: const BorderSide(color: ShiraziColors.primary),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 3. Primary School of Jurisprudence
              _buildInputLabel('Primary School of Jurisprudence', 'المذهب الفقهي المعتمد', icon: Icons.hub_outlined),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMadhhabTile('Hanafi', 'حَنفي'),
                  const SizedBox(width: 8),
                  _buildMadhhabTile('Shafi\'i', 'شافعي'),
                  const SizedBox(width: 8),
                  _buildMadhhabTile('Maliki', 'مالكي'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMadhhabTile('Hanbali', 'حنبلي'),
                  const SizedBox(width: 8),
                  _buildMadhhabTile('Comparative', 'فقه مقارن (Comparative)'),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Scholarly Rank & Affiliation
              _buildInputLabel('Scholarly Rank & Affiliation', 'الصفة العلمية', icon: Icons.workspace_premium_outlined),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildRankTile('mufti', 'Mufti / Darul Ifta', 'مفتي / دور الإفتاء'),
                  const SizedBox(width: 8),
                  _buildRankTile('professor', 'Law Professor', 'أستاذ شريعة وقانون'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildRankTile('researcher', 'Hadith Researcher', 'باحث ومحقق حديثي'),
                  const SizedBox(width: 8),
                  _buildRankTile('seeker', 'Graduate Seeker', 'طالب علم متقدم'),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Master Passphrase
              _buildInputLabel('Master Passphrase', 'كلمة المرور الرئيسية', icon: Icons.key_outlined),
              const SizedBox(height: 6),
              TextField(
                controller: _passphraseController,
                obscureText: _obscurePassphrase,
                style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, color: ShiraziColors.outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassphrase ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: ShiraziColors.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassphrase = !_obscurePassphrase),
                  ),
                  filled: true,
                  fillColor: ShiraziColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: const BorderSide(color: ShiraziColors.primary),
                  ),
                ),
              ),

              // Cryptographic Strength Meter
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ShiraziColors.surfaceContainerLowest,
                  borderRadius: ShiraziRadius.roundedMd,
                  border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fingerprint, size: 14, color: ShiraziColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'Cryptographic Strength: Strong',
                              style: ShiraziTypography.labelSm(
                                color: ShiraziColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '256-bit Key Derived',
                          style: ShiraziTypography.labelSm(color: ShiraziColors.outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(4, (index) {
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                            decoration: BoxDecoration(
                              color: ShiraziColors.secondary,
                              borderRadius: ShiraziRadius.roundedFull,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 6. Confirm Passphrase
              _buildInputLabel('Confirm Passphrase', 'تأكيد كلمة المرور'),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPassphraseController,
                obscureText: _obscurePassphrase,
                style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_reset, color: ShiraziColors.outline, size: 20),
                  filled: true,
                  fillColor: ShiraziColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: ShiraziRadius.roundedLg,
                    borderSide: const BorderSide(color: ShiraziColors.primary),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Checkbox 1: Scholarly Honor Code
              InkWell(
                onTap: () => setState(() => _honorCodeAccepted = !_honorCodeAccepted),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _honorCodeAccepted,
                      activeColor: ShiraziColors.primary,
                      onChanged: (v) => setState(() => _honorCodeAccepted = v ?? false),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I uphold the Scholarly Honor Code & Research Integrity.',
                            style: ShiraziTypography.bodySm(
                              color: ShiraziColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              'أقر بالالتزام بميثاق الأمانة العلمية وضوابط النقل والتحقيق الفقهي',
                              style: ShiraziTypography.amiri(
                                fontSize: 13,
                                color: ShiraziColors.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Checkbox 2: Offline AES-256 Vault
              InkWell(
                onTap: () => setState(() => _localVaultEnabled = !_localVaultEnabled),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _localVaultEnabled,
                      activeColor: ShiraziColors.secondary,
                      onChanged: (v) => setState(() => _localVaultEnabled = v ?? false),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable offline AES-256 local vault for confidential manuscripts.',
                            style: ShiraziTypography.bodySm(
                              color: ShiraziColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              'تشفير محلي فوري للأبحاث والفتاوى الخاصة غير المنشورة',
                              style: ShiraziTypography.amiri(
                                fontSize: 13,
                                color: ShiraziColors.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: ShiraziSpacing.spaceLg),

              // Register CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShiraziColors.primary,
                    foregroundColor: ShiraziColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: ShiraziRadius.roundedLg),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(ShiraziColors.onPrimary),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Register & Initialize Codex',
                              style: ShiraziTypography.labelMd(
                                color: ShiraziColors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Trust Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 14, color: ShiraziColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    'Zero-Knowledge Hash',
                    style: ShiraziTypography.labelSm(color: ShiraziColors.outline),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.sync, size: 14, color: ShiraziColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Shamela & Isnad Sync',
                    style: ShiraziTypography.labelSm(color: ShiraziColors.outline),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Return to Sign In
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                      children: [
                        const TextSpan(text: 'Already registered in the jurisprudence assembly?\n'),
                        TextSpan(
                          text: 'Sign In to Shirazi Codex (تسجيل الدخول)',
                          style: ShiraziTypography.bodySm(
                            color: ShiraziColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: ShiraziSpacing.spaceLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String english, String arabic, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: ShiraziColors.primary),
              const SizedBox(width: 6),
            ],
            Text(
              english,
              style: ShiraziTypography.labelSm(
                color: ShiraziColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            arabic,
            style: ShiraziTypography.amiri(
              fontSize: 13,
              color: ShiraziColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMadhhabTile(String id, String labelArabic) {
    final isSelected = _selectedMadhhab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMadhhab = id),
        borderRadius: ShiraziRadius.roundedMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? ShiraziColors.surfaceContainerHigh : ShiraziColors.surfaceContainerLow,
            borderRadius: ShiraziRadius.roundedMd,
            border: Border.all(
              color: isSelected ? ShiraziColors.primary : ShiraziColors.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                id,
                style: ShiraziTypography.labelSm(
                  color: isSelected ? ShiraziColors.primary : ShiraziColors.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 2),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  labelArabic,
                  style: ShiraziTypography.amiri(
                    fontSize: 12,
                    color: isSelected ? ShiraziColors.primary : ShiraziColors.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankTile(String rankKey, String english, String arabic) {
    final isSelected = _selectedRank == rankKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRank = rankKey),
        borderRadius: ShiraziRadius.roundedMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? ShiraziColors.surfaceContainerHigh : ShiraziColors.surfaceContainerLow,
            borderRadius: ShiraziRadius.roundedMd,
            border: Border.all(
              color: isSelected ? ShiraziColors.secondary : ShiraziColors.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? ShiraziColors.secondary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? ShiraziColors.secondary : ShiraziColors.outline,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      english,
                      overflow: TextOverflow.ellipsis,
                      style: ShiraziTypography.labelSm(
                        color: isSelected ? ShiraziColors.onSurface : ShiraziColors.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        arabic,
                        overflow: TextOverflow.ellipsis,
                        style: ShiraziTypography.amiri(
                          fontSize: 11,
                          color: isSelected ? ShiraziColors.secondary : ShiraziColors.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
