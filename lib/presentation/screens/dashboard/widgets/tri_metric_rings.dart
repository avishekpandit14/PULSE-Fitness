import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/recovery_result.dart';
import '../../../../domain/models/sleep_session_model.dart';
import '../../../../domain/models/strain_result.dart';

/// The three headline rings: sleep performance, recovery and strain.
///
/// Each ring is tappable and opens its own detail screen, which replaces the
/// separate summary cards the dashboard used to stack.
class TriMetricRings extends StatelessWidget {
  final RecoveryResult? recovery;
  final StrainResult? strain;
  final SleepSessionModel? sleepSession;
  final double targetHours;
  final VoidCallback onSleepTap;
  final VoidCallback onRecoveryTap;
  final VoidCallback onStrainTap;

  const TriMetricRings({
    super.key,
    required this.recovery,
    required this.strain,
    required this.sleepSession,
    required this.targetHours,
    required this.onSleepTap,
    required this.onRecoveryTap,
    required this.onStrainTap,
  });

  @override
  Widget build(BuildContext context) {
    final sleepMinutes = sleepSession?.totalMinutes ?? 0;
    final hasSleep = sleepMinutes > 0 && targetHours > 0;
    final sleepPercent = hasSleep
        ? ((sleepMinutes / (targetHours * 60)) * 100).round().clamp(0, 100)
        : null;

    final recoveryScore = recovery?.score;
    final strainScore = strain?.score;

    return Row(
      children: [
        Expanded(
          child: _RingColumn(
            label: 'SLEEP',
            value: sleepPercent?.toString() ?? '—',
            unit: sleepPercent == null ? null : '%',
            progress: (sleepPercent ?? 0) / 100.0,
            color: AppColors.sleepCyan,
            onTap: onSleepTap,
          ),
        ),
        Expanded(
          child: _RingColumn(
            label: 'RECOVERY',
            value: recoveryScore?.toString() ?? '—',
            unit: recoveryScore == null ? null : '%',
            progress: (recoveryScore ?? 0) / 100.0,
            color: _recoveryColor(recovery?.category),
            onTap: onRecoveryTap,
          ),
        ),
        Expanded(
          child: _RingColumn(
            label: 'STRAIN',
            value: strainScore == null ? '—' : strainScore.toStringAsFixed(1),
            unit: null,
            progress: (strainScore ?? 0) / 21.0,
            color: _strainColor(strain?.category),
            onTap: onStrainTap,
          ),
        ),
      ],
    );
  }

  static Color _recoveryColor(RecoveryCategory? category) {
    switch (category) {
      case RecoveryCategory.ready:
        return AppColors.readyGreen;
      case RecoveryCategory.moderate:
        return AppColors.moderateAmber;
      case RecoveryCategory.restRecommended:
        return AppColors.restCoral;
      case RecoveryCategory.notEnoughData:
      case null:
        return AppColors.textTertiary;
    }
  }

  static Color _strainColor(StrainCategory? category) {
    switch (category) {
      case StrainCategory.restorative:
        return AppColors.textSecondary;
      case StrainCategory.low:
        return AppColors.sleepCyan;
      case StrainCategory.moderate:
        return AppColors.limeAccent;
      case StrainCategory.high:
        return AppColors.activityOrange;
      case StrainCategory.allOut:
        return AppColors.restCoral;
      case null:
        return AppColors.textTertiary;
    }
  }
}

class _RingColumn extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final double progress;
  final Color color;
  final VoidCallback onTap;

  const _RingColumn({
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, animated, child) => CustomPaint(
                painter: _RingPainter(progress: animated, color: color),
                child: child,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.0,
                        ),
                      ),
                      if (unit != null)
                        Text(
                          unit!,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 12,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    final track = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;

    final glow = Paint()
      ..color = color.withAlpha(70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(rect, start, 2 * math.pi * progress, false, glow);

    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, start, 2 * math.pi * progress, false, active);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
