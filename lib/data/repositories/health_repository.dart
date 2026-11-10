import '../datasources/database_helper.dart';
import '../datasources/health_connect_service.dart';
import '../datasources/mock_data_generator.dart';
import '../../domain/algorithms/nighttime_heart_rate_analyzer.dart';
import '../../domain/algorithms/recommendation_engine.dart';
import '../../domain/algorithms/recovery_calculator.dart';
import '../../domain/algorithms/sleep_quality_analyzer.dart';
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
      SleepNightReport sleepNight,
      SleepQualityResult? sleepQuality,
      NighttimeHeartRateAnalysis? nightHeartRate,
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
    final dateKey = _dateKey(now);

    final SleepNightReport sleepNight;
    final SleepQualityResult? sleepQuality;
    final NighttimeHeartRateAnalysis? nightHeartRate;
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
      sleepNight = MockDataGenerator.getMockSleepNight(
        targetHours: profile.sleepTargetHours,
      );
      sleepQuality = _evaluateSleep(sleepNight.primary);
      nightHeartRate = _analyzeNightHeartRate(
        sleepSession: sleepNight.primary,
        samples: sleepNight.primary == null
            ? const []
            : MockDataGenerator.getMockNightHeartRateSamples(
                startTime: sleepNight.primary!.startTime,
                endTime: sleepNight.primary!.endTime,
              ),
        historicalNightlyAverages: MockDataGenerator.getMockNightlyHrAverages(),
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

      sleepNight = await _healthService.fetchSleepNight(
        targetHours: profile.sleepTargetHours,
      );
      sleepQuality = _evaluateSleep(sleepNight.primary);

      final primarySleep = sleepNight.primary;
      final nightSamples =
          primarySleep == null || primarySleep.totalMinutes <= 0
          ? const <HeartRateSample>[]
          : await _healthService.fetchHeartRateSamples(
              start: primarySleep.startTime,
              end: primarySleep.endTime,
            );
      nightHeartRate = _analyzeNightHeartRate(
        sleepSession: primarySleep,
        samples: nightSamples,
        // Read the baseline before today's summary is written, and exclude today
        // so a night never contributes to its own baseline.
        historicalNightlyAverages: await _dbHelper
            .getHistoricalNightlyHrAverages(excludeDateKey: dateKey),
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

    // Yesterday's strain. `recentLoads` holds prior days only (StrainCalculator
    // appends today's score itself), so the final entry is yesterday - not the
    // second-to-last, which skipped a day. An unavailable reading stays null
    // instead of silently becoming a rest day.
    final double? yesterdayStrain =
        recentLoads.isNotEmpty && recentLoadAvailability.last
        ? recentLoads.last
        : null;

    // Compute recovery
    final recovery = RecoveryCalculator.calculate(
      sleepSession: sleepNight.primary,
      todayRhr: todayRhr,
      historicalRhrs: historicalRhrs,
      yesterdayStrain: yesterdayStrain,
      checkIn: checkIn,
      sleepTargetHours: profile.sleepTargetHours,
      sleepQuality: sleepQuality,
      nightHeartRate: nightHeartRate,
      napMinutes: sleepNight.napMinutes,
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
        sleepMinutes: sleepNight.primary?.totalMinutes,
        steps: stepsAvailable ? steps : null,
        activeCalories: activeCaloriesAvailable ? activeCalories : null,
        source: 'Android Health Connect',
        dataQuality: syncedWorkouts.isNotEmpty || hrSamples.isNotEmpty
            ? 'measured'
            : 'partial',
        nightHrAvg: nightHeartRate.hasUsableData
            ? nightHeartRate.averageBpm
            : null,
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
      sleepSession: sleepNight.primary,
      sleepNight: sleepNight,
      sleepQuality: sleepQuality,
      nightHeartRate: nightHeartRate,
      todayRhr: todayRhr,
      hrSamples: hrSamples,
      steps: steps,
      activeCalories: activeCalories,
      workouts: syncedWorkouts,
    );
  }

  static SleepQualityResult? _evaluateSleep(SleepSessionModel? session) {
    if (session == null || session.totalMinutes <= 0) return null;
    return SleepQualityAnalyzer.analyze(session);
  }

  /// Analyzes nighttime HR inside the primary sleep window. Returns an explicit
  /// "insufficient" analysis (never invented values) when there was no sleep
  /// session or no usable samples.
  static NighttimeHeartRateAnalysis _analyzeNightHeartRate({
    required SleepSessionModel? sleepSession,
    required List<HeartRateSample> samples,
    required List<double> historicalNightlyAverages,
  }) {
    if (sleepSession == null || sleepSession.totalMinutes <= 0) {
      return NighttimeHeartRateAnalysis(
        sampleCount: 0,
        quality: NighttimeHrQuality.insufficient,
        limitations: const [
          'No validated nighttime sleep session, so nighttime HR was not analysed.',
        ],
      );
    }
    return NighttimeHeartRateAnalyzer.analyze(
      samples: samples,
      sleepStart: sleepSession.startTime,
      sleepEnd: sleepSession.endTime,
      historicalNightlyAverages: historicalNightlyAverages,
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
