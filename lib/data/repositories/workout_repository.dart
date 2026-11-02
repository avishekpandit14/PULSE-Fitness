import '../datasources/database_helper.dart';
import '../datasources/health_connect_service.dart';
import '../datasources/mock_data_generator.dart';
import '../../domain/models/workout_model.dart';

class WorkoutRepository {
  final DatabaseHelper _dbHelper;
  final HealthConnectService _healthService;

  WorkoutRepository({
    DatabaseHelper? dbHelper,
    HealthConnectService? healthService,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _healthService = healthService ?? HealthConnectService();

  Future<List<WorkoutModel>> getTodayWorkouts({
    required bool isDemoMode,
  }) async {
    if (isDemoMode) {
      final manualWorkouts = await _dbHelper.getWorkoutsForDay(DateTime.now());
      return [...MockDataGenerator.getMockWorkouts(), ...manualWorkouts];
    }

    final autoWorkouts = await _healthService.fetchTodayWorkouts();
    final manualWorkouts = await _dbHelper.getWorkoutsForDay(DateTime.now());

    final all = [...autoWorkouts, ...manualWorkouts];
    all.sort((a, b) => b.startTime.compareTo(a.startTime));
    return all;
  }

  Future<List<WorkoutModel>> getAllWorkouts({required bool isDemoMode}) async {
    if (isDemoMode) {
      final manual = await _dbHelper.getAllWorkouts();
      return [...MockDataGenerator.getMockWorkouts(), ...manual];
    }
    return await _dbHelper.getAllWorkouts();
  }

  Future<void> logManualWorkout(WorkoutModel workout) async {
    await _dbHelper.saveWorkout(workout);
  }

  Future<void> deleteWorkout(String id) async {
    await _dbHelper.deleteWorkout(id);
  }
}
