import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/strain_result.dart';
import '../../../widgets/pulse_card.dart';

class CardiovascularLoadCard extends StatelessWidget {
  final StrainResult? strain;

  const CardiovascularLoadCard({super.key, required this.strain});

  @override
  Widget build(BuildContext context) {
    final bool isMeasured = strain?.isMeasured ?? false;
    final double cardioLoad = strain?.cardiovascularLoad ?? 0.0;
    final double movementStrain = strain?.movementStrain ?? 0.0;
    final int activeCalories = strain?.activeCalories ?? 0;
    final int steps = strain?.steps ?? 0;

    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.strainRed.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.strainRed,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CARDIOVASCULAR LOAD',
                    style: AppTypography.labelMedium.copyWith(
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Measured vs Estimated Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isMeasured
                      ? AppColors.readyGreen.withAlpha(30)
                      : AppColors.moderateAmber.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isMeasured
                        ? AppColors.readyGreen.withAlpha(80)
                        : AppColors.moderateAmber.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isMeasured
                            ? AppColors.readyGreen
                            : AppColors.moderateAmber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isMeasured ? 'MEASURED HR' : 'ESTIMATED LOAD',
                      style: TextStyle(
                        color: isMeasured
                            ? AppColors.readyGreen
                            : AppColors.moderateAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cardio Load Metric Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                cardioLoad.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'cardio score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'MOVEMENT LOAD',
                    style: AppTypography.labelMedium.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+${movementStrain.toStringAsFixed(1)} strain',
                    style: const TextStyle(
                      color: AppColors.limeAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Load Split Visual Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: ((cardioLoad / 21.0) * 100).round().clamp(5, 95),
                  child: Container(height: 8, color: AppColors.strainRed),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: ((movementStrain / 21.0) * 100).round().clamp(5, 95),
                  child: Container(height: 8, color: AppColors.limeAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegend(AppColors.strainRed, 'Cardiovascular Stimulus'),
              _buildLegend(AppColors.limeAccent, 'Daily Active Movement'),
            ],
          ),
          const SizedBox(height: 14),

          // Transparent Data Source Explanation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isMeasured
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: isMeasured
                      ? AppColors.readyGreen
                      : AppColors.moderateAmber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMeasured
                        ? 'Cardiovascular load is directly measured from continuous heart-rate samples in Health Connect. Time in elevated zones drives the score.'
                        : 'No direct continuous heart-rate samples recorded in Health Connect today. Training load is estimated using workout duration, perceived exertion (RPE), $steps steps, and $activeCalories active kcal.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                      fontSize: 11,
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

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 10,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
