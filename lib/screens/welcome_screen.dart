import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/constants/shirazi_spacing.dart';
import '../core/localization/app_strings.dart';
import '../widgets/shirazi_emblem.dart';
import '../services/storage_service.dart';
import '../providers/settings_provider.dart';
import 'sign_in_screen.dart';
import 'main_shell.dart';

/// First-launch welcome screen.
///
/// A calm, cinematic introduction: emblem hero, the motto, language choice,
/// three capability pillars, the research-integrity manifesto, and one clear
/// way in. Fully localized through [AppStrings].
class WelcomeScreen extends StatefulWidget {
  final bool isStandalone;

  const WelcomeScreen({super.key, this.isStandalone = false});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isManifestoExpanded = false;

  void _enterApp(BuildContext context) {
    final storage = Provider.of<StorageService>(context, listen: false);
    storage.isFirstLaunch = false;
    if (widget.isStandalone) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  void _navigateToSignIn(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final strings = AppStrings.of(context);

    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        backgroundColor: ShiraziColors.surface,
        appBar: AppBar(
          backgroundColor: ShiraziColors.surfaceContainerLowest.withValues(alpha: 0.85),
          elevation: 0,
          leading: widget.isStandalone
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: ShiraziColors.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ShiraziEmblem(size: 26, strokeWidth: 1.5),
              const SizedBox(width: 8),
              Text(
                'Shirazi',
                style: strings.headlineStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ShiraziColors.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _enterApp(context),
              child: Text(
                strings.welcomeSkip,
                style: strings.labelStyle(
                  fontSize: 13,
                  color: ShiraziColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ShiraziSpacing.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: ShiraziSpacing.spaceLg),

                    // Hero: radiant emblem
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ShiraziColors.primary.withValues(alpha: 0.3),
                                blurRadius: 48,
                                spreadRadius: 12,
                              ),
                              BoxShadow(
                                color: ShiraziColors.secondary.withValues(alpha: 0.18),
                                blurRadius: 32,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: ShiraziColors.surfaceContainerHigh.withValues(alpha: 0.9),
                            borderRadius: ShiraziRadius.roundedXl,
                            border: Border.all(
                              color: ShiraziColors.primary.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: ShiraziEmblem(size: 64, strokeWidth: 2.2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceLg),

                    Text(
                      strings.welcomeTitle,
                      textAlign: TextAlign.center,
                      style: strings.headlineStyle(
                        fontSize: strings.lang == 'ur' ? 21 : 23,
                        fontWeight: FontWeight.bold,
                        color: ShiraziColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: strings.labelStyle(
                        fontSize: 12.5,
                        color: ShiraziColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: strings.isRtl ? 0 : 1.6,
                      ),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceLg),

                    // Motto banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: ShiraziColors.surfaceContainerLow.withValues(alpha: 0.9),
                        borderRadius: ShiraziRadius.roundedLg,
                        border: Border.all(
                          color: ShiraziColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            strings.welcomeMottoQuote,
                            textAlign: TextAlign.center,
                            style: strings.headlineStyle(
                              fontSize: strings.lang == 'ur' ? 16 : 17,
                              color: ShiraziColors.tertiaryFixed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.welcomeMottoSub,
                            textAlign: TextAlign.center,
                            style: strings.bodyStyle(
                              fontSize: 12.5,
                              color: ShiraziColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceLg),

                    // Language selection
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ShiraziColors.surfaceContainerLow.withValues(alpha: 0.85),
                        borderRadius: ShiraziRadius.roundedLg,
                        border: Border.all(
                          color: ShiraziColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language, size: 20, color: ShiraziColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  strings.welcomeLangTitle,
                                  style: strings.labelStyle(
                                    fontSize: 13.5,
                                    color: ShiraziColors.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.welcomeLangSub,
                            style: strings.bodyStyle(
                              fontSize: 12.5,
                              color: ShiraziColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildLanguageOption(
                                settings: settings,
                                langCode: 'en',
                                title: 'English',
                                subtitle: 'Default',
                              ),
                              const SizedBox(width: 8),
                              _buildLanguageOption(
                                settings: settings,
                                langCode: 'ar',
                                title: 'العربية',
                                subtitle: 'Arabic',
                              ),
                              const SizedBox(width: 8),
                              _buildLanguageOption(
                                settings: settings,
                                langCode: 'ur',
                                title: 'اردو',
                                subtitle: 'Urdu',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    // Pillars
                    _buildPillarCard(
                      strings: strings,
                      icon: Icons.menu_book,
                      iconColor: ShiraziColors.primary,
                      badgeText: strings.welcomePillar1Badge,
                      badgeColor: ShiraziColors.primary,
                      title: strings.welcomePillar1Title,
                      description: strings.welcomePillar1Desc,
                      chips: strings.welcomePillar1Chips,
                    ),
                    const SizedBox(height: ShiraziSpacing.spaceSm),
                    _buildPillarCard(
                      strings: strings,
                      icon: Icons.account_tree,
                      iconColor: ShiraziColors.secondary,
                      badgeText: strings.welcomePillar2Badge,
                      badgeColor: ShiraziColors.secondary,
                      title: strings.welcomePillar2Title,
                      description: strings.welcomePillar2Desc,
                      chips: strings.welcomePillar2Chips,
                    ),
                    const SizedBox(height: ShiraziSpacing.spaceSm),
                    _buildPillarCard(
                      strings: strings,
                      icon: Icons.key,
                      iconColor: ShiraziColors.tertiary,
                      badgeText: strings.welcomePillar3Badge,
                      badgeColor: ShiraziColors.tertiary,
                      title: strings.welcomePillar3Title,
                      description: strings.welcomePillar3Desc,
                      chips: strings.welcomePillar3Chips,
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceMd),

                    // Manifesto (collapsed)
                    InkWell(
                      onTap: () => setState(
                        () => _isManifestoExpanded = !_isManifestoExpanded,
                      ),
                      borderRadius: ShiraziRadius.roundedMd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: ShiraziColors.surfaceContainerHigh.withValues(alpha: 0.6),
                          borderRadius: ShiraziRadius.roundedMd,
                          border: Border.all(
                            color: ShiraziColors.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_user,
                                      size: 18,
                                      color: ShiraziColors.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      strings.welcomeManifestoTitle,
                                      style: strings.labelStyle(
                                        fontSize: 13,
                                        color: ShiraziColors.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  _isManifestoExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: ShiraziColors.onSurfaceVariant,
                                  size: 20,
                                ),
                              ],
                            ),
                            if (_isManifestoExpanded) ...[
                              const Divider(color: ShiraziColors.outlineVariant, height: 20),
                              _buildManifestoTenet(
                                strings,
                                strings.welcomeTenet1Title,
                                strings.welcomeTenet1Body,
                              ),
                              _buildManifestoTenet(
                                strings,
                                strings.welcomeTenet2Title,
                                strings.welcomeTenet2Body,
                              ),
                              _buildManifestoTenet(
                                strings,
                                strings.welcomeTenet3Title,
                                strings.welcomeTenet3Body,
                              ),
                              _buildManifestoTenet(
                                strings,
                                strings.welcomeTenet4Title,
                                strings.welcomeTenet4Body,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: ShiraziSpacing.spaceXl),

                    // Primary CTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _enterApp(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShiraziColors.primary,
                          foregroundColor: ShiraziColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: ShiraziRadius.roundedLg,
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              strings.welcomeEnterSanctuary,
                              style: strings.labelStyle(
                                fontSize: 14,
                                color: ShiraziColors.onPrimary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: strings.isRtl ? 0 : 1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              strings.isRtl ? Icons.arrow_back : Icons.arrow_forward,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    InkWell(
                      onTap: () => _navigateToSignIn(context),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: strings.welcomeAlreadyRegistered,
                                style: strings.bodyStyle(
                                  fontSize: 13,
                                  color: ShiraziColors.onSurfaceVariant,
                                ),
                              ),
                              TextSpan(
                                text: strings.welcomeSignIn,
                                style: strings.bodyStyle(
                                  fontSize: 13,
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

                    // Trust badges
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildTrustBadge(strings, Icons.lock, strings.welcomeBadge1),
                        _buildTrustBadge(strings, Icons.hub, strings.welcomeBadge2),
                        _buildTrustBadge(strings, Icons.visibility_off, strings.welcomeBadge3),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.welcomeFooter,
                      textAlign: TextAlign.center,
                      style: strings.labelStyle(
                        fontSize: 11,
                        color: ShiraziColors.outline,
                      ),
                    ),
                    const SizedBox(height: ShiraziSpacing.spaceXl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required SettingsProvider settings,
    required String langCode,
    required String title,
    required String subtitle,
  }) {
    final isSelected = settings.language == langCode;

    return Expanded(
      child: InkWell(
        onTap: () => settings.setLanguage(langCode),
        borderRadius: ShiraziRadius.roundedMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? ShiraziColors.primary.withValues(alpha: 0.18)
                : ShiraziColors.surfaceContainerHigh,
            borderRadius: ShiraziRadius.roundedMd,
            border: Border.all(
              color: isSelected
                  ? ShiraziColors.primary
                  : ShiraziColors.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: langCode == 'ar'
                      ? 'Amiri'
                      : (langCode == 'ur' ? 'NotoNastaliqUrdu' : null),
                  color: isSelected ? ShiraziColors.primary : ShiraziColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? ShiraziColors.primary : ShiraziColors.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillarCard({
    required AppStrings strings,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
    required String title,
    required String description,
    required List<String> chips,
  }) {
    return Container(
      padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerLow.withValues(alpha: 0.85),
        borderRadius: ShiraziRadius.roundedXl,
        border: Border.all(color: ShiraziColors.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ShiraziColors.surfaceContainerHigh,
              borderRadius: ShiraziRadius.roundedMd,
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: strings.headlineStyle(
                          fontSize: strings.lang == 'ur' ? 15 : 16,
                          fontWeight: FontWeight.bold,
                          color: ShiraziColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: strings.labelStyle(
                          fontSize: 10.5,
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: strings.bodyStyle(
                    fontSize: 13,
                    color: ShiraziColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: chips.map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ShiraziColors.surfaceContainerHighest,
                        borderRadius: ShiraziRadius.roundedFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: ShiraziColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c,
                            style: strings.labelStyle(
                              fontSize: 11,
                              color: ShiraziColors.tertiaryFixed,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManifestoTenet(AppStrings strings, String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 14, color: ShiraziColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: strings.labelStyle(
                    fontSize: 12.5,
                    color: ShiraziColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: strings.bodyStyle(
                    fontSize: 12.5,
                    color: ShiraziColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(AppStrings strings, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ShiraziColors.secondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: strings.labelStyle(
            fontSize: 11,
            color: ShiraziColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
