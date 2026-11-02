import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';
import '../checkin/checkin_screen.dart';
import '../data_sources/data_sources_screen.dart';
import '../recovery/recovery_details_screen.dart';
import '../sleep/sleep_details_screen.dart';
import '../strain/strain_details_screen.dart';
import 'widgets/circular_recovery_gauge.dart';
import 'widgets/heart_rate_card.dart';
import 'widgets/quick_checkin_card.dart';
import 'widgets/recommendation_card.dart';
import 'widgets/recovery_summary_card.dart';
import 'widgets/sleep_summary_card.dart';
import 'widgets/strain_summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final healthProvider = context.watch<HealthProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();

    final user = userProvider.profile;
    final now = DateTime.now();

    String greeting;
    final hour = now.hour;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.limeAccent,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await workoutProvider.loadWorkouts(isDemoMode: user.isDemoMode);
          await healthProvider.refreshAll(
            profile: user,
            workouts: workoutProvider.workouts,
          );
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Top App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: AppColors.background.withAlpha(230),
              title: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.limeAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.limeAccent,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PULSE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (user.isDemoMode) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.moderateAmber.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.moderateAmber,
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'DEMO MODE',
                        style: TextStyle(
                          color: AppColors.moderateAmber,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.sensors_rounded,
                    color: AppColors.limeAccent,
                  ),
                  tooltip: 'Data Sources & Health Connect',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DataSourcesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Content List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // A. Greeting & Current Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PulseDateUtils.formatFullDate(now).toUpperCase(),
                        style: AppTypography.labelMedium.copyWith(
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$greeting, ${user.name}',
                        style: AppTypography.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Demo mode alert banner
                  if (user.isDemoMode) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.moderateAmber.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.moderateAmber,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Displaying fictional demo telemetry for UI evaluation. Toggle off in Settings for real Health Connect data.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // B. Large Circular Recovery Indicator
                  CircularRecoveryGauge(
                    recovery: healthProvider.recovery,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecoveryDetailsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // B2. Recovery Summary Card
                  RecoverySummaryCard(
                    recovery: healthProvider.recovery,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecoveryDetailsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // G. Training Recommendation Card
                  RecommendationCard(
                    recommendation: healthProvider.recommendation,
                  ),
                  const SizedBox(height: 16),

                  // C. Sleep Card
                  SleepSummaryCard(
                    sleepSession: healthProvider.sleepSession,
                    targetHours: user.sleepTargetHours,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SleepDetailsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // D. Strain Card
                  StrainSummaryCard(
                    strain: healthProvider.strain,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StrainDetailsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // E. Heart Rate Card
                  HeartRateCard(
                    restingHeartRate: healthProvider.todayRhr,
                    baselineRhr: healthProvider.recovery?.baselineRhr,
                    hrSamples: healthProvider.hrSamples,
                    workouts: workoutProvider.workouts,
                  ),
                  const SizedBox(height: 16),

                  // F. Daily Check-in Card
                  QuickCheckinCard(
                    checkIn: healthProvider.todayCheckIn,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckInScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
