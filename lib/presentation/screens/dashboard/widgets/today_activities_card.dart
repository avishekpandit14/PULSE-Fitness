import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/workout_model.dart';
import '../../../widgets/pulse_card.dart';

/// "My Day" activity strip: what has actually been logged today.
class TodayActivitiesCard extends StatelessWidget {
  final List<WorkoutModel> workouts;
  final VoidCallback onTap;

  const TodayActivitiesCard({
    super.key,
    required this.workouts,
    required this.onTap,
  });

  static const int _maxRows = 3;

  @override
  Widget build(BuildContext context) {
    final visible = workouts.take(_maxRows).toList();
    final overflow = workouts.length - visible.length;

    return PulseCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S ACTIVITIES",
                style: AppTypography.labelMedium.copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                workouts.isEmpty
                    ? 'NONE YET'
                    : '${workouts.length} SESSION${workouts.length == 1 ? '' : 'S'}',
                style: AppTypography.labelMedium.copyWith(
                  fontSize: 9,
                  letterSpacing: 0.6,
                  color: workouts.isEmpty
                      ? AppColors.textTertiary
                      : AppColors.limeAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (workouts.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_walk_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No workouts synced from Health Connect yet today.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...visible.map((workout) => _ActivityRow(workout: workout)),
          if (overflow > 0) ...[
            const SizedBox(height: 8),
            Text(
              '+$overflow more today',
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
}

class _ActivityRow extends StatelessWidget {
  final WorkoutModel workout;

  const _ActivityRow({required this.workout});

  static IconData _iconFor(WorkoutType type) {
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
        return Icons.sports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hr = workout.avgHeartRate;
    final subtitle = hr != null
        ? '${workout.durationMinutes} min · $hr bpm avg'
        : '${workout.durationMinutes} min';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconFor(workout.type),
              size: 16,
              color: AppColors.limeAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.title,
                  style: AppTypography.titleSmall.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          if (workout.caloriesBurned != null)
            Text(
              '${workout.caloriesBurned} kcal',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}
