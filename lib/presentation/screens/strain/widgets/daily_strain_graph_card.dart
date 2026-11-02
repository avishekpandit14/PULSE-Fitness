import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/strain_result.dart';
import '../../../widgets/pulse_card.dart';

class DailyStrainGraphCard extends StatelessWidget {
  final StrainResult? strain;

  const DailyStrainGraphCard({super.key, required this.strain});

  @override
  Widget build(BuildContext context) {
    final progression = strain?.dailyProgression ?? [];
    final double currentScore = strain?.score ?? 0.0;

    // Convert progression points to FlSpots
    // X will be hours since midnight (0.0 to 24.0)
    final spots = <FlSpot>[];

    if (progression.isNotEmpty) {
      for (final p in progression) {
        final hours = p.timestamp.hour + (p.timestamp.minute / 60.0);
        spots.add(FlSpot(hours, p.score.clamp(0.0, 21.0)));
      }
    } else {
      // Minimal baseline if empty
      spots.add(const FlSpot(6.0, 0.0));
      spots.add(FlSpot(12.0, (currentScore * 0.5).clamp(0.0, 21.0)));
      spots.add(
        FlSpot(
          DateTime.now().hour.toDouble().clamp(6.0, 23.0),
          currentScore.clamp(0.0, 21.0),
        ),
      );
    }

    // Ensure spots are sorted by X
    spots.sort((a, b) => a.x.compareTo(b.x));

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
                      Icons.timeline_rounded,
                      color: AppColors.strainRed,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DAILY STRAIN ACCUMULATION',
                    style: AppTypography.labelMedium.copyWith(
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                'Current: ${currentScore.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: AppColors.strainRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cumulative logarithmic curve based on actual activity timestamps throughout today.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Line Chart
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minX: 6.0, // 6 AM
                maxX: 24.0, // Midnight
                minY: 0.0,
                maxY: 21.0,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final hourInt = spot.x.floor();
                        final minInt = ((spot.x - hourInt) * 60).round();
                        final time = DateTime(2026, 1, 1, hourInt, minInt);
                        final timeStr = DateFormat('h:mm a').format(time);
                        return LineTooltipItem(
                          '$timeStr\n${spot.y.toStringAsFixed(1)} Strain',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 7.0,
                  getDrawingHorizontalLine: (val) =>
                      FlLine(color: AppColors.borderSubtle, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4.0,
                      reservedSize: 24,
                      getTitlesWidget: (val, meta) {
                        switch (val.toInt()) {
                          case 6:
                            return _buildAxisTitle('6 AM');
                          case 10:
                            return _buildAxisTitle('10 AM');
                          case 14:
                            return _buildAxisTitle('2 PM');
                          case 18:
                            return _buildAxisTitle('6 PM');
                          case 22:
                            return _buildAxisTitle('10 PM');
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 7.0,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        if (val == 0.0 ||
                            val == 7.0 ||
                            val == 14.0 ||
                            val == 21.0) {
                          return Text(
                            val.toInt().toString(),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.strainRed,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.strainRed.withAlpha(50),
                          AppColors.strainRed.withAlpha(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxisTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
