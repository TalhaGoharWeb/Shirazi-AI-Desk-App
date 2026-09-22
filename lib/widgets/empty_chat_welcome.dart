import 'package:flutter/material.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/localization/app_strings.dart';
import 'shirazi_emblem.dart';

class EmptyChatWelcome extends StatelessWidget {
  final ValueChanged<String> onPromptSelected;

  const EmptyChatWelcome({
    super.key,
    required this.onPromptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emblem & Header
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ShiraziColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x66D4AF37), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33D4AF37),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(child: ShiraziEmblem(size: 38)),
          ),
          const SizedBox(height: 16),

          Text(
            strings.brandTitle,
            style: ShiraziTypography.dynamicHeadline(
              strings.lang,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ShiraziColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          Text(
            strings.welcomeMottoQuote,
            style: ShiraziTypography.dynamicBody(
              strings.lang,
              fontSize: 14,
              color: ShiraziColors.primaryFixedDim,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Curated Prompt Starters Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;
              final promptCards = [
                _buildPromptCard(
                  context,
                  title: strings.promptStarter1Title,
                  desc: strings.promptStarter1Desc,
                  icon: Icons.currency_bitcoin,
                  strings: strings,
                ),
                _buildPromptCard(
                  context,
                  title: strings.promptStarter2Title,
                  desc: strings.promptStarter2Desc,
                  icon: Icons.account_balance,
                  strings: strings,
                ),
                _buildPromptCard(
                  context,
                  title: strings.promptStarter3Title,
                  desc: strings.promptStarter3Desc,
                  icon: Icons.biotech,
                  strings: strings,
                ),
                _buildPromptCard(
                  context,
                  title: strings.promptStarter4Title,
                  desc: strings.promptStarter4Desc,
                  icon: Icons.auto_stories,
                  strings: strings,
                ),
              ];

              if (isWide) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.4,
                  children: promptCards,
                );
              } else {
                return Column(
                  children: promptCards.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: c,
                  )).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required AppStrings strings,
  }) {
    return InkWell(
      onTap: () => onPromptSelected(desc),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ShiraziColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x334D4635), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ShiraziColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: ShiraziColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: ShiraziTypography.dynamicHeadline(
                      strings.lang,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: ShiraziColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: ShiraziTypography.dynamicBody(
                      strings.lang,
                      fontSize: 11.5,
                      color: ShiraziColors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: ShiraziColors.outline),
          ],
        ),
      ),
    );
  }
}
