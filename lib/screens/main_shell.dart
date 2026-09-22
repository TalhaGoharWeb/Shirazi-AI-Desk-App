import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../core/localization/app_strings.dart';
import '../providers/settings_provider.dart';
import '../widgets/shirazi_app_bar.dart';
import '../widgets/shirazi_bottom_nav.dart';
import '../widgets/shirazi_emblem.dart';
import 'chat_screen.dart';
import 'admin_audit_log_screen.dart';
import 'settings_byok_screen.dart';
import 'welcome_screen.dart';
import 'sign_in_screen.dart';
import 'registration_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final titles = [
      strings.navResearch,
      strings.navSettings,
    ];

    return Scaffold(
      backgroundColor: ShiraziColors.background,
      appBar: _currentIndex == 0
          ? null
          : ShiraziAppBar(
              title: titles[_currentIndex],
              onProfileTap: () => _showScholarProfileModal(context),
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ChatScreen(),
          SettingsByokScreen(),
        ],
      ),
      bottomNavigationBar: ShiraziBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
      ),
    );
  }

  void _showScholarProfileModal(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: ShiraziColors.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: const Color(0x334D4635),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: ShiraziSpacing.gutterMobile,
            right: ShiraziSpacing.gutterMobile,
            top: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ShiraziColors.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Scholar info header
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: ShiraziColors.surfaceContainerHigh,
                      borderRadius: ShiraziRadius.roundedLg,
                      border: Border.all(
                        color: settings.isAuthenticated ? ShiraziColors.primary : ShiraziColors.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: settings.isAuthenticated
                          ? const ShiraziEmblem(size: 32, strokeWidth: 1.5)
                          : const Icon(Icons.person_outline, size: 28, color: ShiraziColors.secondary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                settings.isAuthenticated ? settings.scholarName : 'Guest Scholarly Node',
                                style: ShiraziTypography.headlineSm(color: ShiraziColors.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (settings.isAuthenticated)
                              const Icon(Icons.verified, size: 18, color: ShiraziColors.primary),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          settings.isAuthenticated ? settings.scholarRole : 'Local Hardware Enclave • Private Vault',
                          style: ShiraziTypography.bodySm(color: ShiraziColors.secondary),
                        ),
                        if (settings.isAuthenticated)
                          Text(
                            settings.scholarEmail,
                            style: ShiraziTypography.labelSm(color: ShiraziColors.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0x224D4635), height: 1),
              const SizedBox(height: 16),

              // Action buttons
              if (!settings.isAuthenticated) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    );
                  },
                  icon: const Icon(Icons.login, size: 18, color: ShiraziColors.onPrimary),
                  label: Text('Sign In with Scholar ID / SSO', style: ShiraziTypography.labelMd(color: ShiraziColors.onPrimary)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShiraziColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_add_outlined, size: 18, color: ShiraziColors.secondary),
                  label: Text('Register New Scholar Profile', style: ShiraziTypography.labelMd(color: ShiraziColors.secondary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x44D4AF37)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () {
                    settings.logout();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out of Scholar Identity.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, size: 18, color: ShiraziColors.error),
                  label: Text('Sign Out / Revert to Anonymous Node', style: ShiraziTypography.labelMd(color: ShiraziColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ShiraziColors.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Admin Research Dashboard Entry
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAuditLogScreen()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18, color: ShiraziColors.primary),
                label: Text(
                  'Admin Research Oversight Dashboard',
                  style: ShiraziTypography.labelMd(color: ShiraziColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0x66D4AF37)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),

              // Introduction / Welcome Manifesto link
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen(isStandalone: true)),
                  );
                },
                icon: const Icon(Icons.menu_book, size: 18, color: ShiraziColors.primaryFixedDim),
                label: Text(
                  'Scholarly Manifesto & System Overview',
                  style: ShiraziTypography.labelMd(color: ShiraziColors.primaryFixedDim),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
