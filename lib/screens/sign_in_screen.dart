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

/// Scholar sign-in screen.
///
/// Email + password via Firebase Auth, plus a real anonymous guest session.
/// No pre-filled demo credentials, no decorative role tabs, no fake SSO.
class SignInScreen extends StatefulWidget {
  final bool canSkip;

  const SignInScreen({super.key, this.canSkip = true});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGuestLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<FirebaseAuthService>(context, listen: false);
    final result = await authService.signInScholar(
      email: _emailController.text.trim(),
      password: _passwordController.text,
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
      setState(() => _errorMessage = (result['message'] as String?) ?? 'Sign in failed. Please try again.');
    }
  }

  Future<void> _handleGuestSignIn() async {
    setState(() {
      _isGuestLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<FirebaseAuthService>(context, listen: false);
    final result = await authService.signInAnonymously();

    if (!mounted) return;
    setState(() => _isGuestLoading = false);

    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = (result['message'] as String?) ?? 'Guest session failed. Please try again.');
    }
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your email address.';
    if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please enter your password.';
    if (value!.length < 6) return 'Password must be at least 6 characters.';
    return null;
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
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: ShiraziSpacing.spaceLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    // Hero emblem
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ShiraziColors.primary.withValues(alpha: 0.28),
                                blurRadius: 36,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: ShiraziColors.surfaceContainerHigh.withValues(alpha: 0.9),
                            borderRadius: ShiraziRadius.roundedXl,
                            border: Border.all(
                              color: ShiraziColors.primary.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                          ),
                          child: const Center(
                            child: ShiraziEmblem(size: 48, strokeWidth: 2.0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    Text(
                      'Welcome back',
                      style: ShiraziTypography.headlineMd(
                        color: ShiraziColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        'أهلاً بعودتك إلى مجلس العلم',
                        style: ShiraziTypography.amiri(
                          fontSize: 17,
                          color: ShiraziColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue your research, sync your library, and pick up where you left off.',
                      textAlign: TextAlign.center,
                      style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceLg),

                    // Error banner
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

                    // Credential card
                    Container(
                      padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
                      decoration: BoxDecoration(
                        color: ShiraziColors.surfaceContainerLow.withValues(alpha: 0.9),
                        borderRadius: ShiraziRadius.roundedXl,
                        border: Border.all(
                          color: ShiraziColors.outlineVariant.withValues(alpha: 0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMAIL ADDRESS',
                            style: ShiraziTypography.labelSm(
                              color: ShiraziColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                            decoration: _inputDecoration(
                              prefixIcon: Icons.alternate_email,
                              hint: 'you@example.com',
                            ),
                          ),

                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PASSWORD',
                                style: ShiraziTypography.labelSm(
                                  color: ShiraziColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    'Forgot password?',
                                    style: ShiraziTypography.labelSm(
                                      color: ShiraziColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            validator: _validatePassword,
                            obscureText: _obscurePassword,
                            onFieldSubmitted: (_) => _handleSignIn(),
                            style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                            decoration: _inputDecoration(
                              prefixIcon: Icons.lock_outline,
                              hint: '••••••••',
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

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignIn,
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
                                  : Text(
                                      'Sign In',
                                      style: ShiraziTypography.labelMd(
                                        color: ShiraziColors.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: ShiraziColors.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: ShiraziTypography.labelSm(color: ShiraziColors.outline),
                          ),
                        ),
                        const Expanded(child: Divider(color: ShiraziColors.outlineVariant)),
                      ],
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    // Guest entry
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isGuestLoading ? null : _handleGuestSignIn,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ShiraziColors.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: ShiraziColors.outlineVariant.withValues(alpha: 0.5),
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: ShiraziRadius.roundedLg,
                          ),
                        ),
                        child: _isGuestLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_outline, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Continue as Guest',
                                    style: ShiraziTypography.labelMd(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Explore freely — no account needed. Your chats stay on this device.',
                      textAlign: TextAlign.center,
                      style: ShiraziTypography.bodySm(color: ShiraziColors.outline),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceLg),

                    // Register link
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                        );
                      },
                      borderRadius: ShiraziRadius.roundedFull,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: RichText(
                          text: TextSpan(
                            style: ShiraziTypography.bodySm(
                              color: ShiraziColors.onSurfaceVariant,
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Create one',
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
        borderSide: const BorderSide(color: ShiraziColors.primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: ShiraziRadius.roundedLg,
        borderSide: const BorderSide(color: ShiraziColors.error),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: ShiraziRadius.roundedLg,
        borderSide: const BorderSide(color: ShiraziColors.error, width: 1.5),
      ),
    );
  }
}
