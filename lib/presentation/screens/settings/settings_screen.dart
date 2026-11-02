import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/pulse_card.dart';
import '../../widgets/section_header.dart';
import '../data_sources/data_sources_screen.dart';
import '../privacy/privacy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final healthProvider = context.watch<HealthProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final user = userProvider.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Preferences & Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo Mode Switch Card
            PulseCard(
              borderColor: user.isDemoMode ? AppColors.moderateAmber : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.science_rounded,
                            color: user.isDemoMode
                                ? AppColors.moderateAmber
                                : AppColors.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'DEMO MODE (FICTIONAL DATA)',
                            style: AppTypography.labelLarge.copyWith(
                              color: user.isDemoMode
                                  ? AppColors.moderateAmber
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: user.isDemoMode,
                        activeThumbColor: AppColors.moderateAmber,
                        onChanged: (val) async {
                          await userProvider.toggleDemoMode(val);
                          await workoutProvider.loadWorkouts(isDemoMode: val);
                          await healthProvider.refreshAll(
                            profile: userProvider.profile,
                            workouts: workoutProvider.workouts,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When enabled, PULSE populates realistic synthetic tracker telemetry for Health Connect. '
                    'Use this to safely test and inspect all UI states. '
                    'All demo telemetry is explicitly labeled.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile & Physiology Settings
            const SectionHeader(
              title: 'Physiological Parameters',
              subtitle:
                  'Tailors recovery targets and cardiovascular strain zones',
            ),
            const SizedBox(height: 8),
            PulseCard(
              child: Column(
                children: [
                  _buildSettingRow(
                    title: 'Athlete Name',
                    value: user.name,
                    icon: Icons.person_outline_rounded,
                    onTap: () => _editNameDialog(context, userProvider),
                  ),
                  const Divider(height: 16),
                  _buildSettingRow(
                    title: 'Age',
                    value: '${user.age ?? 28} years',
                    icon: Icons.cake_outlined,
                    onTap: () => _editAgeDialog(context, userProvider),
                  ),
                  const Divider(height: 16),
                  _buildSettingRow(
                    title: 'Sleep Target',
                    value: '${user.sleepTargetHours.toStringAsFixed(1)} hrs',
                    icon: Icons.bedtime_outlined,
                    onTap: () => _editSleepTargetDialog(context, userProvider),
                  ),
                  const Divider(height: 16),
                  _buildSettingRow(
                    title: 'Maximum Heart Rate',
                    value:
                        '${user.calculatedMaxHeartRate} bpm ${user.configuredMaxHeartRate == null ? "(Tanaka est.)" : "(Custom)"}',
                    icon: Icons.favorite_outline_rounded,
                    onTap: () => _editMaxHrDialog(context, userProvider),
                  ),
                  const Divider(height: 16),
                  _buildSettingRow(
                    title: 'Weekly Training Frequency',
                    value: '${user.typicalTrainingFrequencyDays} sessions/wk',
                    icon: Icons.fitness_center_outlined,
                    onTap: () =>
                        _editTrainingFrequencyDialog(context, userProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Health Connect & Integrations
            const SectionHeader(title: 'Integrations & System'),
            const SizedBox(height: 8),
            PulseCard(
              child: Column(
                children: [
                  _buildNavRow(
                    title: 'Data Sources & Diagnostic Audit',
                    subtitle:
                        'Inspect Health Connect status and channel availability',
                    icon: Icons.sensors_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DataSourcesScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 16),
                  _buildNavRow(
                    title: 'Privacy Manifesto & Permissions',
                    subtitle:
                        'Local-first architecture and how to revoke permissions',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Danger Zone: Reset Data
            PulseCard(
              borderColor: AppColors.restCoral.withAlpha(80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.delete_forever_rounded,
                        color: AppColors.restCoral,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LOCAL DATA MANAGEMENT',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.restCoral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PULSE stores all your check-ins, manual workouts, and baseline history locally in on-device SQLite. '
                    'Clearing local data removes saved logs without affecting Health Connect or your tracker companion app.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.restCoral,
                      side: const BorderSide(color: AppColors.restCoral),
                    ),
                    onPressed: () => _confirmResetDialog(
                      context,
                      userProvider,
                      healthProvider,
                    ),
                    child: const Text('Reset Local Database'),
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

  Widget _buildSettingRow({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.limeAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.limeAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _editNameDialog(BuildContext context, UserProvider provider) {
    final controller = TextEditingController(text: provider.profile.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Athlete Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.updateProfile(
                  provider.profile.copyWith(name: controller.text.trim()),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editAgeDialog(BuildContext context, UserProvider provider) {
    final controller = TextEditingController(
      text: (provider.profile.age ?? 28).toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Age'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Age in years'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final age = int.tryParse(controller.text);
              if (age != null && age > 10 && age < 120) {
                provider.updateProfile(provider.profile.copyWith(age: age));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editSleepTargetDialog(BuildContext context, UserProvider provider) {
    double current = provider.profile.sleepTargetHours;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: const Text('Sleep Target Duration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${current.toStringAsFixed(1)} hours',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.limeAccent,
                ),
              ),
              Slider(
                value: current,
                min: 5.5,
                max: 10.0,
                divisions: 9,
                onChanged: (v) => setDialogState(() => current = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.updateProfile(
                  provider.profile.copyWith(sleepTargetHours: current),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _editMaxHrDialog(BuildContext context, UserProvider provider) {
    final controller = TextEditingController(
      text: provider.profile.configuredMaxHeartRate?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Max Heart Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max Heart Rate (bpm)',
                hintText: 'Leave empty for Tanaka auto formula',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If left empty, Tanaka formula: 208 - (0.7 * Age) is used automatically.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final hr = int.tryParse(controller.text);
              provider.updateProfile(
                provider.profile.copyWith(configuredMaxHeartRate: hr),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editTrainingFrequencyDialog(
    BuildContext context,
    UserProvider provider,
  ) {
    int days = provider.profile.typicalTrainingFrequencyDays;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: const Text('Training Frequency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$days sessions per week',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.limeAccent,
                ),
              ),
              Slider(
                value: days.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                onChanged: (v) => setDialogState(() => days = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.updateProfile(
                  provider.profile.copyWith(typicalTrainingFrequencyDays: days),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetDialog(
    BuildContext context,
    UserProvider userProvider,
    HealthProvider healthProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Reset Local Database?'),
        content: const Text(
          'This will permanently delete all local check-in entries, manual workouts, '
          'and your RHR baseline history. Data stored inside Android Health Connect will remain untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.restCoral,
            ),
            onPressed: () async {
              await userProvider.resetAllData();
              await healthProvider.refreshAll(
                profile: userProvider.profile,
                workouts: [],
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              'Reset All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
