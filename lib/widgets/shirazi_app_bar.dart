import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../core/localization/app_strings.dart';

class ShiraziAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;

  const ShiraziAppBar({
    super.key,
    required this.title,
    this.onSearchTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(ShiraziSpacing.headerHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          height: ShiraziSpacing.headerHeight + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: ShiraziSpacing.gutterMobile,
            right: ShiraziSpacing.gutterMobile,
          ),
          decoration: BoxDecoration(
            color: ShiraziColors.surfaceContainerLowest.withOpacity(0.85),
            border: const Border(
              bottom: BorderSide(
                color: Color(0x334D4635),
                width: 0.5,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                offset: Offset(0, 1),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Brand & Title block
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ShiraziColors.surfaceContainerLow,
                      borderRadius: ShiraziRadius.roundedMd,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26D4AF37),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: ShiraziColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: ShiraziSpacing.spaceSm),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.of(context).brandTitle,
                        style: ShiraziTypography.labelSm(
                          color: ShiraziColors.secondary,
                          fontWeight: FontWeight.w600,
                        ).copyWith(letterSpacing: 0.8),
                      ),
                      Text(
                        title,
                        style: ShiraziTypography.headlineSm(
                          color: ShiraziColors.onSurface,
                        ).copyWith(height: 1.1),
                      ),
                    ],
                  ),
                ],
              ),

              // Right Actions: Search & Profile Avatar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, size: 22),
                    color: ShiraziColors.onSurfaceVariant,
                    splashRadius: 20,
                    onPressed: onSearchTap,
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: ShiraziColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: ShiraziColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
