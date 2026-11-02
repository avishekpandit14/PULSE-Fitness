import 'package:flutter/foundation.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/workout_model.dart';

class WorkoutProvider extends ChangeNotifier {
  final WorkoutRepository _workoutRepository;
  List<WorkoutModel> _workouts = [];
  bool _isLoading = false;

  WorkoutProvider({WorkoutRepository? workoutRepository})
    : _workoutRepository = workoutRepository ?? WorkoutRepository();

  List<WorkoutModel> get workouts => _workouts;
  bool get isLoading => _isLoading;

  Future<void> loadWorkouts({required bool isDemoMode}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _workouts = await _workoutRepository.getTodayWorkouts(
        isDemoMode: isDemoMode,
      );
    } catch (e) {
      debugPrint('Error loading workouts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addManualWorkout(
    WorkoutModel workout, {
    required bool isDemoMode,
  }) async {
    await _workoutRepository.logManualWorkout(workout);
    await loadWorkouts(isDemoMode: isDemoMode);
  }

  Future<void> deleteWorkout(String id, {required bool isDemoMode}) async {
    await _workoutRepository.deleteWorkout(id);
    await loadWorkouts(isDemoMode: isDemoMode);
  }
}
