import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/strain_result.dart';
import '../../../../domain/models/workout_model.dart';
import '../../../widgets/pulse_card.dart';

class ActivityBreakdownCard extends StatelessWidget {
  final StrainResult? strain;
  final List<WorkoutModel> workouts;

  const ActivityBreakdownCard({
    super.key,
    required this.strain,
    required this.workouts,
  });

  @override
  Widget build(BuildContext context) {
    final int steps = strain?.steps ?? 0;
    final int activeCalories = strain?.activeCalories ?? 0;
    final double movementStrain = strain?.movementStrain ?? 0.0;
    final workoutStrainMap = strain?.workoutStrainMap ?? {};

    // Estimate walking minutes from steps (approx 100 steps per minute walking)
    final int walkingMinutes = (steps / 100).round();

    // Total active duration
    final int totalWorkoutMins = workouts.fold<int>(
      0,
      (a, b) => a + b.durationMinutes,
    );
    final int totalActiveMins = walkingMinutes + totalWorkoutMins;

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
                      color: AppColors.activityOrange.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.pie_chart_rounded,
                      color: AppColors.activityOrange,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ACTIVITY BREAKDOWN',
                    style: AppTypography.labelMedium.copyWith(
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '${totalActiveMins}m Active Today',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.limeAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Background Walking / Movement Row
          _buildActivityItem(
            icon: Icons.directions_walk_rounded,
            title: 'Daily Movement & Walking',
            subtitle:
                '$steps steps  •  ~$walkingMinutes mins  •  $activeCalories kcal',
            strainScore: movementStrain,
            iconColor: AppColors.limeAccent,
            badge: 'BACKGROUND',
          ),

          // 2. Individual Workout Rows
          if (workouts.isNotEmpty) ...[
            const Divider(height: 18),
            ...workouts.map((w) {
              final double wStrain = workoutStrainMap[w.id] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildActivityItem(
                  icon: _getWorkoutIcon(w.type),
                  title: w.title,
                  subtitle:
                      '${w.durationMinutes} mins  •  ${w.caloriesBurned ?? "—"} kcal${w.avgHeartRate != null ? "  •  avg ${w.avgHeartRate} bpm" : ""}',
                  strainScore: wStrain,
                  iconColor: AppColors.strainRed,
                  badge: w.isManual ? 'MANUAL' : 'TRACKED',
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'No dedicated workout sessions logged today. Strain is currently driven solely by baseline movement.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required double strainScore,
    required Color iconColor,
    required String badge,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${strainScore.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: iconColor,
              ),
            ),
            Text(
              'strain',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 9,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getWorkoutIcon(WorkoutType type) {
    switch (type) {
      case WorkoutType.running:
        return Icons.directions_run_rounded;
      case WorkoutType.cycling:
        return Icons.directions_bike_rounded;
      case WorkoutType.swimming:
        return Icons.pool_rounded;
      case WorkoutType.strength:
        return Icons.fitness_center_rounded;
      case WorkoutType.hiit:
        return Icons.timer_rounded;
      case WorkoutType.walking:
        return Icons.directions_walk_rounded;
      case WorkoutType.other:
        return Icons.sports_gymnastics_rounded;
    }
  }
}
