import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/recovery_result.dart';
import '../../../widgets/confidence_badge.dart';

class CircularRecoveryGauge extends StatefulWidget {
  final RecoveryResult? recovery;
  final VoidCallback? onTap;

  const CircularRecoveryGauge({super.key, required this.recovery, this.onTap});

  @override
  State<CircularRecoveryGauge> createState() => _CircularRecoveryGaugeState();
}

class _CircularRecoveryGaugeState extends State<CircularRecoveryGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CircularRecoveryGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recovery?.score != widget.recovery?.score) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final recovery = widget.recovery;
    final hasScore = recovery != null && recovery.score != null;
    final int score = recovery?.score ?? 0;
    final category = recovery?.category ?? RecoveryCategory.notEnoughData;
    final accentColor = _getScoreColor(category);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final animatedScore = hasScore
                    ? (score * _animation.value)
                    : 0.0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(240, 240),
                      painter: _GaugePainter(
                        progress: hasScore ? (animatedScore / 100.0) : 0.0,
                        color: accentColor,
                        trackColor: AppColors.surfaceElevated,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'RECOVERY',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              hasScore ? animatedScore.round().toString() : '—',
                              style: const TextStyle(
                                fontSize: 68,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -2.0,
                                color: AppColors.textPrimary,
                                height: 1.0,
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
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category.displayName.toUpperCase(),
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (recovery != null)
            ConfidenceBadge(confidence: recovery.confidence),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _GaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;

    const startAngle = 0.75 * math.pi; // 135 degrees
    const totalSweepAngle = 1.5 * math.pi; // 270 degrees arc

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweepAngle,
      false,
      trackPaint,
    );

    // Draw progress arc if progress > 0
    if (progress > 0) {
      final progressSweep = totalSweepAngle * progress.clamp(0.0, 1.0);

      // Subtle glow shadow behind the active arc
      final glowPaint = Paint()
        ..color = color.withAlpha(70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        glowPaint,
      );

      final activePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
