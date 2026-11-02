import '../datasources/database_helper.dart';
import '../datasources/health_connect_service.dart';
import '../datasources/mock_data_generator.dart';
import '../../domain/algorithms/recommendation_engine.dart';
import '../../domain/algorithms/recovery_calculator.dart';
import '../../domain/algorithms/strain_calculator.dart';
import '../../domain/models/checkin_model.dart';
import '../../domain/models/heart_rate_sample.dart';
import '../../domain/models/metric_status_model.dart';
import '../../domain/models/recommendation_result.dart';
import '../../domain/models/recovery_result.dart';
import '../../domain/models/sleep_session_model.dart';
import '../../domain/models/strain_result.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/workout_model.dart';

class HealthRepository {
  final DatabaseHelper _dbHelper;
  final HealthConnectService _healthService;

  HealthRepository({
    DatabaseHelper? dbHelper,
    HealthConnectService? healthService,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _healthService = healthService ?? HealthConnectService();

  Future<bool> isHealthConnectAvailable() =>
      _healthService.isHealthConnectAvailable();

  Future<bool> hasPermissions() => _healthService.hasPermissions();

  Future<bool> requestPermissions() => _healthService.requestPermissions();

  Future<void> revokePermissions() => _healthService.revokePermissions();

  Future<void> installHealthConnect() => _healthService.installHealthConnect();

  /// Gets real-time metric diagnostic statuses
  Future<List<MetricStatus>> getMetricStatuses({
    required bool isDemoMode,
  }) async {
    if (isDemoMode) {
      return MockDataGenerator.getMockMetricStatuses();
    }
    return await _healthService.getDetailedMetricStatuses();
  }

  /// Saves today's check-in
  Future<void> saveCheckIn(CheckInModel checkIn) async {
    await _dbHelper.saveCheckIn(checkIn);
  }

  /// Gets today's check-in
  Future<CheckInModel?> getTodayCheckIn({required bool isDemoMode}) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final saved = await _dbHelper.getCheckInForDate(dateKey);
    if (saved != null) return saved;

    if (isDemoMode) {
      return MockDataGenerator.getMockCheckIn();
    }
    return null;
  }

  /// Gets all historical check-ins
  Future<List<CheckInModel>> getAllCheckIns({required bool isDemoMode}) async {
    final list = await _dbHelper.getAllCheckIns();
    if (list.isEmpty && isDemoMode) {
      return [MockDataGenerator.getMockCheckIn()];
    }
    return list;
  }

  /// Computes Recovery and Strain
  Future<
    ({
      RecoveryResult recovery,
      StrainResult strain,
      RecommendationResult recommendation,
      SleepSessionModel? sleepSession,
      double? todayRhr,
      List<HeartRateSample> hrSamples,
      int steps,
      int activeCalories,
      List<WorkoutModel> workouts,
    })
  >
  computeDailyReadiness({
    required UserProfile profile,
    required List<WorkoutModel> workouts,
  }) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final SleepSessionModel? sleepSession;
    final double? todayRhr;
    final List<double> historicalRhrs;
    final int steps;
    final int activeCalories;
    final List<HeartRateSample> hrSamples;
    final CheckInModel? checkIn = await getTodayCheckIn(
      isDemoMode: profile.isDemoMode,
    );
    final List<WorkoutModel> syncedWorkouts;
    bool stepsAvailable = true;
    bool activeCaloriesAvailable = true;

    if (profile.isDemoMode) {
      sleepSession = MockDataGenerator.getMockSleepSession(
        targetHours: profile.sleepTargetHours,
      );
      todayRhr = MockDataGenerator.getMockTodayRhr();
      historicalRhrs = MockDataGenerator.getMockHistoricalRhrs();
      steps = MockDataGenerator.getMockSteps();
      activeCalories = MockDataGenerator.getMockActiveCalories();
      hrSamples = MockDataGenerator.getMockHeartRateSamples();
      syncedWorkouts = workouts;
    } else {
      final healthWorkouts = await _healthService.fetchTodayWorkouts();
      final byId = <String, WorkoutModel>{
        for (final workout in [...healthWorkouts, ...workouts])
          workout.id: workout,
      };
      syncedWorkouts = byId.values.toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      sleepSession = await _healthService.fetchTodaySleepSession(
        targetHours: profile.sleepTargetHours,
      );
      todayRhr = await _healthService.fetchTodayRestingHeartRate();

      // Persist today's RHR to database if recorded to build baseline
      if (todayRhr != null && todayRhr > 30) {
        await _dbHelper.recordRhr(
          dateKey: dateKey,
          rhr: todayRhr,
          source: 'Health Connect',
        );
      }

      historicalRhrs = await _dbHelper.getHistoricalRhrs(limit: 14);
      final syncedSteps = await _healthService.fetchTodayStepsOrNull();
      final syncedCalories = await _healthService
          .fetchTodayActiveCaloriesOrNull();
      stepsAvailable = syncedSteps != null;
      activeCaloriesAvailable = syncedCalories != null;
      steps = syncedSteps ?? 0;
      activeCalories = syncedCalories ?? 0;
      hrSamples = await _healthService.fetchTodayHeartRateSamples();
    }

    // Recent 7-day strain loads
    final List<double> recentLoads;
    final List<bool> recentLoadAvailability;
    if (profile.isDemoMode) {
      recentLoads = MockDataGenerator.getMockWeeklyStrain();
      recentLoadAvailability = List<bool>.filled(recentLoads.length, true);
    } else {
      final stored = await _dbHelper.getRecentDailySummaries(limit: 7);
      final chronological = stored
          .where((row) => row['date_key'] != dateKey)
          .toList()
          .reversed
          .toList();
      recentLoads = chronological
          .map((row) => (row['strain_score'] as num?)?.toDouble() ?? 0.0)
          .toList();
      recentLoadAvailability = chronological
          .map((row) => row['strain_score'] != null)
          .toList();
    }

    // Yesterday's strain from rolling history
    final double? yesterdayStrain = recentLoads.length >= 2
        ? recentLoads[recentLoads.length - 2]
        : null;

    // Compute recovery
    final recovery = RecoveryCalculator.calculate(
      sleepSession: sleepSession,
      todayRhr: todayRhr,
      historicalRhrs: historicalRhrs,
      yesterdayStrain: yesterdayStrain,
      checkIn: checkIn,
      sleepTargetHours: profile.sleepTargetHours,
    );

    // Compute strain with hrSamples and recovery score
    final strain = StrainCalculator.calculate(
      todayWorkouts: syncedWorkouts,
      steps: steps,
      activeCalories: activeCalories,
      maxHeartRate: profile.calculatedMaxHeartRate,
      recent7DaysLoads: recentLoads,
      recent7DaysLoadAvailability: recentLoadAvailability,
      hrSamples: hrSamples,
      recoveryScore: recovery.score,
      stepsAvailable: stepsAvailable,
      activeCaloriesAvailable: activeCaloriesAvailable,
    );

    if (!profile.isDemoMode) {
      await _dbHelper.saveDailySummary(
        dateKey: dateKey,
        recoveryScore: recovery.score,
        strainScore: strain.score,
        sleepMinutes: sleepSession?.totalMinutes,
        steps: stepsAvailable ? steps : null,
        activeCalories: activeCaloriesAvailable ? activeCalories : null,
        source: 'Android Health Connect',
        dataQuality: syncedWorkouts.isNotEmpty || hrSamples.isNotEmpty
            ? 'measured'
            : 'partial',
      );
    }

    // Generate recommendation
    final recommendation = RecommendationEngine.generate(
      recovery: recovery,
      strain: strain,
    );

    return (
      recovery: recovery,
      strain: strain,
      recommendation: recommendation,
      sleepSession: sleepSession,
      todayRhr: todayRhr,
      hrSamples: hrSamples,
      steps: steps,
      activeCalories: activeCalories,
      workouts: syncedWorkouts,
    );
  }
}
