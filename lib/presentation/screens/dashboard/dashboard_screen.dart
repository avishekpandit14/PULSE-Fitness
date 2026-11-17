import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/models/checkin_model.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';
import '../checkin/checkin_screen.dart';
import '../data_sources/data_sources_screen.dart';
import '../recovery/recovery_details_screen.dart';
import '../sleep/sleep_details_screen.dart';
import '../strain/strain_details_screen.dart';
import '../../widgets/section_header.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/monitor_cards.dart';
import 'widgets/quick_checkin_card.dart';
import 'widgets/recommendation_card.dart';
import 'widgets/sleep_summary_card.dart';
import 'widgets/today_activities_card.dart';
import 'widgets/tri_metric_rings.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Consecutive days with a morning check-in, ending today or yesterday.
  static int _checkInStreak(List<CheckInModel> history) {
    if (history.isEmpty) return 0;
    final days = history.map((entry) => entry.dateKey).toSet();
    String key(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    var cursor = DateTime.now();
    if (!days.contains(key(cursor))) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
      if (!days.contains(key(cursor))) return 0;
    }

    var streak = 0;
    while (days.contains(key(cursor))) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }

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

    void open(Widget screen) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
        // No app bar means nothing else reserves the status bar inset, so the
        // header must start below it explicitly.
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // A. Compact header: profile, streak, current day, sync state
                    DashboardHeader(
                      userName: user.name,
                      streakDays: _checkInStreak(healthProvider.checkInHistory),
                      dateLabel:
                          'TODAY · ${PulseDateUtils.formatShortDate(now).toUpperCase()}',
                      isSynced:
                          healthProvider.isHealthConnectAvailable &&
                          healthProvider.hasPermissions,
                      isDemoMode: user.isDemoMode,
                      onSyncTap: () => open(const DataSourcesScreen()),
                    ),

                    // B. Wordmark, kept quiet so the rings stay the focus
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'PULSE',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // C. Sleep / Recovery / Strain rings
                    TriMetricRings(
                      recovery: healthProvider.recovery,
                      strain: healthProvider.strain,
                      sleepSession: healthProvider.sleepSession,
                      targetHours: user.sleepTargetHours,
                      onSleepTap: () => open(const SleepDetailsScreen()),
                      onRecoveryTap: () => open(const RecoveryDetailsScreen()),
                      onStrainTap: () => open(const StrainDetailsScreen()),
                    ),
                    const SizedBox(height: 22),

                    // D. Training recommendation
                    RecommendationCard(
                      recommendation: healthProvider.recommendation,
                    ),
                    const SizedBox(height: 14),

                    // E. Quick status readouts
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SleepMonitorCard(
                              quality: healthProvider.sleepQuality,
                              napMinutes: healthProvider.sleepNight.napMinutes,
                              onTap: () => open(const SleepDetailsScreen()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: HeartMonitorCard(
                              restingHeartRate: healthProvider.todayRhr,
                              baselineRhr: healthProvider.recovery?.baselineRhr,
                              onTap: () => open(const RecoveryDetailsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // F. My Day
                    SectionHeader(
                      title: 'My Day',
                      subtitle: '$greeting, ${user.name}',
                    ),
                    const SizedBox(height: 4),
                    TodayActivitiesCard(
                      workouts: workoutProvider.workouts,
                      onTap: () => open(const StrainDetailsScreen()),
                    ),
                    const SizedBox(height: 16),

                    // G. Sleep detail (naps and stages live here, not in the ring)
                    SleepSummaryCard(
                      sleepSession: healthProvider.sleepSession,
                      naps: healthProvider.sleepNight.naps,
                      napMinutes: healthProvider.sleepNight.napMinutes,
                      targetHours: user.sleepTargetHours,
                      onTap: () => open(const SleepDetailsScreen()),
                    ),
                    const SizedBox(height: 16),

                    // H. Daily check-in
                    QuickCheckinCard(
                      checkIn: healthProvider.todayCheckIn,
                      onTap: () => open(const CheckInScreen()),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
