import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/strain_result.dart';
import '../../../widgets/pulse_card.dart';

class HeartRateZonesCard extends StatelessWidget {
  final StrainResult? strain;
  final int maxHeartRate;

  const HeartRateZonesCard({
    super.key,
    required this.strain,
    required this.maxHeartRate,
  });

  @override
  Widget build(BuildContext context) {
    final zones = strain?.hrZoneMinutes ?? [0, 0, 0, 0, 0];
    final bool hasData = strain?.hasHeartRateData ?? false;
    final int totalMinutes = zones.fold<int>(0, (a, b) => a + b);

    // Calculate BPM thresholds
    final z1Low = (maxHeartRate * 0.50).round();
    final z1High = (maxHeartRate * 0.60).round();
    final z2Low = z1High;
    final z2High = (maxHeartRate * 0.70).round();
    final z3Low = z2High;
    final z3High = (maxHeartRate * 0.80).round();
    final z4Low = z3High;
    final z4High = (maxHeartRate * 0.90).round();
    final z5Low = z4High;
    final z5High = maxHeartRate;

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
                      color: AppColors.heartRatePink.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: AppColors.heartRatePink,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HEART RATE ZONES',
                    style: AppTypography.labelMedium.copyWith(
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'MAX: $maxHeartRate BPM',
                  style: const TextStyle(
                    color: AppColors.limeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Zone Time Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasData
                    ? '$totalMinutes mins total in zones'
                    : '0 mins measured',
                style: AppTypography.bodySmall.copyWith(
                  color: hasData
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!hasData)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NO HR SAMPLES',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Zone Rows
          _buildZoneItem(
            name: 'Zone 5: Anaerobic / Max',
            range: '$z5Low–$z5High BPM (90–100%)',
            minutes: zones[4],
            totalMinutes: totalMinutes,
            color: const Color(0xFFFF0055),
          ),
          const Divider(height: 16),
          _buildZoneItem(
            name: 'Zone 4: Threshold',
            range: '$z4Low–$z4High BPM (80–90%)',
            minutes: zones[3],
            totalMinutes: totalMinutes,
            color: AppColors.strainRed,
          ),
          const Divider(height: 16),
          _buildZoneItem(
            name: 'Zone 3: Aerobic / Tempo',
            range: '$z3Low–$z3High BPM (70–80%)',
            minutes: zones[2],
            totalMinutes: totalMinutes,
            color: AppColors.activityOrange,
          ),
          const Divider(height: 16),
          _buildZoneItem(
            name: 'Zone 2: Aerobic Base',
            range: '$z2Low–$z2High BPM (60–70%)',
            minutes: zones[1],
            totalMinutes: totalMinutes,
            color: AppColors.limeAccent,
          ),
          const Divider(height: 16),
          _buildZoneItem(
            name: 'Zone 1: Active Recovery',
            range: '$z1Low–$z1High BPM (50–60%)',
            minutes: zones[0],
            totalMinutes: totalMinutes,
            color: AppColors.sleepCyan,
          ),

          if (!hasData) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No measured heart-rate samples recorded in Health Connect today. '
                      'Zone intervals reflect your personal thresholds and update when workout HR or continuous samples sync.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneItem({
    required String name,
    required String range,
    required int minutes,
    required int totalMinutes,
    required Color color,
  }) {
    final double fraction = totalMinutes > 0
        ? (minutes / totalMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '${minutes}m',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: minutes > 0 ? color : AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            range,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction > 0 ? fraction : 0.0,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
