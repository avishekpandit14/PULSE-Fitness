import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// Compact dashboard top bar: profile, streak, current day pill and sync state.
///
/// Deliberately not a Material app bar - the rings underneath are the focus and
/// an elevated bar competes with them.
class DashboardHeader extends StatelessWidget {
  final String userName;
  final int streakDays;
  final String dateLabel;
  final bool isSynced;
  final bool isDemoMode;
  final VoidCallback onSyncTap;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.streakDays,
    required this.dateLabel,
    required this.isSynced,
    required this.isDemoMode,
    required this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = userName.trim();
    final initial = trimmed.isEmpty ? 'P' : trimmed[0].toUpperCase();

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (streakDays > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: AppColors.activityOrange,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$streakDays',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              _buildSyncChip(),
            ],
          ),
          _buildDayPill(),
        ],
      ),
    );
  }

  Widget _buildDayPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        dateLabel,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSyncChip() {
    final Color color;
    final String label;
    if (isDemoMode) {
      color = AppColors.moderateAmber;
      label = 'DEMO';
    } else if (isSynced) {
      color = AppColors.readyGreen;
      label = 'SYNCED';
    } else {
      color = AppColors.textTertiary;
      label = 'OFFLINE';
    }

    return GestureDetector(
      onTap: onSyncTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
