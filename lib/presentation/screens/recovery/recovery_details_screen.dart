import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/models/recovery_result.dart';
import '../../providers/health_provider.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/pulse_card.dart';
import '../../widgets/section_header.dart';

class RecoveryDetailsScreen extends StatelessWidget {
  const RecoveryDetailsScreen({super.key});

  Color _getScoreColor(RecoveryCategory category) {
    switch (category) {
      case RecoveryCategory.ready:
        return AppColors.limeAccent;
      case RecoveryCategory.moderate:
        return AppColors.moderateAmber;
      case RecoveryCategory.restRecommended:
        return AppColors.restCoral;
      case RecoveryCategory.notEnoughData:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();
    final recovery = healthProvider.recovery;

    final hasScore = recovery != null && recovery.score != null;
    final int score = recovery?.score ?? 0;
    final category = recovery?.category ?? RecoveryCategory.notEnoughData;
    final accentColor = _getScoreColor(category);

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Deep Dive')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Overview Card
            PulseCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESTIMATED RECOVERY',
                            style: AppTypography.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                hasScore ? '$score' : '—',
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (hasScore)
                                Text(
                                  '%',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category.displayName.toUpperCase(),
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      if (recovery != null)
                        ConfidenceBadge(confidence: recovery.confidence),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    recovery?.detailedExplanation ??
                        'Connect Health Connect and record sleep or check-in to generate recovery insights.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Component Breakdown
            const SectionHeader(
              title: 'Telemetry Component Breakdown',
              subtitle: 'Heuristic weights re-normalized across active signals',
            ),
            const SizedBox(height: 8),

            if (recovery != null && recovery.componentScores.isNotEmpty) ...[
              ...recovery.componentScores.entries.map((entry) {
                final String name = entry.key;
                final double compScore = entry.value;
                final double effectiveWeight =
                    (recovery.componentWeights[name] ?? 0.0) * 100.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PulseCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: AppTypography.titleSmall),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Weight: ${effectiveWeight.round()}%',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${compScore.round()}/100',
                                  style: TextStyle(
                                    color: compScore >= 67
                                        ? AppColors.readyGreen
                                        : (compScore >= 34
                                              ? AppColors.moderateAmber
                                              : AppColors.restCoral),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (compScore / 100.0).clamp(0.0, 1.0),
                            backgroundColor: AppColors.surfaceElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              compScore >= 67
                                  ? AppColors.readyGreen
                                  : (compScore >= 34
                                        ? AppColors.moderateAmber
                                        : AppColors.restCoral),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else ...[
              PulseCard(
                child: Text(
                  'No component signals currently scored. Complete your daily check-in or sync Health Connect sleep.',
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Resting Heart Rate Baseline Tracker
            const SectionHeader(
              title: 'Personal Resting HR Baseline',
              subtitle: 'Multi-day moving calibration',
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
                            'ESTABLISHED BASELINE',
                            style: AppTypography.labelMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            recovery?.baselineRhr != null
                                ? '${recovery!.baselineRhr!.round()} bpm'
                                : 'Pending Calibration',
                            style: AppTypography.titleMedium.copyWith(
                              color: recovery?.baselineRhr != null
                                  ? AppColors.sleepCyan
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'OBSERVATIONS',
                            style: AppTypography.labelMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${recovery?.rhrObservationsCount ?? 0} / 3 days minimum',
                            style: AppTypography.titleSmall.copyWith(
                              color: (recovery?.rhrObservationsCount ?? 0) >= 3
                                  ? AppColors.readyGreen
                                  : AppColors.moderateAmber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PULSE never uses a single isolated resting heart rate as a personal baseline. '
                    'A valid personal baseline requires at least 3 distinct days of resting telemetry to account for day-to-day variance. '
                    'If a baseline is not yet established, the RHR signal is omitted and other signals are re-normalized.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Available vs Missing Signals
            const SectionHeader(title: 'Signal Availability Audit'),
            const SizedBox(height: 8),
            PulseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AVAILABLE SIGNALS:', style: AppTypography.labelMedium),
                  const SizedBox(height: 6),
                  if (recovery != null && recovery.availableSignals.isNotEmpty)
                    ...recovery.availableSignals.map(
                      (s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 14,
                              color: AppColors.readyGreen,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      'None detected yet today',
                      style: AppTypography.bodySmall,
                    ),
                  const SizedBox(height: 14),
                  Text('MISSING SIGNALS:', style: AppTypography.labelMedium),
                  const SizedBox(height: 6),
                  if (recovery != null && recovery.missingSignals.isNotEmpty)
                    ...recovery.missingSignals.map(
                      (s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.remove_circle_outline_rounded,
                              size: 14,
                              color: AppColors.moderateAmber,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      'All primary telemetry signals available',
                      style: AppTypography.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Scientific & Limitation Transparency
            PulseCard(
              backgroundColor: AppColors.surfaceElevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.limeAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ALGORITHM LIMITATIONS',
                        style: AppTypography.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PULSE uses a deterministic, transparent formula for Health Connect-compatible trackers, '
                    'including devices that do not expose nocturnal HRV (RMSSD/SDNN). '
                    'While highly correlated with physical readiness, it is a heuristic model and not a medically validated diagnostic tool. '
                    'Never use this app to diagnose illness or override severe physical pain.',
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
}
