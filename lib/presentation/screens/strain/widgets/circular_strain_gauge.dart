import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/models/strain_result.dart';

class CircularStrainGauge extends StatefulWidget {
  final StrainResult? strain;
  final VoidCallback? onTap;

  const CircularStrainGauge({super.key, required this.strain, this.onTap});

  @override
  State<CircularStrainGauge> createState() => _CircularStrainGaugeState();
}

class _CircularStrainGaugeState extends State<CircularStrainGauge>
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
  void didUpdateWidget(covariant CircularStrainGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.strain?.score != widget.strain?.score) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getCategoryColor(StrainCategory category) {
    switch (category) {
      case StrainCategory.restorative:
        return AppColors.sleepCyan;
      case StrainCategory.low:
        return AppColors.limeAccent;
      case StrainCategory.moderate:
        return AppColors.moderateAmber;
      case StrainCategory.high:
        return AppColors.strainRed;
      case StrainCategory.allOut:
        return const Color(0xFFFF0055);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strain = widget.strain;
    final double score = strain?.score ?? 0.0;
    final category = strain?.category ?? StrainCategory.restorative;
    final accentColor = _getCategoryColor(category);
    final now = DateTime.now();

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          // Current Date Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: AppColors.limeAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  PulseDateUtils.formatFullDate(now),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Large Circular Gauge
          SizedBox(
            width: 250,
            height: 250,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final animatedScore = score * _animation.value;
                final progress = (animatedScore / 21.0).clamp(0.0, 1.0);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(250, 250),
                      painter: _StrainArcPainter(
                        progress: progress,
                        color: accentColor,
                        trackColor: AppColors.surfaceElevated,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'DAILY STRAIN',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                animatedScore.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.5,
                                  color: AppColors.textPrimary,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '/21',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accentColor.withAlpha(70),
                              width: 1,
                            ),
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
        ],
      ),
    );
  }
}

class _StrainArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _StrainArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 28) / 2;

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

    // Draw active progress arc if progress > 0
    if (progress > 0) {
      final progressSweep = totalSweepAngle * progress.clamp(0.0, 1.0);

      // Subtle glow shadow behind the active arc
      final glowPaint = Paint()
        ..color = color.withAlpha(65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

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
  bool shouldRepaint(covariant _StrainArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
