import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/recommendation_result.dart';
import '../../../widgets/pulse_card.dart';

class RecommendationCard extends StatelessWidget {
  final RecommendationResult? recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    if (recommendation == null) return const SizedBox.shrink();

    final rec = recommendation!;
    Color accentColor;
    IconData icon;

    switch (rec.suggestion) {
      case TrainingSuggestion.heavy:
        accentColor = AppColors.limeAccent;
        icon = Icons.bolt_rounded;
        break;
      case TrainingSuggestion.moderate:
        accentColor = AppColors.sleepCyan;
        icon = Icons.directions_run_rounded;
        break;
      case TrainingSuggestion.light:
        accentColor = AppColors.moderateAmber;
        icon = Icons.accessibility_new_rounded;
        break;
      case TrainingSuggestion.rest:
        accentColor = AppColors.restCoral;
        icon = Icons.self_improvement_rounded;
        break;
    }

    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'TRAINING RECOMMENDATION',
                style: AppTypography.labelMedium.copyWith(
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rec.suggestion.displayName.toUpperCase(),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            rec.title,
            style: AppTypography.titleSmall.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rec.description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (rec.mainFactors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'KEY INFLUENCING FACTORS:',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            ...rec.mainFactors.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: AppColors.limeAccent),
                    ),
                    Expanded(
                      child: Text(
                        f,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.safetyDisclaimer,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      height: 1.3,
                    ),
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
