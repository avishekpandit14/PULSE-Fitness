import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/models/checkin_model.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/pulse_card.dart';
import '../../widgets/section_header.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  int _energy = 7; // 1 to 10
  int _soreness = 3; // 0 to 10
  int _fatigue = 3; // 0 to 10
  final _notesController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final existing = context.read<HealthProvider>().todayCheckIn;
      if (existing != null) {
        _energy = existing.energy;
        _soreness = existing.muscleSoreness;
        _fatigue = existing.fatigue;
        if (existing.notes != null) {
          _notesController.text = existing.notes!;
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.watch<HealthProvider>();
    final userProvider = context.watch<UserProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final history = healthProvider.checkInHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-in')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Check-in Form Card
            PulseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SUBJECTIVE CALIBRATION',
                        style: AppTypography.labelMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.limeAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '25% RECOVERY WEIGHT',
                          style: TextStyle(
                            color: AppColors.limeAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. Energy Rating (1-10)
                  _buildSlider(
                    title: 'ENERGY LEVEL',
                    value: _energy,
                    min: 1,
                    max: 10,
                    minLabel: '1 (Exhausted)',
                    maxLabel: '10 (Peak Vitality)',
                    color: AppColors.limeAccent,
                    onChanged: (v) => setState(() => _energy = v),
                    weightDesc:
                        '10% Weight: High subjective vitality raises recovery.',
                  ),
                  const SizedBox(height: 20),

                  // 2. Muscle Soreness Rating (0-10)
                  _buildSlider(
                    title: 'MUSCLE SORENESS (DOMS)',
                    value: _soreness,
                    min: 0,
                    max: 10,
                    minLabel: '0 (No Soreness)',
                    maxLabel: '10 (Debilitating)',
                    color: AppColors.moderateAmber,
                    onChanged: (v) => setState(() => _soreness = v),
                    weightDesc:
                        '10% Weight: Elevated muscle damage reduces training capacity.',
                  ),
                  const SizedBox(height: 20),

                  // 3. Fatigue Rating (0-10)
                  _buildSlider(
                    title: 'SYSTEMIC FATIGUE',
                    value: _fatigue,
                    min: 0,
                    max: 10,
                    minLabel: '0 (Refreshed)',
                    maxLabel: '10 (Drained)',
                    color: AppColors.restCoral,
                    onChanged: (v) => setState(() => _fatigue = v),
                    weightDesc:
                        '5% Weight: Accounts for nervous system / mental fatigue.',
                  ),
                  const SizedBox(height: 20),

                  // Optional Notes
                  Text(
                    'DAILY LOG & OBSERVATIONS (OPTIONAL)',
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. Slept deeply, slight lower back tightness, felt energized',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final dateKey =
                          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

                      final checkIn = CheckInModel(
                        dateKey: dateKey,
                        energy: _energy,
                        muscleSoreness: _soreness,
                        fatigue: _fatigue,
                        notes: _notesController.text.trim().isNotEmpty
                            ? _notesController.text.trim()
                            : null,
                        timestamp: now,
                      );

                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      await healthProvider.submitCheckIn(
                        checkIn: checkIn,
                        profile: userProvider.profile,
                        workouts: workoutProvider.workouts,
                      );

                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Daily check-in saved. Recovery updated!',
                            ),
                            backgroundColor: AppColors.surfaceElevated,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        navigator.pop();
                      }
                    },
                    child: const Text('Save Daily Check-in'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Check-in History
            if (history.isNotEmpty) ...[
              SectionHeader(
                title: 'Check-in History (${history.length})',
                subtitle: 'Recent subjective ratings',
              ),
              const SizedBox(height: 8),
              ...history.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PulseCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              PulseDateUtils.formatShortDate(c.timestamp),
                              style: AppTypography.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              PulseDateUtils.formatTime(c.timestamp),
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                        const Spacer(),
                        _buildMiniBadge(
                          'Energy',
                          '${c.energy}/10',
                          AppColors.limeAccent,
                        ),
                        const SizedBox(width: 8),
                        _buildMiniBadge(
                          'Soreness',
                          '${c.muscleSoreness}/10',
                          AppColors.moderateAmber,
                        ),
                        const SizedBox(width: 8),
                        _buildMiniBadge(
                          'Fatigue',
                          '${c.fatigue}/10',
                          AppColors.restCoral,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required int value,
    required int min,
    required int max,
    required String minLabel,
    required String maxLabel,
    required Color color,
    required ValueChanged<int> onChanged,
    required String weightDesc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.labelMedium),
            Text(
              '$value / $max',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: color,
          thumbColor: color,
          onChanged: (v) => onChanged(v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: AppTypography.bodySmall),
            Text(maxLabel, style: AppTypography.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          weightDesc,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
          ),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
