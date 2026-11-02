import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/strain_result.dart';
import '../../../../domain/models/workout_model.dart';
import '../../../widgets/pulse_card.dart';
import '../log_workout_sheet.dart';

class WorkoutStrainCard extends StatelessWidget {
  final StrainResult? strain;
  final List<WorkoutModel> workouts;
  final Function(String id)? onDeleteWorkout;

  const WorkoutStrainCard({
    super.key,
    required this.strain,
    required this.workouts,
    this.onDeleteWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final workoutStrainMap = strain?.workoutStrainMap ?? {};

    return Column(
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
                    Icons.fitness_center_rounded,
                    color: AppColors.limeAccent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'WORKOUT SESSIONS (${workouts.length})',
                  style: AppTypography.labelMedium.copyWith(
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.limeAccent,
              ),
              label: const Text(
                'Log Workout',
                style: TextStyle(
                  color: AppColors.limeAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (_) => const LogWorkoutSheet(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (workouts.isNotEmpty) ...[
          ...workouts.map((w) {
            final double wStrain = workoutStrainMap[w.id] ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PulseCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getWorkoutIcon(w.type),
                            color: AppColors.limeAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      w.title,
                                      style: AppTypography.titleSmall,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      w.isManual ? 'MANUAL' : 'AUTO-SYNCED',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: w.isManual
                                            ? AppColors.textTertiary
                                            : AppColors.readyGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${w.durationMinutes} mins  •  ${w.caloriesBurned ?? "—"} kcal',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              wStrain.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.strainRed,
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
                        if (w.isManual && onDeleteWorkout != null)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                            onPressed: () => onDeleteWorkout!(w.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Heart Rate Telemetry Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricPill(
                          'AVG HR',
                          w.avgHeartRate != null
                              ? '${w.avgHeartRate} bpm'
                              : '—',
                          AppColors.heartRatePink,
                        ),
                        _buildMetricPill(
                          'PEAK HR',
                          w.maxHeartRate != null
                              ? '${w.maxHeartRate} bpm'
                              : '—',
                          AppColors.strainRed,
                        ),
                        _buildMetricPill(
                          'EFFORT',
                          w.isManual ? 'RPE ${w.rpe}/10' : 'Measured',
                          AppColors.limeAccent,
                        ),
                        _buildMetricPill(
                          'CALORIES',
                          '${w.caloriesBurned ?? "—"} kcal',
                          AppColors.activityOrange,
                        ),
                      ],
                    ),

                    if (w.notes != null && w.notes!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        '“${w.notes}”',
                        style: AppTypography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ] else ...[
          PulseCard(
            child: Column(
              children: [
                const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.textTertiary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'No Workouts Logged Today',
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Workouts from your tracker companion app or Health Connect sync automatically. '
                  'Tap "Log Workout" above to record a manual session with duration and RPE.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 9,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
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
