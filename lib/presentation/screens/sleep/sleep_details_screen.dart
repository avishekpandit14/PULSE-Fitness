import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/models/sleep_session_model.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/pulse_card.dart';
import '../../widgets/section_header.dart';

class SleepDetailsScreen extends StatelessWidget {
  const SleepDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.profile;
    final sleep = healthProvider.sleepSession;
    final bool hasData = sleep != null && sleep.totalMinutes > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep & Rest Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sleep Overview Card
            PulseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL SLEEP DURATION',
                        style: AppTypography.labelMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: hasData
                              ? AppColors.sleepCyan.withAlpha(30)
                              : AppColors.restCoral.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hasData ? 'SYNCED' : 'UNAVAILABLE',
                          style: TextStyle(
                            color: hasData
                                ? AppColors.sleepCyan
                                : AppColors.restCoral,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (hasData) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          sleep.hours.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'hrs',
                          style: TextStyle(
                            color: AppColors.sleepCyan,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'TARGET: ${user.sleepTargetHours.toStringAsFixed(1)} hrs',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${((sleep.hours / user.sleepTargetHours) * 100).round()}% Met',
                              style: TextStyle(
                                color: sleep.hours >= user.sleepTargetHours
                                    ? AppColors.readyGreen
                                    : AppColors.moderateAmber,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (sleep.dataQuality != SleepDataQuality.measured) ...[
                          const SizedBox(height: 8),
                          Text(
                            sleep.dataQuality == SleepDataQuality.partial
                                ? 'Partial sleep data: ${sleep.unknownMinutes} minutes are unclassified and excluded.'
                                : 'Sleep duration is unavailable because no validated asleep intervals were recorded.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.moderateAmber,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value:
                            (sleep.hours / user.sleepTargetHours).clamp(
                              0.0,
                              1.25,
                            ) /
                            1.25,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.sleepCyan,
                        ),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bedtime: ${PulseDateUtils.formatTime(sleep.startTime)}',
                          style: AppTypography.bodySmall,
                        ),
                        Text(
                          'Wake: ${PulseDateUtils.formatTime(sleep.endTime)}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'No sleep records found in Health Connect for last night.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ensure your tracker companion app is synced and Health Connect synchronization is permitted.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Hypnogram Sleep Stages
            if (hasData) ...[
              const SectionHeader(
                title: 'Sleep Stage Architecture',
                subtitle: 'Deep, Light, REM, and Awake distributions',
              ),
              const SizedBox(height: 8),
              PulseCard(
                child: Column(
                  children: [
                    // Visual stage bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          _buildStageBarSegment(
                            sleep.deepMinutes ?? 0,
                            sleep.totalMinutes,
                            AppColors.sleepCyan,
                          ),
                          _buildStageBarSegment(
                            sleep.lightMinutes ?? 0,
                            sleep.totalMinutes,
                            Colors.blueAccent,
                          ),
                          _buildStageBarSegment(
                            sleep.remMinutes ?? 0,
                            sleep.totalMinutes,
                            Colors.purpleAccent,
                          ),
                          _buildStageBarSegment(
                            sleep.awakeMinutes ?? 0,
                            sleep.totalMinutes,
                            AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStageRow(
                      'Deep Sleep (Physical Repair)',
                      sleep.deepMinutes ?? 0,
                      sleep.totalMinutes,
                      AppColors.sleepCyan,
                    ),
                    const Divider(height: 20),
                    _buildStageRow(
                      'Light Sleep (Core Maintenance)',
                      sleep.lightMinutes ?? 0,
                      sleep.totalMinutes,
                      Colors.blueAccent,
                    ),
                    const Divider(height: 20),
                    _buildStageRow(
                      'REM Sleep (Cognitive Restoration)',
                      sleep.remMinutes ?? 0,
                      sleep.totalMinutes,
                      Colors.purpleAccent,
                    ),
                    const Divider(height: 20),
                    _buildStageRow(
                      'Awake / Disruptions',
                      sleep.awakeMinutes ?? 0,
                      sleep.totalMinutes,
                      AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Sleep Target Configuration
            const SectionHeader(
              title: 'Sleep Target Configuration',
              subtitle:
                  'Recovery algorithm scores relative to your personal target',
            ),
            const SizedBox(height: 8),
            PulseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TARGET DURATION', style: AppTypography.labelMedium),
                      Text(
                        '${user.sleepTargetHours.toStringAsFixed(1)} hrs (${(user.sleepTargetHours * 60).round()} mins)',
                        style: const TextStyle(
                          color: AppColors.limeAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: user.sleepTargetHours,
                    min: 5.5,
                    max: 10.0,
                    divisions: 9,
                    onChanged: (val) {
                      userProvider.updateProfile(
                        user.copyWith(sleepTargetHours: val),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('5.5 hrs', style: AppTypography.bodySmall),
                      Text('7.5 hrs (Nominal)', style: AppTypography.bodySmall),
                      Text('10.0 hrs', style: AppTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PULSE scoring rewards meeting 100%–110% of this target. '
                    'Oversleeping significantly beyond 125% of your target does not reward unlimited points, '
                    'reflecting the lethargy and circadian disruption of overextended bed rest.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
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

  Widget _buildStageBarSegment(int minutes, int total, Color color) {
    final double flex = (minutes / (total > 0 ? total : 1)).clamp(0.05, 1.0);
    return Expanded(
      flex: (flex * 100).round(),
      child: Container(height: 16, color: color),
    );
  }

  Widget _buildStageRow(String name, int minutes, int total, Color color) {
    final hrs = minutes / 60.0;
    final pct = total > 0 ? ((minutes / total) * 100).round() : 0;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          '${hrs.toStringAsFixed(1)}h ($pct%)',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
