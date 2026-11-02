import '../../domain/models/checkin_model.dart';
import '../../domain/models/heart_rate_sample.dart';
import '../../domain/models/metric_status_model.dart';
import '../../domain/models/sleep_session_model.dart';
import '../../domain/models/workout_model.dart';

/// Provides realistic athletic telemetry for Demo Mode testing.
/// Clearly labeled as synthetic data across the UI.
class MockDataGenerator {
  static final DateTime _now = DateTime.now();

  static SleepSessionModel getMockSleepSession({double targetHours = 8.0}) {
    final dateKey =
        '${_now.year.toString().padLeft(4, '0')}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}';
    final start = DateTime(
      _now.year,
      _now.month,
      _now.day,
      23,
      15,
    ).subtract(const Duration(days: 1));
    final end = DateTime(_now.year, _now.month, _now.day, 6, 57);

    return SleepSessionModel(
      id: 'demo_sleep_$dateKey',
      dateKey: dateKey,
      startTime: start,
      endTime: end,
      totalMinutes: 462, // 7h 42m
      deepMinutes: 98,
      lightMinutes: 214,
      remMinutes: 104,
      awakeMinutes: 46,
      targetMinutes: (targetHours * 60).round(),
      consistencyScore: 89.0,
    );
  }

  static double getMockTodayRhr() => 56.0;

  static List<double> getMockHistoricalRhrs() => [59.0, 58.0, 57.0, 58.0, 57.0];

  static int getMockSteps() => 9420;

  static int getMockActiveCalories() => 640;

  static List<HeartRateSample> getMockHeartRateSamples() {
    return [
      HeartRateSample(
        timestamp: _now.subtract(const Duration(hours: 8)),
        bpm: 54,
      ),
      HeartRateSample(
        timestamp: _now.subtract(const Duration(hours: 7)),
        bpm: 58,
      ),
      HeartRateSample(
        timestamp: _now.subtract(const Duration(hours: 5)),
        bpm: 72,
      ),
      HeartRateSample(
        timestamp: _now.subtract(const Duration(hours: 4)),
        bpm: 142,
      ),
      HeartRateSample(
        timestamp: _now.subtract(const Duration(hours: 3, minutes: 40)),
        bpm: 171,
      ),
      HeartRateSample(
        timestamp: _now.subtract(const Duration(hours: 3, minutes: 20)),
        bpm: 155,
      ),
      HeartRateSample(
        timestamp: _now.subtract(const Duration(hours: 2)),
        bpm: 84,
      ),
      HeartRateSample(
        timestamp: _now.subtract(const Duration(hours: 1)),
        bpm: 68,
      ),
      HeartRateSample(
        timestamp: _now.subtract(const Duration(minutes: 15)),
        bpm: 62,
      ),
    ];
  }

  static List<WorkoutModel> getMockWorkouts() {
    return [
      WorkoutModel(
        id: 'demo_w1',
        title: 'Morning Aerobic Intervals',
        type: WorkoutType.running,
        startTime: _now.subtract(const Duration(hours: 4)),
        durationMinutes: 45,
        avgHeartRate: 154,
        maxHeartRate: 174,
        caloriesBurned: 460,
        rpe: 7,
        isManual: false,
        hrZoneMinutes: [4, 12, 17, 10, 2],
        notes: 'Synthetic tracker workout. Clean pace in Zone 3 and Zone 4.',
      ),
    ];
  }

  static CheckInModel getMockCheckIn() {
    final dateKey =
        '${_now.year.toString().padLeft(4, '0')}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}';
    return CheckInModel(
      id: 999,
      dateKey: dateKey,
      energy: 8,
      muscleSoreness: 2,
      fatigue: 2,
      notes:
          'Woke up feeling energetic. Minor quad soreness from squats 2 days ago.',
      timestamp: _now.subtract(const Duration(hours: 3)),
    );
  }

  static List<double> getMockWeeklyStrain() => [
    11.2,
    14.5,
    7.8,
    15.6,
    9.4,
    13.8,
    12.6,
  ];

  static List<int> getMockWeeklyRecovery() => [74, 82, 65, 88, 58, 86, 84];

  static List<MetricStatus> getMockMetricStatuses() {
    return [
      MetricStatus(
        key: 'steps',
        title: 'Daily Steps',
        description:
            'Passive step accumulation tracking general daily activity.',
        status: MetricSyncStatus.available,
        lastValue: '9,420 steps',
        lastSyncedAt: _now.subtract(const Duration(minutes: 12)),
        explanation: '[DEMO MODE] Fictional step telemetry active.',
      ),
      MetricStatus(
        key: 'rhr',
        title: 'Resting Heart Rate',
        description: 'Basal resting heart rate for baseline calibration.',
        status: MetricSyncStatus.available,
        lastValue: '56 bpm (Baseline: 57.8)',
        lastSyncedAt: _now.subtract(const Duration(hours: 4)),
        explanation:
            '[DEMO MODE] 5-day established personal baseline of 57.8 bpm.',
      ),
      MetricStatus(
        key: 'heart_rate',
        title: 'Heart Rate Samples',
        description: 'Continuous biometric heart rate monitoring.',
        status: MetricSyncStatus.available,
        lastValue: '62 bpm',
        lastSyncedAt: _now.subtract(const Duration(minutes: 5)),
        explanation: '[DEMO MODE] Simulated optical sensor stream.',
      ),
      MetricStatus(
        key: 'sleep',
        title: 'Sleep Sessions',
        description: 'Total duration and hypnogram sleep stages.',
        status: MetricSyncStatus.available,
        lastValue: '7.7 hrs (98m Deep, 104m REM)',
        lastSyncedAt: _now.subtract(const Duration(hours: 5)),
        explanation: '[DEMO MODE] Fictional sleep session synced.',
      ),
      MetricStatus(
        key: 'active_calories',
        title: 'Active Calories',
        description: 'Energy expenditure from active movement.',
        status: MetricSyncStatus.available,
        lastValue: '640 kcal',
        lastSyncedAt: _now.subtract(const Duration(minutes: 12)),
        explanation: '[DEMO MODE] Simulated active energy burned.',
      ),
      MetricStatus(
        key: 'workouts',
        title: 'Exercise & Workout Sessions',
        description: 'Dedicated sport sessions with HR telemetry.',
        status: MetricSyncStatus.available,
        lastValue: '1 workout (45 min Running)',
        lastSyncedAt: _now.subtract(const Duration(hours: 4)),
        explanation: '[DEMO MODE] Running workout with 5 HR zones.',
      ),
    ];
  }
}
