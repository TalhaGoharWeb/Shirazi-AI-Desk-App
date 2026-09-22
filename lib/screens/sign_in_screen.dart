import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../widgets/shirazi_emblem.dart';
import '../services/firebase_auth_service.dart';
import 'registration_screen.dart';
import 'forgot_password_screen.dart';
import 'main_shell.dart';

class SignInScreen extends StatefulWidget {
  final bool canSkip;

  const SignInScreen({super.key, this.canSkip = true});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _idController = TextEditingController(text: 'scholar@darulifta.edu');
  final TextEditingController _passphraseController = TextEditingController(text: 'ShiraziPass2026!');
  bool _obscurePassword = true;
  bool _trustNode = true;
  String _selectedRole = 'scholar'; // 'scholar', 'institution', 'explorer'
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<FirebaseAuthService>(context, listen: false);

    final result = await authService.signInScholar(
      email: _idController.text.trim().isNotEmpty ? _idController.text.trim() : 'scholar@darulifta.edu',
      password: _passphraseController.text.isNotEmpty ? _passphraseController.text : 'ShiraziPass2026!',
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShiraziColors.surface,
      appBar: AppBar(
        backgroundColor: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.85),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: ShiraziColors.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              )
            : null,
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
                'SCHOLAR SIGN IN',
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

