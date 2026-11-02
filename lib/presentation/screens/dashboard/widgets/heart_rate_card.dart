import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/heart_rate_sample.dart';
import '../../../../domain/models/workout_model.dart';
import '../../../widgets/pulse_card.dart';

class HeartRateCard extends StatelessWidget {
  final double? restingHeartRate;
  final double? baselineRhr;
  final List<HeartRateSample> hrSamples;
  final List<WorkoutModel> workouts;

  const HeartRateCard({
    super.key,
    required this.restingHeartRate,
    this.baselineRhr,
    required this.hrSamples,
    required this.workouts,
  });

  @override
  Widget build(BuildContext context) {
    final int? latestBpm = hrSamples.isNotEmpty ? hrSamples.last.bpm : null;

    // Workout HR summary
    int? workoutPeakHr;
    int? workoutAvgHr;
    for (final w in workouts) {
      if (w.maxHeartRate != null &&
          (workoutPeakHr == null || w.maxHeartRate! > workoutPeakHr)) {
        workoutPeakHr = w.maxHeartRate;
      }
      if (w.avgHeartRate != null &&
          (workoutAvgHr == null || w.avgHeartRate! > workoutAvgHr)) {
        workoutAvgHr = w.avgHeartRate;
      }
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
                  color: AppColors.heartRatePink.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.heartRatePink,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HEART RATE TELEMETRY',
                style: AppTypography.labelMedium.copyWith(
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Resting Heart Rate Tile
              Expanded(
                child: _buildMetricBlock(
                  title: 'RESTING HR',
                  value: restingHeartRate != null
                      ? '${restingHeartRate!.round()} bpm'
                      : 'Unavailable',
                  subtext: baselineRhr != null
                      ? 'Baseline: ${baselineRhr!.round()} bpm'
                      : (restingHeartRate != null
                            ? 'Establishing baseline...'
                            : 'No resting data from Health Connect'),
                  color: AppColors.readyGreen,
                  isAvailable: restingHeartRate != null,
                ),
              ),
              const SizedBox(width: 12),
              // Latest Heart Rate Tile
              Expanded(
                child: _buildMetricBlock(
                  title: 'LATEST HR',
                  value: latestBpm != null ? '$latestBpm bpm' : 'Unavailable',
                  subtext: hrSamples.isNotEmpty
                      ? '${hrSamples.length} samples today'
                      : 'Awaiting sensor sync',
                  color: AppColors.heartRatePink,
                  isAvailable: latestBpm != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Workout HR Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORKOUT HR METRICS',
                      style: AppTypography.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      workoutPeakHr != null
                          ? 'Peak: $workoutPeakHr bpm  •  Avg: ${workoutAvgHr ?? "—"} bpm'
                          : 'No active workout HR recorded today',
                      style: AppTypography.bodySmall.copyWith(
                        color: workoutPeakHr != null
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                Icon(
                  workoutPeakHr != null
                      ? Icons.show_chart_rounded
                      : Icons.info_outline_rounded,
                  color: workoutPeakHr != null
                      ? AppColors.limeAccent
                      : AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBlock({
    required String title,
    required String value,
    required String subtext,
    required Color color,
    required bool isAvailable,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isAvailable ? color : AppColors.textTertiary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: isAvailable
                  ? AppColors.textSecondary
                  : AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
