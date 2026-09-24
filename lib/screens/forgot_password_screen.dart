import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../widgets/shirazi_emblem.dart';
import '../services/firebase_auth_service.dart';

/// Password reset screen.
///
/// Sends a real Firebase password-reset email. No fake OTP step, no
/// decorative recovery protocols — the link in the email does the work.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<FirebaseAuthService>(context, listen: false);
    final result = await authService.sendPasswordReset(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _emailSent = true);
    } else {
      setState(() => _errorMessage =
          (result['message'] as String?) ?? 'Could not send the reset email. Please try again.');
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
              constraints: const BoxConstraints(maxWidth: 440),
              child: _emailSent ? _buildSuccessState() : _buildRequestForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: ShiraziSpacing.spaceLg),

          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: ShiraziColors.primary.withValues(alpha: 0.12),
              borderRadius: ShiraziRadius.roundedXl,
              border: Border.all(color: ShiraziColors.primary.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.lock_reset, size: 36, color: ShiraziColors.primary),
          ),

          const SizedBox(height: ShiraziSpacing.spaceMd),

          Text(
            'Reset your password',
            style: ShiraziTypography.headlineMd(
              color: ShiraziColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'استعادة كلمة المرور',
              style: ShiraziTypography.amiri(fontSize: 17, color: ShiraziColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the email you registered with and we will send you a secure link to choose a new password.',
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

          Container(
            padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
            decoration: BoxDecoration(
              color: ShiraziColors.surfaceContainerLow.withValues(alpha: 0.9),
              borderRadius: ShiraziRadius.roundedXl,
              border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.25)),
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
                  onFieldSubmitted: (_) => _handleSendReset(),
                  style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShiraziColors.primary,
                      foregroundColor: ShiraziColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
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
                              const Icon(Icons.send_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Send Reset Link',
                                style: ShiraziTypography.labelMd(
                                  color: ShiraziColors.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: ShiraziSpacing.spaceLg),

          InkWell(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 16, color: ShiraziColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Back to sign in',
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
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: ShiraziSpacing.spaceXl),

        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: ShiraziColors.secondary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: ShiraziColors.secondary.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.mark_email_read_outlined, size: 40, color: ShiraziColors.secondary),
        ),

        const SizedBox(height: ShiraziSpacing.spaceMd),

        Text(
          'Check your inbox',
          style: ShiraziTypography.headlineMd(
            color: ShiraziColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a password-reset link to\n${_emailController.text.trim()}.\nIt expires in 1 hour — check spam if you don\'t see it.',
          textAlign: TextAlign.center,
          style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurfaceVariant),
        ),

        const SizedBox(height: ShiraziSpacing.spaceLg),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ShiraziColors.primary,
              foregroundColor: ShiraziColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: ShiraziRadius.roundedLg,
              ),
            ),
            child: Text(
              'Back to Sign In',
              style: ShiraziTypography.labelMd(
                color: ShiraziColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() {
            _emailSent = false;
            _errorMessage = null;
          }),
          child: Text(
            'Use a different email',
            style: ShiraziTypography.bodySm(
              color: ShiraziColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: ShiraziSpacing.spaceXl),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    final border = OutlineInputBorder(
      borderRadius: ShiraziRadius.roundedLg,
      borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
    );
    return InputDecoration(
      prefixIcon: const Icon(Icons.alternate_email, color: ShiraziColors.outline, size: 20),
      hintText: 'you@example.com',
      hintStyle: ShiraziTypography.bodySm(color: ShiraziColors.outline),
      filled: true,
      fillColor: ShiraziColors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: ShiraziRadius.roundedLg,
        borderSide: const BorderSide(color: ShiraziColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: ShiraziRadius.roundedLg,
        borderSide: const BorderSide(color: ShiraziColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: ShiraziRadius.roundedLg,
        borderSide: const BorderSide(color: ShiraziColors.error, width: 1.5),
      ),
    );
  }
}
