import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/models/user_profile.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/pulse_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController(text: 'Athlete');
  final _ageController = TextEditingController(text: '28');
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _maxHrController = TextEditingController();

  double _sleepTarget = 8.0;
  int _trainingFrequency = 4;
  bool _startInDemoMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _maxHrController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding({required bool isSkip}) async {
    final userProvider = context.read<UserProvider>();
    final healthProvider = context.read<HealthProvider>();
    final workoutProvider = context.read<WorkoutProvider>();

    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final maxHr = int.tryParse(_maxHrController.text);

    final profile = isSkip
        ? const UserProfile(onboardingCompleted: true)
        : UserProfile(
            name: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : 'Athlete',
            age: age,
            heightCm: height,
            weightKg: weight,
            sleepTargetHours: _sleepTarget,
            configuredMaxHeartRate: maxHr,
            typicalTrainingFrequencyDays: _trainingFrequency,
            isDemoMode: _startInDemoMode,
            onboardingCompleted: true,
          );

    await userProvider.completeOnboarding(profile);
    await workoutProvider.loadWorkouts(isDemoMode: profile.isDemoMode);
    await healthProvider.refreshAll(
      profile: profile,
      workouts: workoutProvider.workouts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.limeAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PULSE',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _completeOnboarding(isSkip: true),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Welcome to PULSE',
                style: AppTypography.displayMedium.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'Next-generation athletic recovery and training load estimation. '
                'Works with compatible Android Health Connect trackers without requiring HRV.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 28),

              // 1. Name & Age
              PulseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. BASIC IDENTITY (OPTIONAL)',
                      style: AppTypography.labelMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Name',
                        hintText: 'e.g. Alex',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age (years)',
                        hintText: 'Used to calculate heart rate training zones',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Why we ask: Used strictly to tailor greeting and estimate max heart rate using Tanaka formula.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Sleep Target
              PulseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '2. SLEEP TARGET',
                          style: AppTypography.labelMedium,
                        ),
                        Text(
                          '${_sleepTarget.toStringAsFixed(1)} hrs',
                          style: const TextStyle(
                            color: AppColors.limeAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _sleepTarget,
                      min: 5.5,
                      max: 10.0,
                      divisions: 9,
                      onChanged: (v) => setState(() => _sleepTarget = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('5.5 hrs', style: AppTypography.bodySmall),
                        Text(
                          '7.5-8.0 hrs (Standard)',
                          style: AppTypography.bodySmall,
                        ),
                        Text('10.0 hrs', style: AppTypography.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Why we ask: The recovery engine evaluates sleep duration relative to your personalized target rather than a generic arbitrary value.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Training Frequency & Heart Rate
              PulseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '3. TRAINING FREQUENCY',
                          style: AppTypography.labelMedium,
                        ),
                        Text(
                          '$_trainingFrequency days/wk',
                          style: const TextStyle(
                            color: AppColors.limeAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _trainingFrequency.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      onChanged: (v) =>
                          setState(() => _trainingFrequency = v.round()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _maxHrController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Heart Rate (optional, bpm)',
                        hintText: 'Leave empty for 208 - (0.7 * age)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Why we ask: Calibrates Zone 1 through Zone 5 training strain intensity.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Demo mode toggle option during onboarding
              PulseCard(
                borderColor: _startInDemoMode ? AppColors.moderateAmber : null,
                child: Row(
                  children: [
                    const Icon(
                      Icons.science_rounded,
                      color: AppColors.moderateAmber,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start in Demo Mode',
                            style: AppTypography.titleSmall,
                          ),
                          Text(
                            'Explore with synthetic tracker telemetry right away',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _startInDemoMode,
                      activeThumbColor: AppColors.moderateAmber,
                      onChanged: (v) => setState(() => _startInDemoMode = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Complete Button
              ElevatedButton(
                onPressed: () => _completeOnboarding(isSkip: false),
                child: const Text('Get Started with PULSE'),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'No account required. All health data remains strictly on your device.',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