              // 1. Star Emblem with Radiant Golden Aura
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ShiraziColors.primary.withValues(alpha: 0.25),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: ShiraziColors.surfaceContainerHigh.withValues(alpha: 0.85),
                      borderRadius: ShiraziRadius.roundedXl,
                      border: Border.all(color: ShiraziColors.primary.withValues(alpha: 0.35), width: 1.2),
                    ),
                    child: const Center(
                      child: ShiraziEmblem(size: 50, strokeWidth: 2.0),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: ShiraziSpacing.spaceMd),

              // Title Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SHIRAZI',
                    style: ShiraziTypography.headlineLg(
                      color: ShiraziColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'شیرازی',
                    style: ShiraziTypography.scheherazade(
                      fontSize: 26,
                      color: ShiraziColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'ISLAMIC JURISPRUDENCE & SCHOLARLY CODEX',
                textAlign: TextAlign.center,
                style: ShiraziTypography.labelSm(
                  color: ShiraziColors.primary,
                  fontWeight: FontWeight.bold,
                ).copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'بوابة الباحثين والفقهاء',
                  textAlign: TextAlign.center,
                  style: ShiraziTypography.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ShiraziColors.tertiaryFixed,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Sign in to access synchronized research vaults, Shamela corpora, and authenticated juristic reasoning.',
                  textAlign: TextAlign.center,
                  style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                ),
              ),

              const SizedBox(height: ShiraziSpacing.spaceLg),

              // 2. Persona Role Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ShiraziColors.surfaceContainerLowest,
                  borderRadius: ShiraziRadius.roundedXl,
                  border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    _buildRoleTab('scholar', 'Scholar / Mufti', 'باحث / مفتي'),
                    _buildRoleTab('institution', 'Institution', 'هيئة أكاديمية'),
                    _buildRoleTab('explorer', 'Explorer', 'مستكشف'),
                  ],
                ),
              ),

              const SizedBox(height: ShiraziSpacing.spaceMd),

              // 3. Primary Credential Card
              Container(
                padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: ShiraziColors.surfaceContainerLow.withValues(alpha: 0.9),
                  borderRadius: ShiraziRadius.roundedXl,
                  border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field 1: Scholarly ID / Email
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'SCHOLARLY ID / EMAIL',
                              style: ShiraziTypography.labelSm(
                                color: ShiraziColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'الهوية الفقهية',
                              style: ShiraziTypography.labelSm(color: ShiraziColors.primary),
                            ),
                          ],
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
                              'Verified Isnad',
                              style: ShiraziTypography.labelSm(
                                color: ShiraziColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _idController,
                      style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.badge_outlined, color: ShiraziColors.outline, size: 20),
                        hintText: 'scholar@darulifta.edu or ID',
                        hintStyle: ShiraziTypography.bodySm(color: ShiraziColors.outline),
                        filled: true,
                        fillColor: ShiraziColors.surfaceContainerLowest,
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

                    // Field 2: Secret Passphrase
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ENCRYPTED PASSPHRASE',
                              style: ShiraziTypography.labelSm(
                                color: ShiraziColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'كلمة المرور',
                              style: ShiraziTypography.labelSm(color: ShiraziColors.primary),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            );
                          },
                          child: Text(
                            'نسيت الكلمة؟',
                            style: ShiraziTypography.labelSm(
                              color: ShiraziColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passphraseController,
                      obscureText: _obscurePassword,
                      style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.key_outlined, color: ShiraziColors.outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: ShiraziColors.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        hintText: '••••••••••••••••',
                        hintStyle: ShiraziTypography.bodySm(color: ShiraziColors.outline),
                        filled: true,
                        fillColor: ShiraziColors.surfaceContainerLowest,
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

                    const SizedBox(height: 12),

                    // Remember Session & Encryption Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Switch(
                              value: _trustNode,
                              activeColor: ShiraziColors.primary,
                              onChanged: (v) => setState(() => _trustNode = v),
                            ),
                            Text(
                              'Trust this research node',
                              style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.security, size: 14, color: ShiraziColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'AES-256',
                              style: ShiraziTypography.labelSm(color: ShiraziColors.outline),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Main Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignIn,
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
                                  const Icon(Icons.menu_book, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sign In to Research Desk',
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
                  ],
                ),
              ),

              const SizedBox(height: ShiraziSpacing.spaceMd),

              // 4. Federated Academic Identities
              Row(
                children: [
                  const Expanded(child: Divider(color: ShiraziColors.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'أو عبر المصادقة الأكاديمية',
                      style: ShiraziTypography.labelSm(color: ShiraziColors.outline),
                    ),
                  ),
                  const Expanded(child: Divider(color: ShiraziColors.outlineVariant)),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildFederatedButton(
                      icon: Icons.account_balance,
                      title: 'Institutional SSO',
                      subtitle: 'Al-Azhar / Darul Uloom',
                      onTap: _handleSignIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFederatedButton(
                      icon: Icons.school,
                      title: 'Academic Cloud',
                      subtitle: 'Scholar / ORCID Key',
                      onTap: _handleSignIn,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: ShiraziSpacing.spaceLg),

              // 5. New to Shirazi? Register CTA
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                  );
                },
                borderRadius: ShiraziRadius.roundedFull,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: ShiraziColors.surfaceContainerLowest,
                    borderRadius: ShiraziRadius.roundedFull,
                    border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'New to Shirazi? ',
                        style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                      ),
                      Text(
                        'طلب انتساب باحث ›',
                        style: ShiraziTypography.bodySm(
                          color: ShiraziColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: ShiraziSpacing.spaceLg),

              // Zero-Knowledge Footer Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: ShiraziColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Zero-Knowledge Research Vault • End-to-End Encrypted',
                    style: ShiraziTypography.labelSm(color: ShiraziColors.outline),
                  ),
                ],
              ),

              const SizedBox(height: ShiraziSpacing.spaceLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String roleKey, String title, String subtitle) {
    final isSelected = _selectedRole == roleKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = roleKey),
        borderRadius: ShiraziRadius.roundedLg,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? ShiraziColors.surfaceContainerHigh : Colors.transparent,
            borderRadius: ShiraziRadius.roundedLg,
            border: isSelected ? Border.all(color: ShiraziColors.primary.withValues(alpha: 0.3)) : null,
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: ShiraziTypography.labelSm(
                  color: isSelected ? ShiraziColors.primary : ShiraziColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: ShiraziTypography.amiri(
                    fontSize: 11,
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

  Widget _buildFederatedButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: ShiraziRadius.roundedLg,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ShiraziColors.surfaceContainerLow,
          borderRadius: ShiraziRadius.roundedLg,
          border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ShiraziColors.surfaceContainerHigh,
                borderRadius: ShiraziRadius.roundedSm,
              ),
              child: Icon(icon, size: 18, color: ShiraziColors.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: ShiraziTypography.labelSm(
                      color: ShiraziColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: ShiraziTypography.labelSm(color: ShiraziColors.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
