import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/pulse_card.dart';
import '../../widgets/section_header.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Data Governance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PulseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.readyGreen.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.readyGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ZERO CLOUD STORAGE',
                              style: AppTypography.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '100% On-Device Local Processing',
                              style: TextStyle(
                                color: AppColors.readyGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'PULSE is engineered with absolute respect for bodily autonomy and data sovereignty. '
                    'We do not operate servers, do not require user accounts, do not include third-party advertising SDKs, '
                    'and never transmit or sell your biometric data.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const SectionHeader(
              title: 'What We Read & Why',
              subtitle:
                  'Transparent rationale for each Android Health Connect permission',
            ),
            const SizedBox(height: 8),

            _buildPermissionItem(
              title: 'Heart Rate & Resting Heart Rate',
              permission: 'android.permission.health.READ_HEART_RATE',
              purpose:
                  'Used to determine your personal resting heart rate baseline, identify autonomic recovery status, '
                  'and calculate cardiovascular training impulse in athletic heart rate zones.',
            ),
            const SizedBox(height: 10),

            _buildPermissionItem(
              title: 'Sleep Sessions & Sleep Stages',
              permission: 'android.permission.health.READ_SLEEP',
              purpose:
                  'Used to evaluate nocturnal rest duration against your configured target (accounting for 35% of recovery calculation) '
                  'and assess restorative sleep consistency.',
            ),
            const SizedBox(height: 10),

            _buildPermissionItem(
              title: 'Exercise & Workout Sessions',
              permission: 'android.permission.health.READ_EXERCISE',
              purpose:
                  'Used to aggregate workout durations, sport categories, and heart rate intensities into your daily strain score.',
            ),
            const SizedBox(height: 10),

            _buildPermissionItem(
              title: 'Steps & Active Calories',
              permission: 'android.permission.health.READ_STEPS',
              purpose:
                  'Used as background daily movement context. Never falsely inflated to masquerade as high-intensity workout strain.',
            ),
            const SizedBox(height: 24),

            const SectionHeader(
              title: 'How to Revoke Permissions',
              subtitle: 'Complete user control over data access',
            ),
            const SizedBox(height: 8),
            PulseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You retain permanent control over your permissions. To revoke access at any time:\n\n'
                    '1. Open Android Settings on your phone.\n'
                    '2. Go to Apps → Special app access → Health Connect (or Settings → Security & privacy → Health Connect on Android 14+).\n'
                    '3. Tap App permissions → PULSE.\n'
                    '4. Toggle off individual permissions or select "Remove all permissions".\n\n'
                    'Once revoked, PULSE will immediately cease reading data from Health Connect.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
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

  Widget _buildPermissionItem({
    required String title,
    required String permission,
    required String purpose,
  }) {
    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.limeAccent,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppTypography.titleSmall)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            permission,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            purpose,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
