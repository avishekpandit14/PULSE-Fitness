import 'package:flutter/foundation.dart';
import '../../data/repositories/health_repository.dart';
import '../../domain/algorithms/nighttime_heart_rate_analyzer.dart';
import '../../domain/algorithms/sleep_quality_analyzer.dart';
import '../../domain/models/checkin_model.dart';
import '../../domain/models/heart_rate_sample.dart';
import '../../domain/models/metric_status_model.dart';
import '../../domain/models/recommendation_result.dart';
import '../../domain/models/recovery_result.dart';
import '../../domain/models/sleep_session_model.dart';
import '../../domain/models/strain_result.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/workout_model.dart';

class HealthProvider extends ChangeNotifier {
  final HealthRepository _healthRepository;

  RecoveryResult? _recovery;
  StrainResult? _strain;
  RecommendationResult? _recommendation;
  SleepSessionModel? _sleepSession;
  SleepNightReport _sleepNight = SleepNightReport.empty;
  SleepQualityResult? _sleepQuality;
  NighttimeHeartRateAnalysis? _nightHeartRate;
  double? _todayRhr;
  List<HeartRateSample> _hrSamples = [];
  int _steps = 0;
  int _activeCalories = 0;
  List<MetricStatus> _metricStatuses = [];
  CheckInModel? _todayCheckIn;
  List<CheckInModel> _checkInHistory = [];

  bool _isLoading = false;
  bool _isHealthConnectAvailable = false;
  bool _hasPermissions = false;
  String? _errorMessage;

  HealthProvider({HealthRepository? healthRepository})
    : _healthRepository = healthRepository ?? HealthRepository();

  RecoveryResult? get recovery => _recovery;
  StrainResult? get strain => _strain;
  RecommendationResult? get recommendation => _recommendation;
  SleepSessionModel? get sleepSession => _sleepSession;

  /// Primary nighttime session plus separately tracked naps.
  SleepNightReport get sleepNight => _sleepNight;
  SleepQualityResult? get sleepQuality => _sleepQuality;
  NighttimeHeartRateAnalysis? get nightHeartRate => _nightHeartRate;
  double? get todayRhr => _todayRhr;
  List<HeartRateSample> get hrSamples => _hrSamples;
  int get steps => _steps;
  int get activeCalories => _activeCalories;
  List<MetricStatus> get metricStatuses => _metricStatuses;
  CheckInModel? get todayCheckIn => _todayCheckIn;
  List<CheckInModel> get checkInHistory => _checkInHistory;
  bool get isLoading => _isLoading;
  bool get isHealthConnectAvailable => _isHealthConnectAvailable;
  bool get hasPermissions => _hasPermissions;
  String? get errorMessage => _errorMessage;

  Future<void> refreshAll({
    required UserProfile profile,
    required List<WorkoutModel> workouts,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isHealthConnectAvailable = await _healthRepository
          .isHealthConnectAvailable();
      _hasPermissions = await _healthRepository.hasPermissions();

      final data = await _healthRepository.computeDailyReadiness(
        profile: profile,
        workouts: workouts,
      );

      _recovery = data.recovery;
      _strain = data.strain;
      _recommendation = data.recommendation;
      _sleepSession = data.sleepSession;
      _sleepNight = data.sleepNight;
      _sleepQuality = data.sleepQuality;
      _nightHeartRate = data.nightHeartRate;
      _todayRhr = data.todayRhr;
      _hrSamples = data.hrSamples;
      _steps = data.steps;
      _activeCalories = data.activeCalories;

      _todayCheckIn = await _healthRepository.getTodayCheckIn(
        isDemoMode: profile.isDemoMode,
      );
      _checkInHistory = await _healthRepository.getAllCheckIns(
        isDemoMode: profile.isDemoMode,
      );
      _metricStatuses = await _healthRepository.getMetricStatuses(
        isDemoMode: profile.isDemoMode,
      );
    } catch (e) {
      _errorMessage = 'Error syncing health telemetry: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestPermissions({
    required UserProfile profile,
    required List<WorkoutModel> workouts,
  }) async {
    final granted = await _healthRepository.requestPermissions();
    await refreshAll(profile: profile, workouts: workouts);
    return granted;
  }

  Future<void> revokePermissions({
    required UserProfile profile,
    required List<WorkoutModel> workouts,
  }) async {
    await _healthRepository.revokePermissions();
    await refreshAll(profile: profile, workouts: workouts);
  }

  Future<void> installHealthConnect() async {
    await _healthRepository.installHealthConnect();
  }

  Future<void> submitCheckIn({
    required CheckInModel checkIn,
    required UserProfile profile,
    required List<WorkoutModel> workouts,
  }) async {
    await _healthRepository.saveCheckIn(checkIn);
    _todayCheckIn = checkIn;
    await refreshAll(profile: profile, workouts: workouts);
  }
}
