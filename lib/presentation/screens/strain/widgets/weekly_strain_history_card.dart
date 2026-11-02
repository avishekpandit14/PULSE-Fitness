import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/strain_result.dart';
import '../../../widgets/pulse_card.dart';

class WeeklyStrainHistoryCard extends StatelessWidget {
  final StrainResult? strain;

  const WeeklyStrainHistoryCard({super.key, required this.strain});

  @override
  Widget build(BuildContext context) {
    // Ensure we have exactly 7 days of loads ending today
    final rawLoads = strain?.weeklyDailyLoads ?? [];
    final currentScore = strain?.score ?? 0.0;

    List<double> loads = List<double>.from(rawLoads);
    if (loads.isEmpty) {
      loads = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, currentScore];
    } else if (loads.length < 7) {
      final padCount = 7 - loads.length;
      loads = [...List.filled(padCount, 0.0), ...loads];
    } else if (loads.length > 7) {
      loads = loads.sublist(loads.length - 7);
    }
    // Make sure today's latest is reflected in the last element
    loads[6] = currentScore;

    final double avgStrain = loads.isNotEmpty
        ? loads.reduce((a, b) => a + b) / loads.length
        : 0.0;
    final double maxStrain = loads.isNotEmpty
        ? loads.reduce((a, b) => a > b ? a : b)
        : 0.0;

    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateFormat('E').format(date); // Mon, Tue, etc.
    });

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
                      Icons.bar_chart_rounded,
                      color: AppColors.strainRed,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '7-DAY STRAIN HISTORY',
                    style: AppTypography.labelMedium.copyWith(
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // 7-day average pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle, width: 1),
                ),
                child: Text(
                  'AVG: ${avgStrain.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bar Chart
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 21.0,
                minY: 0.0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceElevated,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isToday = groupIndex == 6;
                      final label = isToday ? 'Today' : dayLabels[groupIndex];
                      return BarTooltipItem(
                        '$label\n',
                        const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toStringAsFixed(1)} Strain',
                            style: TextStyle(
                              color: isToday
                                  ? AppColors.strainRed
                                  : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 7,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        final isToday = index == 6;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            isToday ? 'Today' : dayLabels[index],
                            style: TextStyle(
                              color: isToday
                                  ? AppColors.strainRed
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 7,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderSubtle.withAlpha(60),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final isToday = index == 6;
                  final val = loads[index].clamp(0.0, 21.0);

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        width: 16,
                        color: isToday
                            ? AppColors.strainRed
                            : (val > 14.0
                                  ? AppColors.strainRed.withAlpha(160)
                                  : AppColors.textSecondary.withAlpha(120)),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 21.0,
                          color: AppColors.surfaceElevated.withAlpha(80),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 7-day stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withAlpha(120),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.borderSubtle.withAlpha(80),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('7-Day Avg', avgStrain.toStringAsFixed(1)),
                Container(height: 24, width: 1, color: AppColors.borderSubtle),
                _buildStatItem('Peak Day', maxStrain.toStringAsFixed(1)),
                Container(height: 24, width: 1, color: AppColors.borderSubtle),
                _buildStatItem(
                  'Acute Load',
                  strain?.acuteLoad.toStringAsFixed(1) ?? '--',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
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
