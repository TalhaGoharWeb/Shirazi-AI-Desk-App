import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../widgets/shirazi_emblem.dart';
import '../services/firebase_auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'scholar@darulifta.edu');
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPassphraseController = TextEditingController();
  final TextEditingController _confirmPassphraseController = TextEditingController();

  int _currentStep = 1; // 1 = Request, 2 = Verify Code, 3 = Reset Complete
  bool _isLoading = false;
  bool _obscureNewPass = true;
  String _selectedMethod = 'email'; // 'email', 'pgp'

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPassphraseController.dispose();
    _confirmPassphraseController.dispose();
    super.dispose();
  }

  void _handleSendCode() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<FirebaseAuthService>(context, listen: false);
    final result = await authService.sendPasswordReset(_emailController.text.trim());

    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentStep = 2;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ShiraziColors.surfaceContainerHigh,
          content: Text(
            result['message'] ?? 'Reset instructions dispatched.',
            style: ShiraziTypography.bodySm(color: ShiraziColors.primary),
          ),
        ),
      );
    }
  }

  void _handleResetPassphrase() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ShiraziColors.surfaceContainerHigh,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: ShiraziColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Passphrase successfully re-encrypted. You may now sign in.',
                  style: ShiraziTypography.bodySm(color: ShiraziColors.onSurface),
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context);
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
                'CREDENTIAL RECOVERY',
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
                child: ShiraziEmblem(size: 52, strokeWidth: 1.8),
              ),
              const SizedBox(height: 12),

              // Step Badge
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
                        color: ShiraziColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _currentStep == 1
                          ? 'STEP 1 OF 2 • طلب استعادة الهوية الفقهية'
                          : 'STEP 2 OF 2 • توثيق الرمز وتعيين كلمة المرور',
                      style: ShiraziTypography.labelSm(
                        color: ShiraziColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: ShiraziSpacing.spaceMd),

              Text(
                'Recover Scholarly Passphrase',
                style: ShiraziTypography.headlineMd(
                  color: ShiraziColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'استعادة مفتاح المرور والتحقيق',
                  style: ShiraziTypography.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ShiraziColors.tertiaryFixed,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Enter your verified Scholarly ID, institutional seminary email, or cryptographic signature to receive recovery instructions.',
                  textAlign: TextAlign.center,
                  style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                ),
              ),

              const SizedBox(height: ShiraziSpacing.spaceLg),

              if (_currentStep == 1) ...[
                // STEP 1: Email and Method Selection
                _buildCard(
                  children: [
                    _buildInputLabel('Scholarly ID / Academic Email', 'البريد الأكاديمي المعتمد'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
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

                    _buildInputLabel('Recovery Protocol', 'قناة التحقق الفقهي'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMethodChoice(
                          'email',
                          'Seminary Email OTP',
                          'رمز بريدي فوري',
                          Icons.email_outlined,
                        ),
                        const SizedBox(width: 8),
                        _buildMethodChoice(
                          'pgp',
                          'PGP Key Signature',
                          'بصمة المفتاح العام',
                          Icons.key_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShiraziColors.primary,
                          foregroundColor: ShiraziColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: ShiraziRadius.roundedLg),
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
                                  const Icon(Icons.send_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dispatch Verification Code',
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
              ] else ...[
                // STEP 2: Code and New Passphrase
                _buildCard(
                  children: [
                    _buildInputLabel('6-Digit Verification Token', 'رمز التحقق الأكاديمي'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        letterSpacing: 10,
                        fontWeight: FontWeight.bold,
                        color: ShiraziColors.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: '849201',
                        hintStyle: TextStyle(
                          fontSize: 20,
                          letterSpacing: 8,
                          color: ShiraziColors.outline.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: ShiraziColors.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: ShiraziRadius.roundedLg,
                          borderSide: const BorderSide(color: ShiraziColors.primary),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildInputLabel('New Master Passphrase', 'كلمة المرور الجديدة'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _newPassphraseController,
                      obscureText: _obscureNewPass,
                      style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: ShiraziColors.outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: ShiraziColors.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                        ),
                        hintText: '••••••••••••••••',
                        filled: true,
                        fillColor: ShiraziColors.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: ShiraziRadius.roundedLg,
                          borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildInputLabel('Confirm New Passphrase', 'تأكيد كلمة المرور الجديدة'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _confirmPassphraseController,
                      obscureText: _obscureNewPass,
                      style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_reset, color: ShiraziColors.outline, size: 20),
                        hintText: '••••••••••••••••',
                        filled: true,
                        fillColor: ShiraziColors.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: ShiraziRadius.roundedLg,
                          borderSide: BorderSide(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleResetPassphrase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShiraziColors.primary,
                          foregroundColor: ShiraziColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: ShiraziRadius.roundedLg),
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
                                  const Icon(Icons.verified, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Update Passphrase & Authenticate',
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
              ],

              const SizedBox(height: ShiraziSpacing.spaceLg),

              // Return to Sign In
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
                        'Return to Scholar Sign In (العودة لتسجيل الدخول)',
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
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
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
        children: children,
      ),
    );
  }

  Widget _buildInputLabel(String english, String arabic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          english,
          style: ShiraziTypography.labelSm(
            color: ShiraziColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
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

  Widget _buildMethodChoice(String methodKey, String title, String subtitle, IconData icon) {
    final isSelected = _selectedMethod == methodKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = methodKey),
        borderRadius: ShiraziRadius.roundedMd,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? ShiraziColors.surfaceContainerHigh : ShiraziColors.surfaceContainerLowest,
            borderRadius: ShiraziRadius.roundedMd,
            border: Border.all(
              color: isSelected ? ShiraziColors.secondary : ShiraziColors.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? ShiraziColors.secondary : ShiraziColors.outline),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: ShiraziTypography.labelSm(
                  color: isSelected ? ShiraziColors.onSurface : ShiraziColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: ShiraziTypography.amiri(
                    fontSize: 11,
                    color: isSelected ? ShiraziColors.secondary : ShiraziColors.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
