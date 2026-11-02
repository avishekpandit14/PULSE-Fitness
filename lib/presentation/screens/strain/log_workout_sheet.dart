import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/models/workout_model.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';

class LogWorkoutSheet extends StatefulWidget {
  const LogWorkoutSheet({super.key});

  @override
  State<LogWorkoutSheet> createState() => _LogWorkoutSheetState();
}

class _LogWorkoutSheetState extends State<LogWorkoutSheet> {
  final _titleController = TextEditingController(text: 'Strength Training');
  final _durationController = TextEditingController(text: '45');
  final _caloriesController = TextEditingController(text: '320');
  final _notesController = TextEditingController();

  WorkoutType _selectedType = WorkoutType.strength;
  int _rpe = 7; // Rate of perceived exertion (1-10)

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Log Manual Workout', style: AppTypography.titleMedium),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Workout Type Selector
            Text('ACTIVITY TYPE', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WorkoutType.values.map((type) {
                final isSelected = type == _selectedType;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  selectedColor: AppColors.limeAccent,
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = type;
                        _titleController.text = type.displayName;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Workout Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Session Name'),
            ),
            const SizedBox(height: 12),

            // Duration & Calories
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (mins)',
                      suffixText: 'm',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories (optional)',
                      suffixText: 'kcal',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Perceived Exertion (RPE)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RATE OF PERCEIVED EXERTION (RPE)',
                  style: AppTypography.labelMedium,
                ),
                Text(
                  '$_rpe / 10',
                  style: const TextStyle(
                    color: AppColors.limeAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Slider(
              value: _rpe.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) => setState(() => _rpe = val.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 (Very Easy)', style: AppTypography.bodySmall),
                Text('5 (Moderate)', style: AppTypography.bodySmall),
                Text('10 (Max Effort)', style: AppTypography.bodySmall),
              ],
            ),
            const SizedBox(height: 16),

            // Optional Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. 5x5 squats, high intensity interval circuits',
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: () async {
                final duration = int.tryParse(_durationController.text) ?? 30;
                final calories = int.tryParse(_caloriesController.text);
                final userProvider = context.read<UserProvider>();
                final workoutProvider = context.read<WorkoutProvider>();
                final healthProvider = context.read<HealthProvider>();

                final newWorkout = WorkoutModel(
                  id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                  title: _titleController.text.trim().isNotEmpty
                      ? _titleController.text.trim()
                      : _selectedType.displayName,
                  type: _selectedType,
                  startTime: DateTime.now().subtract(
                    Duration(minutes: duration),
                  ),
                  durationMinutes: duration,
                  caloriesBurned: calories,
                  rpe: _rpe,
                  isManual: true,
                  notes: _notesController.text.trim().isNotEmpty
                      ? _notesController.text.trim()
                      : null,
                );

                final navigator = Navigator.of(context);

                await workoutProvider.addManualWorkout(
                  newWorkout,
                  isDemoMode: userProvider.isDemoMode,
                );

                await healthProvider.refreshAll(
                  profile: userProvider.profile,
                  workouts: workoutProvider.workouts,
                );

                if (mounted) navigator.pop();
              },
              child: const Text('Log Workout Session'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
