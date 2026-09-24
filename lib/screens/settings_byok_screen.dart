import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../core/localization/app_strings.dart';
import '../providers/settings_provider.dart';
import 'admin_health_screen.dart';
import 'welcome_screen.dart';
import 'sign_in_screen.dart';

class SettingsByokScreen extends StatefulWidget {
  const SettingsByokScreen({super.key});

  @override
  State<SettingsByokScreen> createState() => _SettingsByokScreenState();
}

class _SettingsByokScreenState extends State<SettingsByokScreen> {
  late TextEditingController _keyController;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _keyController = TextEditingController(text: settings.currentApiKey);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    Widget body = Material(
      color: ShiraziColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: ShiraziSpacing.gutterMobile,
        ).copyWith(
          top: ShiraziSpacing.spaceSm,
          bottom: 30,
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Welcoming Header Card
          Container(
            padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ShiraziColors.surfaceContainerLow,
                  ShiraziColors.surfaceContainerHigh.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: ShiraziRadius.roundedXl,
              border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.3)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ShiraziColors.secondary.withOpacity(0.15),
                        borderRadius: ShiraziRadius.roundedFull,
                      ),
                      child: Row(
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
                            'Personal Key (BYOK)',
                            style: ShiraziTypography.labelSm(
                              color: ShiraziColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        'مفتاح الذكاء الاصطناعي الخاص',
                        style: ShiraziTypography.amiri(
                          fontSize: 13,
                          color: ShiraziColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Connect Your API Key',
                  style: ShiraziTypography.headlineMd(color: ShiraziColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provide your personal AI key as a fallback when the Shirazi Oracle\u2019s own inference capacity is exhausted.',
                  style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.lock, size: 16, color: ShiraziColors.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Stored in your device\u2019s secure storage (Android Keystore / iOS Keychain). Only ever sent to your Shirazi Oracle server over HTTPS, where it runs the full Shirazi research pipeline with it \u2014 never used for direct AI answers.',
                        style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: ShiraziSpacing.spaceMd),

          // 2. Automatic Fallback Priority
          Container(
            padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
            decoration: BoxDecoration(
              color: ShiraziColors.surfaceContainerLow,
              borderRadius: ShiraziRadius.roundedXl,
              border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.3)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alt_route, size: 18, color: ShiraziColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'AUTOMATIC FALLBACK PRIORITY',
                          style: ShiraziTypography.labelMd(
                            color: ShiraziColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        'أولوية الاستدعاء',
                        style: ShiraziTypography.amiri(
                          fontSize: 13,
                          color: ShiraziColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'When Shirazi Core server reaches quota or rate limits, the app seamlessly uses your fallback keys without re-sending the question.',
                  style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),

                // Cascade Visual Flow
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ShiraziColors.surfaceContainer,
                    borderRadius: ShiraziRadius.roundedMd,
                    border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPriorityStepBadge('Tier 1', 'Shirazi Core', true),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: ShiraziColors.outline),
                      _buildPriorityStepBadge(
                        'Tier 2',
                        settings.preferredProvider.toUpperCase(),
                        settings.getKeyForProvider(settings.preferredProvider).isNotEmpty,
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: ShiraziColors.outline),
                      _buildPriorityStepBadge(
                        'Tier 3',
                        settings.secondaryProvider.toUpperCase(),
                        settings.getKeyForProvider(settings.secondaryProvider).isNotEmpty,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Preferred and Secondary Selectors
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferred Fallback (Tier 2)',
                            style: ShiraziTypography.labelSm(color: ShiraziColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: ShiraziColors.surfaceContainer,
                              borderRadius: ShiraziRadius.roundedMd,
                              border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.4)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: settings.preferredProvider,
                                isExpanded: true,
                                dropdownColor: ShiraziColors.surfaceContainerHigh,
                                style: ShiraziTypography.bodySm(color: ShiraziColors.onSurface),
                                items: const [
                                  DropdownMenuItem(value: 'gemini', child: Text('Gemini (Flash)', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'groq', child: Text('Groq (LLaMA 3.3)', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'openrouter', child: Text('OpenRouter', overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setPreferredProvider(val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secondary Fallback (Tier 3)',
                            style: ShiraziTypography.labelSm(color: ShiraziColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: ShiraziColors.surfaceContainer,
                              borderRadius: ShiraziRadius.roundedMd,
                              border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.4)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: settings.secondaryProvider,
                                isExpanded: true,
                                dropdownColor: ShiraziColors.surfaceContainerHigh,
                                style: ShiraziTypography.bodySm(color: ShiraziColors.onSurface),
                                items: const [
                                  DropdownMenuItem(value: 'groq', child: Text('Groq (LLaMA 3.3)', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'gemini', child: Text('Gemini (Flash)', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'openrouter', child: Text('OpenRouter', overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    settings.setSecondaryProvider(val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: ShiraziSpacing.spaceMd),

          // 2b. Connection Security (§1, §5)
          _buildSecuritySection(context, settings),

          const SizedBox(height: ShiraziSpacing.spaceMd),

          // 3. Choose AI Service Provider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MANAGE PROVIDER KEYS',
                style: ShiraziTypography.labelMd(
                  color: ShiraziColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'إدارة المفاتيح',
                  style: ShiraziTypography.amiri(
                    fontSize: 13,
                    color: ShiraziColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildProviderCard(
                  id: 'gemini',
                  name: 'Gemini',
                  subtitle: settings.geminiKey.isNotEmpty ? 'Key Saved' : 'Free & Fast',
                  icon: Icons.psychology,
                  isSelected: settings.selectedProvider == 'gemini',
                  onTap: () {
                    settings.selectProvider('gemini');
                    _keyController.text = settings.currentApiKey;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProviderCard(
                  id: 'groq',
                  name: 'Groq Cloud',
                  subtitle: settings.groqKey.isNotEmpty ? 'Key Saved' : 'Ultra Speed',
                  icon: Icons.bolt,
                  isSelected: settings.selectedProvider == 'groq',
                  onTap: () {
                    settings.selectProvider('groq');
                    _keyController.text = settings.currentApiKey;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProviderCard(
                  id: 'openrouter',
                  name: 'OpenRouter',
                  subtitle: settings.openRouterKey.isNotEmpty ? 'Key Saved' : 'Multi-Model',
                  icon: Icons.hub,
                  isSelected: settings.selectedProvider == 'openrouter',
                  onTap: () {
                    settings.selectProvider('openrouter');
                    _keyController.text = settings.currentApiKey;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: ShiraziSpacing.spaceMd),

          // 4. Key Input & Configuration Card
          Container(
            padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
            decoration: BoxDecoration(
              color: ShiraziColors.surfaceContainerLow,
              borderRadius: ShiraziRadius.roundedXl,
              border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.3)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.key, size: 18, color: ShiraziColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${settings.selectedProvider.toUpperCase()} CREDENTIALS',
                          style: ShiraziTypography.labelMd(
                            color: ShiraziColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Enable/Disable Switch
                        Text(
                          settings.isProviderEnabled(settings.selectedProvider) ? 'Active' : 'Disabled',
                          style: ShiraziTypography.labelSm(
                            color: settings.isProviderEnabled(settings.selectedProvider)
                                ? ShiraziColors.secondary
                                : ShiraziColors.outline,
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: settings.isProviderEnabled(settings.selectedProvider),
                            activeColor: ShiraziColors.secondary,
                            onChanged: (val) {
                              settings.toggleProviderEnabled(settings.selectedProvider, val);
                            },
                          ),
                        ),
                        // Delete Key Button
                        if (settings.currentApiKey.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            tooltip: 'Remove key',
                            onPressed: () {
                              settings.deleteKey(settings.selectedProvider);
                              _keyController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${settings.selectedProvider.toUpperCase()} key removed securely'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Masked key indicator if already saved
                if (settings.currentApiKey.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ShiraziColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ShiraziColors.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, size: 12, color: ShiraziColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Secured: ${settings.getMaskedKey(settings.selectedProvider)}',
                          style: ShiraziTypography.dynamicLabel(
                            'en',
                            fontSize: 11,
                            color: ShiraziColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Status Badge
                Builder(
                  builder: (context) {
                    final isTesting = settings.isTestingKey || settings.testStatus.contains('Validating');
                    final isError = settings.testStatus.contains('Failed') ||
                        settings.testStatus.contains('Invalid') ||
                        settings.testStatus.contains('Please') ||
                        settings.testStatus.contains('Error') ||
                        settings.testStatus.contains('Unsupported');
                    final isSuccess = settings.testStatus.contains('Verified') ||
                        settings.testStatus.contains('200') ||
                        settings.testStatus.contains('Saved');

                    final statusColor = isTesting
                        ? Colors.amber
                        : isError
                            ? Colors.redAccent
                            : isSuccess
                                ? ShiraziColors.secondary
                                : ShiraziColors.secondary;

                    final statusIcon = isTesting
                        ? Icons.sync
                        : isError
                            ? Icons.error_outline
                            : Icons.check_circle;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: ShiraziRadius.roundedFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            settings.testStatus,
                            style: ShiraziTypography.labelSm(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Text Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: ShiraziColors.surfaceContainer,
                    borderRadius: ShiraziRadius.roundedMd,
                    border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _keyController,
                          obscureText: _obscureText,
                          style: ShiraziTypography.bodySm(color: ShiraziColors.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Paste new or updated API key...',
                            hintStyle: ShiraziTypography.bodySm(color: ShiraziColors.outline),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility : Icons.visibility_off,
                          size: 18,
                        ),
                        color: ShiraziColors.onSurfaceVariant,
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Save & Test Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final clean = SettingsProvider.sanitizeApiKey(_keyController.text);
                          _keyController.text = clean;
                          // Honest save: only announce success when the key
                          // actually landed in secure device storage.
                          final ok = await settings.saveCurrentKey(clean);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'API Key saved to secure device storage'
                                  : 'Save failed: ${settings.testStatus}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShiraziColors.primary,
                          foregroundColor: ShiraziColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: ShiraziRadius.roundedMd,
                          ),
                        ),
                        icon: const Icon(Icons.save, size: 16),
                        label: Text(
                          'Save Key',
                          style: ShiraziTypography.labelMd(
                            color: ShiraziColors.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: settings.isTestingKey
                            ? null
                            : () => settings.testConnection(_keyController.text),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: ShiraziColors.surfaceContainer,
                          side: BorderSide(color: ShiraziColors.outlineVariant.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: ShiraziRadius.roundedMd,
                          ),
                        ),
                        icon: settings.isTestingKey
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.verified, size: 16, color: ShiraziColors.secondary),
                        label: Text(
                          'Test Connection',
                          style: ShiraziTypography.labelMd(
                            color: ShiraziColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Free Key Guide Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text(
                            'Need a free key? 1-minute setup guide',
                            style: ShiraziTypography.bodySm(color: ShiraziColors.primary),
                          ),
                          const Icon(Icons.north_east, size: 12, color: ShiraziColors.primary),
                        ],
                      ),
                    ),
                    Text(
                      '100% Free Tier Available',
                      style: ShiraziTypography.labelSm(color: ShiraziColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: ShiraziSpacing.spaceMd),

          // 4. App & Reading Preferences
          Container(
            padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
            decoration: BoxDecoration(
              color: ShiraziColors.surfaceContainerLow,
              borderRadius: ShiraziRadius.roundedXl,
              border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune, size: 18, color: ShiraziColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'APP & READING PREFERENCES',
                          style: ShiraziTypography.labelMd(
                            color: ShiraziColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        'تفضيلات القراءة',
                        style: ShiraziTypography.amiri(
                          fontSize: 13,
                          color: ShiraziColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Language Selector
                Text(
                  AppStrings.of(context).languageSectionTitle,
                  style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildLangButton(
                        label: 'العربية',
                        code: 'ar',
                        isArabic: true,
                        isSelected: settings.language == 'ar',
                        onTap: () => settings.setLanguage('ar'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildLangButton(
                        label: 'اردو',
                        code: 'ur',
                        isUrdu: true,
                        isSelected: settings.language == 'ur',
                        onTap: () => settings.setLanguage('ur'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildLangButton(
                        label: 'English',
                        code: 'en',
                        isSelected: settings.language == 'en',
                        onTap: () => settings.setLanguage('en'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Font Size Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Arabic Font Size (حجم الخط)',
                      style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                    ),
                    Text(
                      '${settings.arabicFontSize.toInt()}px',
                      style: ShiraziTypography.labelSm(color: ShiraziColors.secondary),
                    ),
                  ],
                ),
                Slider(
                  value: settings.arabicFontSize,
                  min: 14,
                  max: 24,
                  divisions: 10,
                  activeColor: ShiraziColors.primary,
                  inactiveColor: ShiraziColors.surfaceContainerHighest,
                  onChanged: settings.setFontSize,
                ),

                // Live Preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ShiraziColors.surfaceContainer,
                    borderRadius: ShiraziRadius.roundedMd,
                    border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.2)),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'بِسْمِ اللَّـهِ الرَّحْمَـٰنِ الرَّحِيمِ • كِتَابُ الحَجِّ وَالعُمْرَةِ',
                      textAlign: TextAlign.center,
                      style: ShiraziTypography.amiri(
                        fontSize: settings.arabicFontSize,
                        color: ShiraziColors.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Offline Reading Cache Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline Reading Cache',
                            style: ShiraziTypography.bodyMd(color: ShiraziColors.onSurface),
                          ),
                          Text(
                            'Keep downloaded codices and answered fatwas on device',
                            style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: settings.offlineCache,
                      activeColor: ShiraziColors.secondary,
                      onChanged: settings.toggleOfflineCache,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: ShiraziSpacing.spaceMd),

          // 5. Scholar Identity & Research Sanctuary
          Container(
            padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
            decoration: BoxDecoration(
              color: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.85),
              borderRadius: ShiraziRadius.roundedXl,
              border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: ShiraziColors.surfaceContainerHigh,
                            borderRadius: ShiraziRadius.roundedMd,
                            border: Border.all(
                              color: settings.isAuthenticated ? ShiraziColors.primary : ShiraziColors.outlineVariant.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            settings.isAuthenticated ? Icons.verified : Icons.person_outline,
                            size: 20,
                            color: settings.isAuthenticated ? ShiraziColors.primary : ShiraziColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  settings.isAuthenticated ? settings.scholarName : 'Guest Scholarly Node',
                                  style: ShiraziTypography.bodyMd(
                                    color: ShiraziColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: settings.isAuthenticated
                                        ? ShiraziColors.secondary.withValues(alpha: 0.2)
                                        : ShiraziColors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    settings.isAuthenticated ? 'Verified Isnad' : 'Guest Node',
                                    style: ShiraziTypography.labelSm(
                                      color: settings.isAuthenticated ? ShiraziColors.secondary : ShiraziColors.outline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              settings.isAuthenticated ? settings.scholarRole : 'Decentralized local vault',
                              style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0x224D4635), height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WelcomeScreen(isStandalone: true)),
                          );
                        },
                        icon: const Icon(Icons.menu_book, size: 16, color: ShiraziColors.primary),
                        label: Text(
                          'Manifesto',
                          style: ShiraziTypography.labelSm(color: ShiraziColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0x44D4AF37)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (settings.isAuthenticated) {
                            settings.logout();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logged out. Reverted to anonymous researcher node.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignInScreen()),
                            );
                          }
                        },
                        icon: Icon(
                          settings.isAuthenticated ? Icons.logout : Icons.login,
                          size: 16,
                          color: ShiraziColors.onPrimary,
                        ),
                        label: Text(
                          settings.isAuthenticated ? 'Sign Out' : 'Sign In',
                          style: ShiraziTypography.labelSm(color: ShiraziColors.onPrimary),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: settings.isAuthenticated ? ShiraziColors.error : ShiraziColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: ShiraziSpacing.spaceMd),

          // 6. Admin Console Entry (Restricted)
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminHealthScreen()),
              );
            },
            borderRadius: ShiraziRadius.roundedXl,
            child: Container(
              padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
              decoration: BoxDecoration(
                color: ShiraziColors.surfaceContainerLowest.withOpacity(0.8),
                borderRadius: ShiraziRadius.roundedXl,
                border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ShiraziColors.surfaceContainerHigh,
                            borderRadius: ShiraziRadius.roundedMd,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 20,
                            color: ShiraziColors.outline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Admin Console',
                                    style: ShiraziTypography.bodyMd(
                                      color: ShiraziColors.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: ShiraziColors.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Restricted',
                                      style: ShiraziTypography.labelSm(
                                        color: ShiraziColors.outline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Manage Lucene index, OCI clusters & backend nodes',
                                style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 20, color: ShiraziColors.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );

    if (canPop) {
      return Scaffold(
        backgroundColor: ShiraziColors.background,
        appBar: AppBar(
          backgroundColor: ShiraziColors.surfaceContainerLow,
          elevation: 0,
          title: Text(
            'API Keys & Fallbacks',
            style: ShiraziTypography.headlineSm(color: ShiraziColors.onSurface),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: ShiraziColors.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: body,
      );
    }

    return body;
  }

  /// Connection security status (§1, §5).
  ///
  /// Shows whether the Oracle transport is HTTPS/WSS. User API keys are
  /// NEVER transmitted over plain HTTP in release builds.
  Widget _buildSecuritySection(BuildContext context, dynamic settings) {
    final bool secure = settings.isSecureTransport as bool;
    final String label = settings.oracleServerLabel as String;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainer,
        borderRadius: ShiraziRadius.roundedMd,
        border: Border.all(
          color: (secure ? ShiraziColors.secondary : ShiraziColors.error)
              .withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                secure ? Icons.lock : Icons.warning_amber_rounded,
                size: 18,
                color: secure ? ShiraziColors.secondary : ShiraziColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  secure
                      ? 'Secure connection (HTTPS/WSS)'
                      : 'Insecure connection (HTTP)',
                  style: ShiraziTypography.labelMd(
                    color: ShiraziColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            secure
                ? 'Questions and API keys travel over encrypted TLS.'
                : 'Your Oracle server does not use TLS yet. API keys are BLOCKED from being sent until you switch to HTTPS.',
            style: ShiraziTypography.bodySm(color: ShiraziColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard({
    required String id,
    required String name,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: ShiraziRadius.roundedXl,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? ShiraziColors.surfaceContainerHigh : ShiraziColors.surfaceContainerLow,
          borderRadius: ShiraziRadius.roundedXl,
          border: Border.all(
            color: isSelected ? ShiraziColors.primary : ShiraziColors.outlineVariant.withOpacity(0.4),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: ShiraziColors.surfaceContainer,
                borderRadius: ShiraziRadius.roundedSm,
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected ? ShiraziColors.primary : ShiraziColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: ShiraziTypography.labelMd(
                color: ShiraziColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: ShiraziTypography.labelSm(
                color: isSelected ? ShiraziColors.secondary : ShiraziColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityStepBadge(String tier, String name, bool isConfigured) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isConfigured
                ? ShiraziColors.secondary.withOpacity(0.15)
                : ShiraziColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tier,
            style: ShiraziTypography.dynamicLabel(
              'en',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isConfigured ? ShiraziColors.secondary : ShiraziColors.outline,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: ShiraziTypography.dynamicLabel(
            'en',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isConfigured ? ShiraziColors.onSurface : ShiraziColors.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildLangButton({
    required String label,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
    bool isArabic = false,
    bool isUrdu = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: ShiraziRadius.roundedMd,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: ShiraziColors.surfaceContainer,
          borderRadius: ShiraziRadius.roundedMd,
          border: Border.all(
            color: isSelected ? ShiraziColors.primary : ShiraziColors.outlineVariant.withOpacity(0.4),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Center(
          child: isArabic
              ? Text(label, style: ShiraziTypography.amiri(fontSize: 14, fontWeight: FontWeight.bold))
              : (isUrdu
                  ? Text(label, style: ShiraziTypography.urdu(fontSize: 13, height: 1.6))
                  : Text(label, style: ShiraziTypography.bodySm(color: ShiraziColors.onSurface))),
        ),
      ),
    );
  }
}
