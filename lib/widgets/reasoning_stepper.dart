import 'package:flutter/material.dart';
import '../core/theme/shirazi_colors.dart';
import '../core/theme/shirazi_typography.dart';
import '../core/constants/shirazi_spacing.dart';
import '../core/localization/app_strings.dart';
import '../models/inquiry.dart';

class ReasoningStepper extends StatelessWidget {
  final List<ReasoningStep> steps;

  const ReasoningStepper({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final completedCount = steps.where((s) => s.isCompleted).length;

    String headerTitle;
    String statusBadge;
    if (strings.lang == 'ar') {
      headerTitle = 'محرك تخريج النصوص وتحقيق الأسانيد';
      statusBadge = '$completedCount من ${steps.length} مراحل مكتملة';
    } else if (strings.lang == 'ur') {
      headerTitle = 'تخریج متون و تحقیق اسناد انجن';
      statusBadge = '$completedCount از ${steps.length} مراحل مکمل';
    } else {
      headerTitle = 'TAKAHRIJ & ISNAD SYNTHESIS ENGINE';
      statusBadge = '$completedCount of ${steps.length} Stages Complete';
    }

    return Container(
      padding: const EdgeInsets.all(ShiraziSpacing.spaceMd),
      decoration: BoxDecoration(
        color: ShiraziColors.surfaceContainerLowest.withOpacity(0.85),
        borderRadius: ShiraziRadius.roundedXl,
        border: Border.all(color: ShiraziColors.outlineVariant.withOpacity(0.3), width: 0.5),
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
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_tree,
                      size: 18,
                      color: ShiraziColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        headerTitle,
                        overflow: TextOverflow.ellipsis,
                        style: ShiraziTypography.labelMd(
                          color: ShiraziColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ).copyWith(letterSpacing: strings.isRtl ? 0 : 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ShiraziColors.secondaryContainer.withOpacity(0.3),
                  borderRadius: ShiraziRadius.roundedFull,
                ),
                child: Text(
                  statusBadge,
                  style: ShiraziTypography.labelSm(
                    color: ShiraziColors.secondaryFixed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Steps list
          Column(
            children: steps.map((step) => _buildStepTile(step)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(ReasoningStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: step.isProcessing
            ? ShiraziColors.primary.withOpacity(0.08)
            : ShiraziColors.surfaceContainerLow.withOpacity(0.6),
        borderRadius: ShiraziRadius.roundedMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator circle
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: step.isCompleted
                  ? ShiraziColors.secondaryContainer
                  : (step.isProcessing
                      ? ShiraziColors.primaryContainer
                      : ShiraziColors.surfaceContainerHigh),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: step.isCompleted
                  ? const Icon(Icons.check, size: 14, color: ShiraziColors.onSecondaryContainer)
                  : (step.isProcessing
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ShiraziColors.onPrimaryContainer,
                          ),
                        )
                      : const Icon(Icons.circle, size: 8, color: ShiraziColors.outline)),
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: ShiraziTypography.labelMd(
                          color: step.isProcessing
                              ? ShiraziColors.primary
                              : ShiraziColors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (step.duration.isNotEmpty)
                      Text(
                        step.duration,
                        style: ShiraziTypography.labelSm(
                          color: step.isProcessing
                              ? ShiraziColors.primary
                              : ShiraziColors.secondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  step.detail,
                  style: ShiraziTypography.bodySm(
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
}
