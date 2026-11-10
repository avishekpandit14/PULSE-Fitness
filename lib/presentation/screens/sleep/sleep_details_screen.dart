import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/algorithms/nighttime_heart_rate_analyzer.dart';
import '../../../domain/models/sleep_session_model.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/confidence_badge.dart';
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
    final night = healthProvider.sleepNight;
    final quality = healthProvider.sleepQuality;
    final nightHr = healthProvider.nightHeartRate;

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
                    // Visual stage bar. Unreported stages are omitted entirely
                    // so the remaining segments keep their real proportions.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          if (sleep.deepMinutes != null)
                            _buildStageBarSegment(
                              sleep.deepMinutes!,
                              sleep.totalMinutes,
                              AppColors.sleepCyan,
                            ),
                          if (sleep.lightMinutes != null)
                            _buildStageBarSegment(
                              sleep.lightMinutes!,
                              sleep.totalMinutes,
                              Colors.blueAccent,
                            ),
                          if (sleep.remMinutes != null)
                            _buildStageBarSegment(
                              sleep.remMinutes!,
                              sleep.totalMinutes,
                              Colors.purpleAccent,
                            ),
                          if (sleep.awakeMinutes != null)
                            _buildStageBarSegment(
                              sleep.awakeMinutes!,
                              sleep.totalMinutes,
                              AppColors.textSecondary,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStageRow(
                      'Deep Sleep (Physical Repair)',
                      sleep.deepMinutes,
                      sleep.totalMinutes,
                      AppColors.sleepCyan,
                    ),
                    const Divider(height: 20),
                    _buildStageRow(
                      'Light Sleep (Core Maintenance)',
                      sleep.lightMinutes,
                      sleep.totalMinutes,
                      Colors.blueAccent,
                    ),
                    const Divider(height: 20),
                    _buildStageRow(
                      'REM Sleep (Cognitive Restoration)',
                      sleep.remMinutes,
                      sleep.totalMinutes,
                      Colors.purpleAccent,
                    ),
                    const Divider(height: 20),
                    _buildStageRow(
                      'Awake / Disruptions',
                      sleep.awakeMinutes,
                      sleep.totalMinutes,
                      AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Naps and additional sleep periods
            if (hasData && night.hasNaps) ...[
              const SectionHeader(
                title: 'Naps & Additional Sleep',
                subtitle: 'Reported separately from the primary night',
              ),
              const SizedBox(height: 8),
              PulseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${night.napMinutes} min of naps recorded today. Naps are '
                      'shown for information only: they never replace, inflate or '
                      'reduce your nighttime sleep score.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...night.naps.map(
                      (nap) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.self_improvement_rounded,
                              size: 16,
                              color: AppColors.sleepCyan,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${PulseDateUtils.formatTime(nap.startTime)} – '
                                '${PulseDateUtils.formatTime(nap.endTime)}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '${nap.minutes} min',
                              style: const TextStyle(
                                color: AppColors.sleepCyan,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
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
            ],

            // Sleep quality (stages + efficiency, not duration)
            if (hasData && quality != null) ...[
              const SectionHeader(
                title: 'Sleep Quality',
                subtitle:
                    'Stage composition and efficiency — scored independently '
                    'of total duration',
              ),
              const SizedBox(height: 8),
              PulseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUALITY SCORE',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              quality.score == null
                                  ? 'Unavailable'
                                  : '${quality.score!.round()}/100',
                              style: AppTypography.titleMedium.copyWith(
                                color: quality.score == null
                                    ? AppColors.textTertiary
                                    : AppColors.sleepCyan,
                                fontSize: 26,
                              ),
                            ),
                          ],
                        ),
                        ConfidenceBadge(confidence: quality.confidence),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStat(
                          'Efficiency',
                          quality.efficiency == null
                              ? 'Unavailable'
                              : '${(quality.efficiency! * 100).round()}%',
                        ),
                        _buildStat(
                          'Deep',
                          quality.deepRatio == null
                              ? 'Unavailable'
                              : '${(quality.deepRatio! * 100).round()}%',
                        ),
                        _buildStat(
                          'REM',
                          quality.remRatio == null
                              ? 'Unavailable'
                              : '${(quality.remRatio! * 100).round()}%',
                        ),
                        _buildStat(
                          'Awake',
                          sleep.awakeMinutes == null
                              ? 'Unavailable'
                              : '${sleep.awakeMinutes} min',
                        ),
                      ],
                    ),
                    if (quality.missingFactors.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...quality.missingFactors.map(
                        (factor) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 13,
                                color: AppColors.moderateAmber,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  factor,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.moderateAmber,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Reference bands used for the stage scores are heuristic '
                      'and shown in the app for transparency; they are not '
                      'clinical thresholds. Missing stages are excluded from the '
                      'score and lower confidence instead of counting as zero.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Nighttime heart rate (BPM samples only, no HRV)
            if (hasData && nightHr != null) ...[
              const SectionHeader(
                title: 'Nighttime Heart Rate',
                subtitle:
                    'From overnight BPM samples only — HRV is never inferred',
              ),
              const SizedBox(height: 8),
              PulseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nightHr.hasUsableData) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildStat(
                            'Average',
                            '${nightHr.averageBpm!.round()} bpm',
                          ),
                          _buildStat(
                            'Lowest',
                            nightHr.lowestBpm == null
                                ? 'Unavailable'
                                : '${nightHr.lowestBpm!.round()} bpm',
                          ),
                          _buildStat(
                            'Highest (p95)',
                            nightHr.highestBpm == null
                                ? 'Unavailable'
                                : '${nightHr.highestBpm!.round()} bpm',
                          ),
                          _buildStat(
                            'Stability',
                            nightHr.stabilityScore == null
                                ? 'Unavailable'
                                : '${nightHr.stabilityScore!.round()}%',
                          ),
                          _buildStat(
                            'Trend',
                            _trendLabel(nightHr.trendDeltaBpm),
                          ),
                          _buildStat(
                            'Coverage',
                            nightHr.coverage == null
                                ? 'Unavailable'
                                : '${(nightHr.coverage! * 100).round()}%',
                          ),
                          _buildStat(
                            'Your baseline',
                            nightHr.hasBaseline
                                ? '${nightHr.baselineBpm!.round()} bpm '
                                      '(${nightHr.baselineNightCount} nights)'
                                : 'Not established '
                                      '(${nightHr.baselineNightCount}/'
                                      '${NighttimeHeartRateAnalyzer.minBaselineNights} nights)',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nightHr.hasBaseline
                            ? 'Compared with your own nightly average of '
                                  '${nightHr.baselineBpm!.round()} bpm, not with '
                                  'an absolute target. Stability describes the spread '
                                  'of sampled BPM values and is not HRV.'
                            : 'Nighttime HR is not scored yet: a personal baseline '
                                  'needs at least three nights. Absolute heart rate '
                                  'values are never treated as good or bad on their own.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Nighttime heart rate unavailable: '
                        '${nightHr.sampleCount} usable sample'
                        '${nightHr.sampleCount == 1 ? '' : 's'} inside the sleep '
                        'window. No values are estimated or invented.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.moderateAmber,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (nightHr.limitations.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...nightHr.limitations.map(
                        (limitation) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 13,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  limitation,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.labelMedium.copyWith(
              fontSize: 9,
              color: AppColors.textTertiary,
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
      ),
    );
  }

  String _trendLabel(double? delta) {
    if (delta == null) return 'Unavailable';
    if (delta <= -1) return 'Falling ${delta.abs().round()} bpm';
    if (delta >= 1) return 'Rising +${delta.round()} bpm';
    return 'Flat';
  }

  Widget _buildStageBarSegment(int minutes, int total, Color color) {
    final double flex = (minutes / (total > 0 ? total : 1)).clamp(0.05, 1.0);
    return Expanded(
      flex: (flex * 100).round(),
      child: Container(height: 16, color: color),
    );
  }

  Widget _buildStageRow(String name, int? minutes, int total, Color color) {
    final pct = minutes != null && total > 0
        ? ((minutes / total) * 100).round()
        : null;
    final value = minutes == null
        ? 'Unavailable'
        : '${(minutes / 60.0).toStringAsFixed(1)}h ($pct%)';

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
          value,
          style: TextStyle(
            color: minutes == null
                ? AppColors.textTertiary
                : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
