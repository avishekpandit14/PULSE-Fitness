import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/strain_result.dart';
import '../../../widgets/pulse_card.dart';

class RecommendedStrainCard extends StatelessWidget {
  final StrainResult? strain;
  final double? recoveryScore;

  const RecommendedStrainCard({
    super.key,
    required this.strain,
    this.recoveryScore,
  });

  @override
  Widget build(BuildContext context) {
    final target =
        strain?.recommendedTarget ??
        const RecommendedStrainTarget(
          minTarget: 10.0,
          maxTarget: 14.0,
          label: 'Moderate Optimal',
          explanation:
              'Maintain steady aerobic volume or technique work without accumulating excessive fatigue.',
        );

    final double currentStrain = strain?.score ?? 0.0;
    final String status = target.getTargetStatus(currentStrain);

    Color statusColor;
    if (status == 'In Target Zone') {
      statusColor = AppColors.readyGreen;
    } else if (status == 'Below Target') {
      statusColor = AppColors.moderateAmber;
    } else {
      statusColor = AppColors.strainRed;
    }

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
                      color: AppColors.limeAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.track_changes_rounded,
                      color: AppColors.limeAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECOMMENDED STRAIN TARGET',
                    style: AppTypography.labelMedium.copyWith(
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Target status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Target range headline
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${target.minTarget.toStringAsFixed(1)} – ${target.maxTarget.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Target Range',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (recoveryScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.battery_charging_full_rounded,
                        size: 13,
                        color: AppColors.readyGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recoveryScore!.toStringAsFixed(0)}% Recovery',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Visual 0-21 target bar
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const maxScale = 21.0;

              // Normalized offsets
              final leftTargetFrac = (target.minTarget / maxScale).clamp(
                0.0,
                1.0,
              );
              final rightTargetFrac = (target.maxTarget / maxScale).clamp(
                0.0,
                1.0,
              );
              final currentFrac = (currentStrain / maxScale).clamp(0.0, 1.0);

              final targetLeft = leftTargetFrac * width;
              final targetWidth = ((rightTargetFrac - leftTargetFrac) * width)
                  .clamp(4.0, width);
              final currentX = currentFrac * width;

              return Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Background Track
                      Container(
                        height: 12,
                        width: width,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Target Bracket Zone
                      Positioned(
                        left: targetLeft,
                        width: targetWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.limeAccent.withAlpha(50),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.limeAccent.withAlpha(150),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Current Strain Fill (from 0 to currentX)
                      Container(
                        height: 12,
                        width: currentX.clamp(0.0, width),
                        decoration: BoxDecoration(
                          color: AppColors.strainRed.withAlpha(180),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Current position marker dot
                      Positioned(
                        left: (currentX - 5).clamp(0.0, width - 10),
                        top: 1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(100),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '0',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Current: ${currentStrain.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: currentStrain > 0
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        '21',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // Target Category and rationale
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withAlpha(120),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target.label,
                  style: const TextStyle(
                    color: AppColors.limeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  target.explanation,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
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
