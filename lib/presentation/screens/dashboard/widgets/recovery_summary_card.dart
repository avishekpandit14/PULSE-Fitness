import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/recovery_result.dart';
import '../../../widgets/pulse_card.dart';

class RecoverySummaryCard extends StatelessWidget {
  final RecoveryResult? recovery;
  final VoidCallback onTap;

  const RecoverySummaryCard({
    super.key,
    required this.recovery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore = recovery != null && recovery!.score != null;
    final explanation =
        recovery?.shortExplanation ??
        'Health Connect sleep records or a daily check-in are needed to compute recovery.';

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
                      color: AppColors.limeAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppColors.limeAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECOVERY ANALYSIS',
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
          const SizedBox(height: 12),
          Text(
            explanation,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // Signals indicator
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSignalPill(
                label: 'HRV-Free Formula',
                isActive: true,
                color: AppColors.limeAccent,
              ),
              _buildSignalPill(
                label: hasScore
                    ? '${recovery!.availableSignals.length} Active Signals'
                    : 'Awaiting Telemetry',
                isActive: hasScore,
                color: hasScore ? AppColors.readyGreen : AppColors.restCoral,
              ),
              if (recovery != null && recovery!.baselineRhr != null)
                _buildSignalPill(
                  label: 'Baseline: ${recovery!.baselineRhr!.round()} bpm',
                  isActive: true,
                  color: AppColors.sleepCyan,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalPill({
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
