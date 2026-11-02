import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/pulse_card.dart';
import '../../widgets/section_header.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();
    final userProvider = context.watch<UserProvider>();
    final isDemo = userProvider.isDemoMode;

    final recoveryScores = isDemo
        ? [74, 82, 65, 88, 58, 86, (healthProvider.recovery?.score ?? 84)]
        : [70, 75, 68, 80, 62, 78, (healthProvider.recovery?.score ?? 72)];

    final strainScores =
        healthProvider.strain?.weeklyDailyLoads ?? const <double>[];

    final avgRecovery =
        recoveryScores.fold(0, (a, b) => a + b) / recoveryScores.length;
    final avgStrain = strainScores.isEmpty
        ? 0.0
        : strainScores.fold(0.0, (a, b) => a + b) / strainScores.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Trends & Performance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rolling Averages
            Row(
              children: [
                Expanded(
                  child: PulseCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '7-DAY AVG RECOVERY',
                          style: AppTypography.labelMedium,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              avgRecovery.round().toString(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.limeAccent,
                              ),
                            ),
                            const Text(
                              '%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.limeAccent,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Optimal adaptation zone',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PulseCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '7-DAY AVG STRAIN',
                          style: AppTypography.labelMedium,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              avgStrain.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.strainRed,
                              ),
                            ),
                            const Text(
                              ' / 21',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Steady acute volume',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weekly Recovery Trend Line Chart
            const SectionHeader(
              title: '7-Day Recovery Progression',
              subtitle: 'Daily readiness fluctuations',
            ),
            const SizedBox(height: 8),
            PulseCard(
              child: Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 100,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (val) => FlLine(
                            color: AppColors.borderSubtle,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                const days = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Today',
                                ];
                                final idx = val.toInt();
                                if (idx >= 0 && idx < days.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      days[idx],
                                      style: TextStyle(
                                        color: idx == 6
                                            ? AppColors.limeAccent
                                            : AppColors.textTertiary,
                                        fontSize: 10,
                                        fontWeight: idx == 6
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (val, meta) {
                                if (val == 0 || val == 50 || val == 100) {
                                  return Text(
                                    '${val.toInt()}%',
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
                            spots: List.generate(
                              recoveryScores.length,
                              (i) => FlSpot(
                                i.toDouble(),
                                recoveryScores[i].toDouble(),
                              ),
                            ),
                            isCurved: true,
                            color: AppColors.limeAccent,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.limeAccent.withAlpha(25),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Strain vs Recovery Balance Overlay Chart
            const SectionHeader(
              title: 'Strain vs Recovery Balance',
              subtitle: 'Supercompensation & load management',
            ),
            const SizedBox(height: 8),
            PulseCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildChartLegend(AppColors.limeAccent, 'Recovery (%)'),
                      const SizedBox(width: 14),
                      _buildChartLegend(
                        AppColors.strainRed,
                        'Strain (scaled x4.7)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 100,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (val) => FlLine(
                            color: AppColors.borderSubtle,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                const days = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Today',
                                ];
                                final idx = val.toInt();
                                if (idx >= 0 && idx < days.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      days[idx],
                                      style: const TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 10,
                                      ),
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
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // Recovery
                          LineChartBarData(
                            spots: List.generate(
                              recoveryScores.length,
                              (i) => FlSpot(
                                i.toDouble(),
                                recoveryScores[i].toDouble(),
                              ),
                            ),
                            isCurved: true,
                            color: AppColors.limeAccent,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                          ),
                          // Strain normalized to 0-100 (21.0 -> 100)
                          LineChartBarData(
                            spots: List.generate(
                              strainScores.length,
                              (i) => FlSpot(
                                i.toDouble(),
                                (strainScores[i] / 21.0 * 100.0).clamp(
                                  0.0,
                                  100.0,
                                ),
                              ),
                            ),
                            isCurved: true,
                            color: AppColors.strainRed,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
