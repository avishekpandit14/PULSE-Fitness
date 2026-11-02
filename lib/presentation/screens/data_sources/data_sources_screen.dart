import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/models/metric_status_model.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/pulse_card.dart';
import '../../widgets/section_header.dart';

class DataSourcesScreen extends StatelessWidget {
  const DataSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();
    final userProvider = context.watch<UserProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();

    final user = userProvider.profile;
    final metrics = healthProvider.metricStatuses;
    final isHC = healthProvider.isHealthConnectAvailable;
    final hasPerm = healthProvider.hasPermissions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sources & Health Connect'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.limeAccent,
            ),
            tooltip: 'Sync Now',
            onPressed: () async {
              await workoutProvider.loadWorkouts(isDemoMode: user.isDemoMode);
              await healthProvider.refreshAll(
                profile: user,
                workouts: workoutProvider.workouts,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Connect Bridge Status Card
            PulseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.sensors_rounded,
                          color: AppColors.limeAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ANDROID HEALTH CONNECT',
                              style: AppTypography.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.isDemoMode
                                  ? 'Demo Mode Active (Synthetic Telemetry)'
                                  : (isHC
                                        ? (hasPerm
                                              ? 'Connected & Authorized'
                                              : 'Permissions Pending')
                                        : 'Health Connect Not Installed / Ready'),
                              style: TextStyle(
                                color: user.isDemoMode
                                    ? AppColors.moderateAmber
                                    : (hasPerm
                                          ? AppColors.readyGreen
                                          : AppColors.restCoral),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PULSE reads telemetry locally from Android Health Connect. Any compatible '
                    'tracker and companion app that writes Health Connect records can work.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  if (!user.isDemoMode) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.security_rounded, size: 16),
                            label: const Text(
                              'Request Access',
                              style: TextStyle(fontSize: 13),
                            ),
                            onPressed: () async {
                              await healthProvider.requestPermissions(
                                profile: user,
                                workouts: workoutProvider.workouts,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            label: const Text(
                              'Install / Open',
                              style: TextStyle(fontSize: 13),
                            ),
                            onPressed: () async {
                              await healthProvider.installHealthConnect();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metrics Status Audit
            const SectionHeader(
              title: 'Individual Metric Status Audit',
              subtitle: 'Telemetry channels verified on device',
            ),
            const SizedBox(height: 8),

            if (metrics.isNotEmpty) ...[
              ...metrics.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMetricCard(m),
                ),
              ),
            ] else ...[
              PulseCard(
                child: Text(
                  'Scanning data sources...',
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // How Permissions Work & How to Revoke
            const SectionHeader(title: 'Permissions & Tracker Sync Guide'),
            const SizedBox(height: 8),
            PulseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HOW DATA FLOWS:', style: AppTypography.labelMedium),
                  const SizedBox(height: 6),
                  Text(
                    '1. Your tracker records sensor data.\n'
                    '2. Its companion app syncs the tracker over Bluetooth or Wi-Fi.\n'
                    '3. Enable Health Connect sharing in that companion app.\n'
                    '4. PULSE reads Health Connect locally without sending data to any external cloud.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'HOW TO REVOKE PERMISSIONS:',
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You can revoke access anytime in Android Settings → Apps → Special app access → Health Connect → App permissions → PULSE.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
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

  Widget _buildMetricCard(MetricStatus metric) {
    Color badgeColor;
    switch (metric.status) {
      case MetricSyncStatus.available:
        badgeColor = AppColors.readyGreen;
        break;
      case MetricSyncStatus.permissionRequired:
        badgeColor = AppColors.moderateAmber;
        break;
      case MetricSyncStatus.noDataFound:
        badgeColor = AppColors.textTertiary;
        break;
      case MetricSyncStatus.unsupported:
        badgeColor = AppColors.restCoral;
        break;
    }

    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(metric.title, style: AppTypography.titleSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withAlpha(70)),
                ),
                child: Text(
                  metric.statusLabel.toUpperCase(),
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(metric.description, style: AppTypography.bodySmall),
          if (metric.lastValue != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Last Record:', style: AppTypography.labelMedium),
                  Text(
                    metric.lastValue!,
                    style: const TextStyle(
                      color: AppColors.limeAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            metric.explanation,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
