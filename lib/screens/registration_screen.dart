import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../core/localization/app_strings.dart';
import '../widgets/shirazi_emblem.dart';
import '../services/firebase_auth_service.dart';
import 'main_shell.dart';

/// Account registration screen.
///
/// Creates a Firebase email/password account and stores the scholar profile
/// (name, madhhab, rank) in Firestore. Empty fields, real validation, and a
/// genuinely computed password-strength indicator — no demo data, no fake
/// crypto theatre.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String _selectedMadhhab = 'Hanafi';
  String _selectedRank = 'seeker';
  bool _obscurePassword = true;
  bool _honorCodeAccepted = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  static const _madhhabs = [
    ('Hanafi', 'حنفي'),
    ("Shafi'i", 'شافعي'),
    ('Maliki', 'مالكي'),
    ('Hanbali', 'حنبلي'),
    ('Comparative', 'مقارن'),
  ];

  static const _ranks = [
    ('seeker', 'Student of Knowledge', 'طالب علم'),
    ('researcher', 'Researcher', 'باحث'),
    ('professor', 'Teacher / Professor', 'مدرس / أستاذ'),
    ('mufti', 'Mufti / Scholar', 'مفتي / عالم'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _rankTitle(String key) {
    switch (key) {
      case 'mufti':
        return 'Mufti / Scholar';
      case 'professor':
        return 'Teacher / Professor';
      case 'researcher':
        return 'Researcher';
      case 'seeker':
      default:
        return 'Student of Knowledge';
    }
  }

  /// Simple, honest strength score 0..4 based on length and character variety.
  int _passwordStrength(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password) && RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score.clamp(0, 4);
  }

  String _strengthLabel(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
      default:
        return 'Strong';
    }
  }

  Color _strengthColor(int score) {
    switch (score) {
      case 0:
      case 1:
        return ShiraziColors.error;
      case 2:
        return const Color(0xFFD97706); // amber
      case 3:
        return ShiraziColors.secondary;
      case 4:
      default:
        return ShiraziColors.secondary;
    }
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_honorCodeAccepted) {
      setState(() => _errorMessage =
          'Please accept the Scholarly Honor Code to create your account.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<FirebaseAuthService>(context, listen: false);
    final result = await authService.registerScholar(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      scholarName: _nameController.text.trim(),
      madhhab: _selectedMadhhab,
      scholarlyRank: _rankTitle(_selectedRank),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = (result['message'] as String?) ?? 'Registration failed. Please try again.');
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<FirebaseAuthService>(context, listen: false);
    final result = await authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } else if (result['code'] == 'cancelled') {
      setState(() => _errorMessage = AppStrings.of(context).googleSignInCancelled);
    } else {
      setState(() => _errorMessage =
          (result['message'] as String?) ?? 'Google sign-up failed. Please try again.');
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
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: ShiraziSpacing.spaceLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    const Center(child: ShiraziEmblem(size: 52, strokeWidth: 1.8)),
                    const SizedBox(height: 12),

                    Text(
                      'Create your account',
                      style: ShiraziTypography.headlineMd(
                        color: ShiraziColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        'انضم إلى مجلس العلم',
                        style: ShiraziTypography.amiri(
                          fontSize: 17,
                          color: ShiraziColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'One account for your research desk on every device — your madhhab shapes every answer.',
                      textAlign: TextAlign.center,
                      style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceLg),

                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: ShiraziColors.error.withValues(alpha: 0.12),
                          borderRadius: ShiraziRadius.roundedMd,
                          border: Border.all(color: ShiraziColors.error.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 18, color: ShiraziColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: ShiraziTypography.bodySm(color: ShiraziColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: ShiraziSpacing.spaceMd),
                    ],

                    // Name
                    _buildLabel('FULL NAME'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Please enter your name.' : null,
                      textCapitalization: TextCapitalization.words,
                      style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                      decoration: _inputDecoration(
                        prefixIcon: Icons.person_outline,
                        hint: 'Your name',
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Email
                    _buildLabel('EMAIL ADDRESS'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Please enter your email address.';
                        if (!t.contains('@') || !t.contains('.')) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                      decoration: _inputDecoration(
                        prefixIcon: Icons.alternate_email,
                        hint: 'you@example.com',
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Password + live strength
                    _buildLabel('PASSWORD'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'Please choose a password.';
                        if (v!.length < 6) return 'Password must be at least 6 characters.';
                        return null;
                      },
                      obscureText: _obscurePassword,
                      onChanged: (_) => setState(() {}),
                      style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                      decoration: _inputDecoration(
                        prefixIcon: Icons.lock_outline,
                        hint: 'At least 6 characters',
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: ShiraziColors.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStrengthMeter(_passwordStrength(_passwordController.text)),

                    const SizedBox(height: 14),

                    // Confirm
                    _buildLabel('CONFIRM PASSWORD'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmController,
                      validator: (v) => v != _passwordController.text
                          ? 'Passwords do not match.'
                          : null,
                      obscureText: _obscurePassword,
                      style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                      decoration: _inputDecoration(
                        prefixIcon: Icons.lock_reset,
                        hint: 'Repeat your password',
                      ),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceLg),

                    // Madhhab selector (drives answer framing)
                    _buildSectionHeader(
                      'YOUR MADHHAB',
                      'Answers are framed from your school first.',
                      Icons.hub_outlined,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _madhhabs
                          .map((m) => _buildChoiceChip(
                                label: m.$1,
                                arabic: m.$2,
                                selected: _selectedMadhhab == m.$1,
                                onTap: () => setState(() => _selectedMadhhab = m.$1),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    // Rank selector
                    _buildSectionHeader(
                      'I AM A…',
                      'Helps us tailor explanations to your level.',
                      Icons.workspace_premium_outlined,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _ranks
                          .map((r) => _buildChoiceChip(
                                label: r.$2,
                                arabic: r.$3,
                                selected: _selectedRank == r.$1,
                                onTap: () => setState(() => _selectedRank = r.$1),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    // Honor code — required
                    InkWell(
                      onTap: () => setState(() => _honorCodeAccepted = !_honorCodeAccepted),
                      borderRadius: ShiraziRadius.roundedMd,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
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
                                    'I will seek knowledge with honesty and verify before I share.',
                                    style: ShiraziTypography.bodySm(
                                      color: ShiraziColors.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      'أطلب العلم بأمانة، وأتحقق قبل أن أنشر',
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
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    // Register CTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShiraziColors.primary,
                          foregroundColor: ShiraziColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: ShiraziRadius.roundedLg,
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    ShiraziColors.onPrimary,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Create Account',
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

                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    // Google sign-up
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isGoogleLoading ? null : _handleGoogleSignUp,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ShiraziColors.onSurface,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(
                            color: ShiraziColors.outlineVariant.withValues(alpha: 0.6),
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: ShiraziRadius.roundedLg,
                          ),
                        ),
                        child: _isGoogleLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const _GoogleMark(),
                                  const SizedBox(width: 10),
                                  Text(
                                    AppStrings.of(context).signUpWithGoogle,
                                    style: ShiraziTypography.labelMd(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF3C4043),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RichText(
                          text: TextSpan(
                            style: ShiraziTypography.bodySm(
                              color: ShiraziColors.onSurfaceVariant,
                            ),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign in',
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
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: ShiraziTypography.labelSm(
          color: ShiraziColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ShiraziColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ShiraziTypography.labelSm(
                  color: ShiraziColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: ShiraziTypography.bodySm(color: ShiraziColors.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String arabic,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: ShiraziRadius.roundedLg,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? ShiraziColors.primary.withValues(alpha: 0.16)
              : ShiraziColors.surfaceContainerLow,
          borderRadius: ShiraziRadius.roundedLg,
          border: Border.all(
            color: selected
                ? ShiraziColors.primary
                : ShiraziColors.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle, size: 16, color: ShiraziColors.primary),
              ),
            Text(
              label,
              style: ShiraziTypography.labelMd(
                color: selected ? ShiraziColors.primary : ShiraziColors.onSurface,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              arabic,
              style: ShiraziTypography.amiri(
                fontSize: 14,
                color: selected ? ShiraziColors.primary : ShiraziColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthMeter(int score) {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i < score
                        ? _strengthColor(score)
                        : ShiraziColors.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: ShiraziRadius.roundedFull,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _strengthLabel(score),
          style: ShiraziTypography.labelSm(
            color: _strengthColor(score),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required IconData prefixIcon, required String hint}) {
    final border = OutlineInputBorder(
      borderRadius: ShiraziRadius.roundedLg,
      borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
    );
    return InputDecoration(
      prefixIcon: Icon(prefixIcon, color: ShiraziColors.outline, size: 20),
      hintText: hint,
      hintStyle: ShiraziTypography.bodySm(color: ShiraziColors.outline),
      filled: true,
      fillColor: ShiraziColors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: ShiraziRadius.roundedLg,
        borderSide: BorderSide(color: ShiraziColors.primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: ShiraziRadius.roundedLg,
        borderSide: BorderSide(color: ShiraziColors.error),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: ShiraziRadius.roundedLg,
        borderSide: BorderSide(color: ShiraziColors.error, width: 1.5),
      ),
    );
  }
}

/// Compact Google "G" brand mark (drawn, no asset needed).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4),
          height: 1.0,
        ),
      ),
    );
  }
}
