import 'package:flutter/material.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/localization/app_strings.dart';
import '../widgets/shirazi_app_bar.dart';
import '../widgets/shirazi_bottom_nav.dart';
import 'chat_screen.dart';
import 'settings_byok_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

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
              onProfileTap: _openProfile,
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ChatScreen(onProfileTap: _openProfile),
          const SettingsByokScreen(),
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
}
