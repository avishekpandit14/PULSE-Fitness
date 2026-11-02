import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/sleep_session_model.dart';
import '../../../widgets/pulse_card.dart';

class SleepSummaryCard extends StatelessWidget {
  final SleepSessionModel? sleepSession;
  final double targetHours;
  final VoidCallback onTap;

  const SleepSummaryCard({
    super.key,
    required this.sleepSession,
    required this.targetHours,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasData = sleepSession != null && sleepSession!.totalMinutes > 0;

    return PulseCard(
      onTap: onTap,
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
                      color: AppColors.sleepCyan.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bedtime_rounded,
                      color: AppColors.sleepCyan,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SLEEP & REST',
                    style: AppTypography.labelMedium.copyWith(
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (sleepSession!.dataQuality != SleepDataQuality.measured) ...[
                const SizedBox(height: 8),
                Text(
                  sleepSession!.dataQuality == SleepDataQuality.partial
                      ? '${sleepSession!.unknownMinutes} minutes of the sleep window are unclassified and excluded.'
                      : 'Sleep duration is unavailable because no validated asleep intervals were recorded.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.moderateAmber,
                  ),
                ),
              ],
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textTertiary,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasData) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  sleepSession!.hours.toStringAsFixed(1),
                  style: AppTypography.metricLarge,
                ),
                const SizedBox(width: 4),
                const Text(
                  'hrs',
                  style: TextStyle(
                    color: AppColors.sleepCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TARGET: ${targetHours.toStringAsFixed(1)} hrs',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${((sleepSession!.hours / targetHours) * 100).round()}% Achieved',
                      style: TextStyle(
                        color: sleepSession!.hours >= targetHours
                            ? AppColors.readyGreen
                            : AppColors.moderateAmber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value:
                    (sleepSession!.hours / targetHours).clamp(0.0, 1.25) / 1.25,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.sleepCyan,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 14),
            // Sleep stages breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStageTile(
                  'Deep',
                  sleepSession!.deepMinutes ?? 0,
                  AppColors.sleepCyan,
                ),
                _buildStageTile(
                  'Light',
                  sleepSession!.lightMinutes ?? 0,
                  Colors.blueAccent,
                ),
                _buildStageTile(
                  'REM',
                  sleepSession!.remMinutes ?? 0,
                  Colors.purpleAccent,
                ),
                _buildStageTile(
                  'Awake',
                  sleepSession!.awakeMinutes ?? 0,
                  AppColors.textSecondary,
                ),
              ],
            ),
            if (sleepSession!.consistencyScore != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sync_rounded,
                      size: 14,
                      color: AppColors.sleepCyan,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sleep Consistency: ${sleepSession!.consistencyScore!.round()}%',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.moderateAmber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sleep Record Unavailable',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.moderateAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No sleep session synced from Health Connect. '
                    'Ensure your tracker was worn to sleep, its companion app was synced, '
                    'and Health Connect permissions are active.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStageTile(String label, int minutes, Color color) {
    final hrs = minutes / 60.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.bodySmall),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${hrs.toStringAsFixed(1)}h',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
