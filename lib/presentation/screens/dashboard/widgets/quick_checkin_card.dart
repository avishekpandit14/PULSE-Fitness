import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/models/checkin_model.dart';
import '../../../widgets/pulse_card.dart';

class QuickCheckinCard extends StatelessWidget {
  final CheckInModel? checkIn;
  final VoidCallback onTap;

  const QuickCheckinCard({
    super.key,
    required this.checkIn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = checkIn != null;

    return PulseCard(
      onTap: onTap,
      borderColor: isCompleted ? null : AppColors.limeAccent.withAlpha(80),
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
                      Icons.edit_note_rounded,
                      color: AppColors.limeAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DAILY SUBJECTIVE CHECK-IN',
                    style: AppTypography.labelMedium.copyWith(
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.readyGreen.withAlpha(30)
                      : AppColors.limeAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'COMPLETED' : 'PENDING',
                  style: TextStyle(
                    color: isCompleted
                        ? AppColors.readyGreen
                        : AppColors.limeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isCompleted) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSliderMetric(
                  'Energy',
                  '${checkIn!.energy}/10',
                  AppColors.limeAccent,
                ),
                _buildSliderMetric(
                  'Soreness',
                  '${checkIn!.muscleSoreness}/10',
                  AppColors.moderateAmber,
                ),
                _buildSliderMetric(
                  'Fatigue',
                  '${checkIn!.fatigue}/10',
                  AppColors.restCoral,
                ),
              ],
            ),
            if (checkIn!.notes != null && checkIn!.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '“${checkIn!.notes}”',
                style: AppTypography.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ] else ...[
            Text(
              'Calibrate your recovery score with morning subjective vitality ratings.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  size: 14,
                  color: AppColors.limeAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap to complete check-in (Energy, Soreness, Fatigue)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.limeAccent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSliderMetric(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: AppTypography.labelMedium),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
