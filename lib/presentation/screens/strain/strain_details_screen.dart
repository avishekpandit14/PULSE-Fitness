import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/models/strain_result.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';
import 'log_workout_sheet.dart';
import 'widgets/activity_breakdown_card.dart';
import 'widgets/cardiovascular_load_card.dart';
import 'widgets/circular_strain_gauge.dart';
import 'widgets/daily_strain_graph_card.dart';
import 'widgets/heart_rate_zones_card.dart';
import 'widgets/recommended_strain_card.dart';
import 'widgets/weekly_strain_history_card.dart';
import 'widgets/workout_strain_card.dart';

class StrainDetailsScreen extends StatelessWidget {
  const StrainDetailsScreen({super.key});

  Future<void> _refreshData(BuildContext context) async {
    final user = context.read<UserProvider>().profile;
    final workouts = context.read<WorkoutProvider>().workouts;
    await context.read<HealthProvider>().refreshAll(
      profile: user,
      workouts: workouts,
    );
  }

  void _openLogWorkout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const LogWorkoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final userProvider = context.watch<UserProvider>();

    final strain = healthProvider.strain;
    final recovery = healthProvider.recovery;
    final workouts = workoutProvider.workouts;
    final user = userProvider.profile;

    final isLoading = healthProvider.isLoading && strain == null;
    final errorMessage = healthProvider.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Strain & Training Load'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.limeAccent),
            tooltip: 'Log Workout',
            onPressed: () => _openLogWorkout(context),
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Sync Data',
            onPressed: () => _refreshData(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.limeAccent,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () => _refreshData(context),
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.limeAccent,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Calculating cardiovascular strain...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : errorMessage != null && strain == null
            ? _buildErrorView(context, errorMessage)
            : _buildContent(
                context: context,
                strain: strain,
                recoveryScore: recovery?.score?.toDouble(),
                workouts: workouts,
                maxHeartRate: user.calculatedMaxHeartRate,
              ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.strainRed.withAlpha(80)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.strainRed,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to Load Strain Data',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _refreshData(context),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Sync'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.limeAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required StrainResult? strain,
    required double? recoveryScore,
    required List<dynamic> workouts,
    required int maxHeartRate,
  }) {
    final bool isEmpty =
        (strain?.score ?? 0.0) == 0.0 &&
        workouts.isEmpty &&
        (strain?.steps ?? 0) == 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEmpty) ...[
            _buildEmptyStateBanner(context),
            const SizedBox(height: 14),
          ],

          // 1. Daily Strain Gauge (0–21, categories, today's date)
          CircularStrainGauge(strain: strain),
          const SizedBox(height: 14),

          // 2. Recommended Strain Target (Target range based on recovery score)
          RecommendedStrainCard(strain: strain, recoveryScore: recoveryScore),
          const SizedBox(height: 14),

          // 3. Cardiovascular Load (Cardio vs Movement split, Measured vs Estimated)
          CardiovascularLoadCard(strain: strain),
          const SizedBox(height: 14),

          // 4. Heart Rate Zones (Zones 1-5, BPM ranges, time in zones)
          HeartRateZonesCard(strain: strain, maxHeartRate: maxHeartRate),
          const SizedBox(height: 14),

          // 5. Daily Strain Progression Graph (Timestamped accumulation curve)
          DailyStrainGraphCard(strain: strain),
          const SizedBox(height: 14),

          // 6. Activity Breakdown (Walking, workouts, and recorded activities)
          ActivityBreakdownCard(strain: strain, workouts: workouts.cast()),
          const SizedBox(height: 14),

          // 7. Workout Sessions List (Individual workouts with strain, HR, calories)
          WorkoutStrainCard(
            strain: strain,
            workouts: workouts.cast(),
            onDeleteWorkout: (id) async {
              final user = context.read<UserProvider>().profile;
              await context.read<WorkoutProvider>().deleteWorkout(
                id,
                isDemoMode: user.isDemoMode,
              );
              if (context.mounted) {
                final updatedWorkouts = context
                    .read<WorkoutProvider>()
                    .workouts;
                await context.read<HealthProvider>().refreshAll(
                  profile: user,
                  workouts: updatedWorkouts,
                );
              }
            },
          ),
          const SizedBox(height: 14),

          // 8. Weekly Strain History (Last 7 days bar chart & 7-day average)
          WeeklyStrainHistoryCard(strain: strain),
          const SizedBox(height: 20),

          // Scientific & Algorithmic Transparency Disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withAlpha(120),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderSubtle.withAlpha(60),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    StrainResult.disclaimer,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyStateBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.limeAccent.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run_rounded,
              color: AppColors.limeAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No Activity Recorded Today',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Wear your watch or tap + to log a manual session.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
