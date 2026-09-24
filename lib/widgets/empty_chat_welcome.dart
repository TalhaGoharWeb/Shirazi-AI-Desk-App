import 'package:flutter/material.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/localization/app_strings.dart';
import 'shirazi_emblem.dart';

/// Conversational home state: glowing emblem, greeting, quick suggestion
/// chips and curated prompt cards.
class EmptyChatWelcome extends StatefulWidget {
  final ValueChanged<String> onPromptSelected;

  const EmptyChatWelcome({
    super.key,
    required this.onPromptSelected,
  });

  @override
  State<EmptyChatWelcome> createState() => _EmptyChatWelcomeState();
}

class _EmptyChatWelcomeState extends State<EmptyChatWelcome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing emblem
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final t = _pulse.value;
              return Container(
                width: 84,
                height: 84,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ShiraziColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ShiraziColors.primary.withValues(alpha: 0.4 + 0.3 * t),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ShiraziColors.primary.withValues(alpha: 0.18 + 0.14 * t),
                      blurRadius: 24 + 12 * t,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(child: ShiraziEmblem(size: 56)),
              );
            },
          ),
          const SizedBox(height: 18),

          Text(
            _greeting(strings),
            style: ShiraziTypography.dynamicHeadline(
              strings.lang,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ShiraziColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              strings.welcomeMottoQuote,
              style: ShiraziTypography.dynamicBody(
                strings.lang,
                fontSize: 14,
                color: ShiraziColors.primaryFixedDim,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Quick suggestion chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: [
                _SuggestionChip(
                  label: strings.lang == 'ur'
                      ? 'نماز کے اوقات'
                      : strings.lang == 'ar'
                          ? 'أوقات الصلاة'
                          : 'Prayer times',
                  icon: Icons.schedule_rounded,
                  onTap: () => widget.onPromptSelected(
                    strings.lang == 'ur'
                        ? 'نماز کے اوقات کا شرعی حکم کیا ہے؟'
                        : strings.lang == 'ar'
                            ? 'ما حكم أوقات الصلاة الشرعية؟'
                            : 'What are the prescribed times for the five daily prayers?',
                  ),
                ),
                _SuggestionChip(
                  label: strings.lang == 'ur' ? 'روزہ' : strings.lang == 'ar' ? 'الصيام' : 'Fasting',
                  icon: Icons.nights_stay_outlined,
                  onTap: () => widget.onPromptSelected(
                    strings.lang == 'ur'
                        ? 'روزے کے فرائض و سنن بیان کریں'
                        : strings.lang == 'ar'
                            ? 'اذكر فرائض الصيام وسننه'
                            : 'Explain the obligations and sunnahs of fasting',
                  ),
                ),
                _SuggestionChip(
                  label: strings.lang == 'ur' ? 'زکوٰۃ' : strings.lang == 'ar' ? 'الزكاة' : 'Zakat',
                  icon: Icons.volunteer_activism_outlined,
                  onTap: () => widget.onPromptSelected(
                    strings.lang == 'ur'
                        ? 'زکوٰۃ کن لوگوں پر فرض ہے؟'
                        : strings.lang == 'ar'
                            ? 'على من تجب الزكاة؟'
                            : 'On whom is zakat obligatory?',
                  ),
                ),
                _SuggestionChip(
                  label: strings.lang == 'ur' ? 'حدیث کی تحقیق' : strings.lang == 'ar' ? 'تخريج الحديث' : 'Hadith check',
                  icon: Icons.verified_outlined,
                  onTap: () => widget.onPromptSelected(strings.promptStarter4Desc),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Curated prompt cards
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
              }
              return Column(
                children: promptCards
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: c,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _greeting(AppStrings strings) {
    switch (strings.lang) {
      case 'ar':
        return 'السلام عليكم، كيف أخدمك؟';
      case 'ur':
        return 'السلام علیکم، میں آپ کی کیا مدد کر سکتا ہوں؟';
      default:
        return 'Peace be upon you — how may I help?';
    }
  }

  Widget _buildPromptCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required AppStrings strings,
  }) {
    return InkWell(
      onTap: () => widget.onPromptSelected(desc),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ShiraziColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ShiraziColors.outlineVariant.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: ShiraziColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: ShiraziColors.primary),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 4),
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

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: ShiraziColors.surfaceContainerHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ShiraziColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: ShiraziColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: ShiraziTypography.dynamicLabel(
                  strings.lang,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ShiraziColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
