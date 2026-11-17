import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/algorithms/sleep_quality_analyzer.dart';
import '../../../widgets/pulse_card.dart';

/// Two compact status cards that sit side by side, like a quick health readout.
class SleepMonitorCard extends StatelessWidget {
  final SleepQualityResult? quality;
  final int napMinutes;
  final VoidCallback onTap;

  const SleepMonitorCard({
    super.key,
    required this.quality,
    required this.napMinutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String status;
    final String detail;

    final score = quality?.score;
    if (score == null) {
      color = AppColors.textTertiary;
      status = 'NO STAGE DATA';
      detail = 'Awaiting sleep stages';
    } else if (score >= 75) {
      color = AppColors.readyGreen;
      status = 'GOOD QUALITY';
      detail = _stageDetail(quality!);
    } else if (score >= 55) {
      color = AppColors.moderateAmber;
      status = 'FAIR QUALITY';
      detail = _stageDetail(quality!);
    } else {
      color = AppColors.restCoral;
      status = 'LOW QUALITY';
      detail = _stageDetail(quality!);
    }

    return _MonitorCard(
      title: 'SLEEP MONITOR',
      color: color,
      status: status,
      detail: napMinutes > 0 ? '$detail · ${napMinutes}m nap' : detail,
      onTap: onTap,
    );
  }

  static String _stageDetail(SleepQualityResult quality) {
    final score = quality.score?.round();
    final deepRem = (quality.deepRatio != null && quality.remRatio != null)
        ? 'Deep+REM ${((quality.deepRatio! + quality.remRatio!) * 100).round()}%'
        : (quality.efficiency != null
              ? 'Efficiency ${(quality.efficiency! * 100).round()}%'
              : 'Limited stage data');
    return score == null ? deepRem : '$score/100 · $deepRem';
  }
}

class HeartMonitorCard extends StatelessWidget {
  final double? restingHeartRate;
  final double? baselineRhr;
  final VoidCallback onTap;

  const HeartMonitorCard({
    super.key,
    required this.restingHeartRate,
    required this.baselineRhr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String status;
    // Assigned once per branch, but the elevated/below wording refines it.
    String detail;

    final rhr = restingHeartRate;
    final baseline = baselineRhr;

    if (rhr == null) {
      color = AppColors.textTertiary;
      status = 'NO DATA';
      detail = 'No resting HR record';
    } else if (baseline == null) {
      color = AppColors.textSecondary;
      status = 'BASELINE PENDING';
      detail = '${rhr.round()} bpm today';
    } else {
      final delta = (rhr - baseline).round();
      detail = '${rhr.round()} vs ${baseline.round()} bpm';
      if (delta.abs() <= 2) {
        color = AppColors.readyGreen;
        status = 'WITHIN RANGE';
      } else if (delta > 2) {
        color = AppColors.restCoral;
        status = 'ELEVATED';
        detail = '${rhr.round()} vs ${baseline.round()} bpm (+$delta)';
      } else {
        color = AppColors.sleepCyan;
        status = 'BELOW BASELINE';
        detail = '${rhr.round()} vs ${baseline.round()} bpm ($delta)';
      }
    }

    return _MonitorCard(
      title: 'HEART MONITOR',
      color: color,
      status: status,
      detail: detail,
      onTap: onTap,
    );
  }
}

class _MonitorCard extends StatelessWidget {
  final String title;
  final Color color;
  final String status;
  final String detail;
  final VoidCallback onTap;

  const _MonitorCard({
    required this.title,
    required this.color,
    required this.status,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 11, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
