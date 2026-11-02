import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/models/recovery_result.dart';

class ConfidenceBadge extends StatelessWidget {
  final ConfidenceLevel confidence;

  const ConfidenceBadge({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (confidence) {
      case ConfidenceLevel.high:
        bg = AppColors.readyGreen.withAlpha(40);
        text = AppColors.readyGreen;
        label = 'HIGH CONFIDENCE';
        break;
      case ConfidenceLevel.moderate:
        bg = AppColors.moderateAmber.withAlpha(40);
        text = AppColors.moderateAmber;
        label = 'MODERATE CONFIDENCE';
        break;
      case ConfidenceLevel.low:
        bg = AppColors.restCoral.withAlpha(40);
        text = AppColors.restCoral;
        label = 'LOW CONFIDENCE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: text, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
