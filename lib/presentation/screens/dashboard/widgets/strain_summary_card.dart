import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/strain_result.dart';
import '../../../widgets/pulse_card.dart';

class StrainSummaryCard extends StatelessWidget {
  final StrainResult? strain;
  final VoidCallback onTap;

  const StrainSummaryCard({
    super.key,
    required this.strain,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double score = strain?.score ?? 0.0;
    final int activeCalories = strain?.activeCalories ?? 0;
    final int steps = strain?.steps ?? 0;
    final int workouts = strain?.workoutCount ?? 0;
    final weekly = strain?.weeklyDailyLoads ?? const <double>[];

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
                      color: AppColors.strainRed.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.strainRed,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DAILY STRAIN & LOAD',
                    style: AppTypography.labelMedium.copyWith(
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textTertiary,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: AppTypography.metricLarge.copyWith(
                  color: AppColors.strainRed,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ 21.0',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.strainRed.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  strain?.category.displayName.toUpperCase() ?? 'LIGHT STRAIN',
                  style: const TextStyle(
                    color: AppColors.strainRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 7-day mini trend bar chart
          SizedBox(
            height: 70,
            child: BarChart(
              BarChartData(
                maxY: 21.0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final idx = val.toInt();
                        if (idx >= 0 && idx < days.length) {
                          return Text(
                            days[idx],
                            style: TextStyle(
                              color: idx == 6
                                  ? AppColors.strainRed
                                  : AppColors.textTertiary,
                              fontSize: 10,
                              fontWeight: idx == 6
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(weekly.length, (i) {
                  final isToday = i == weekly.length - 1;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weekly[i].clamp(1.0, 21.0),
                        color: isToday
                            ? AppColors.strainRed
                            : AppColors.strainRed.withAlpha(90),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Metrics summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                Icons.fitness_center_rounded,
                '$workouts Workouts',
              ),
              _buildMiniMetric(
                Icons.local_fire_department_rounded,
                '$activeCalories Active kcal',
              ),
              _buildMiniMetric(Icons.directions_walk_rounded, '$steps Steps'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Notice: Strain calculation is an algorithmic physiological load estimate, not an official WHOOP or Athlytic score.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
