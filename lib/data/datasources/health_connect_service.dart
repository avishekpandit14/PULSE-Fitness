import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../../domain/models/heart_rate_sample.dart';
import '../../domain/models/metric_status_model.dart';
import '../../domain/models/sleep_session_model.dart';
import '../../domain/models/workout_model.dart';
import '../../domain/algorithms/sleep_data_processor.dart';

class HealthConnectService {
  final Health _health = Health();
  bool _isConfigured = false;

  static final List<HealthDataType> readTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.WORKOUT,
  ];

  Future<void> _ensureConfigured() async {
    if (!_isConfigured) {
      try {
        await _health.configure();
        _isConfigured = true;
      } catch (e) {
        debugPrint('HealthConnectService configure error: $e');
      }
    }
  }

  /// Checks if Health Connect is installed and operational on this device
  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return false;
    await _ensureConfigured();
    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (e) {
      debugPrint('Error checking Health Connect availability: $e');
      return false;
    }
  }

  /// Checks whether general read permissions are granted
  Future<bool> hasPermissions() async {
    if (!Platform.isAndroid) return false;
    await _ensureConfigured();
    try {
      final has = await _health.hasPermissions(readTypes);
      return has ?? false;
    } catch (e) {
      debugPrint('Error checking Health Connect permissions: $e');
      return false;
    }
  }

  /// Checks specific permission for Heart Rate
  Future<bool> hasHeartRatePermission() async {
    if (!Platform.isAndroid) return false;
    await _ensureConfigured();
    try {
      final has = await _health.hasPermissions([HealthDataType.HEART_RATE]);
      return has ?? false;
    } catch (e) {
      debugPrint('Error checking HR permission: $e');
      return false;
    }
  }

  /// Checks specific permission for Resting Heart Rate
  Future<bool> hasRestingHeartRatePermission() async {
    if (!Platform.isAndroid) return false;
    await _ensureConfigured();
    try {
      final has = await _health.hasPermissions([
        HealthDataType.RESTING_HEART_RATE,
      ]);
      return has ?? false;
    } catch (e) {
      debugPrint('Error checking Resting HR permission: $e');
      return false;
    }
  }

  /// Requests permission to read Health Connect data types
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;
    await _ensureConfigured();
    try {
      return await _health.requestAuthorization(readTypes);
    } catch (e) {
      debugPrint('Error requesting Health Connect permissions: $e');
      return false;
    }
  }

  /// Revokes permissions
  Future<void> revokePermissions() async {
    if (!Platform.isAndroid) return;
    await _ensureConfigured();
    try {
      await _health.revokePermissions();
    } catch (e) {
      debugPrint('Error revoking permissions: $e');
    }
  }

  /// Opens Health Connect app in Play Store for installation
  Future<void> installHealthConnect() async {
    if (!Platform.isAndroid) return;
    await _ensureConfigured();
    try {
      await _health.installHealthConnect();
    } catch (e) {
      debugPrint('Error opening Health Connect install: $e');
    }
  }

  /// Fetches today's total steps
  Future<int> fetchTodaySteps() async {
    if (!Platform.isAndroid) return 0;
    await _ensureConfigured();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      debugPrint('Error fetching steps from Health Connect: $e');
      return 0;
    }
  }

  Future<int?> fetchTodayStepsOrNull() async {
    if (!Platform.isAndroid) return null;
    await _ensureConfigured();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      return await _health.getTotalStepsInInterval(midnight, now);
    } catch (e) {
      debugPrint('Error fetching steps from Health Connect: $e');
      return null;
    }
  }

  /// Fetches the most recent available resting heart rate.
  Future<double?> fetchTodayRestingHeartRate() async {
    if (!Platform.isAndroid) return null;
    await _ensureConfigured();

    final now = DateTime.now();
    final startTime = now.subtract(const Duration(days: 7));

    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.RESTING_HEART_RATE],
        startTime: startTime,
        endTime: now,
      );

      final validPoints =
          points
              .where(
                (p) =>
                    p.value is NumericHealthValue &&
                    p.dateFrom.isBefore(now) &&
                    !p.dateFrom.isBefore(startTime),
              )
              .toList()
            ..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));

      if (validPoints.isEmpty) return null;

      final val = (validPoints.first.value as NumericHealthValue).numericValue
          .toDouble();
      if (val >= 30 && val <= 180) {
        return val;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching resting HR from Health Connect: $e');
      return null;
    }
  }

  /// Fetches heart-rate samples from today (with fallback to last 24 hours).
  Future<List<HeartRateSample>> fetchTodayHeartRateSamples() async {
    final now = DateTime.now();
    return fetchHeartRateSamples(
      start: now.subtract(const Duration(hours: 24)),
      end: now,
    );
  }

  /// Fetches continuous heart rate samples inside an explicit window. Used to
  /// slice the primary sleep window for nighttime HR analysis.
  Future<List<HeartRateSample>> fetchHeartRateSamples({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!Platform.isAndroid) {
      return [];
    }

    await _ensureConfigured();

    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );

      final samples = <HeartRateSample>[];

      for (final p in points) {
        if (p.value is! NumericHealthValue) continue;

        final value = (p.value as NumericHealthValue).numericValue;
        if (!value.isFinite || value <= 30 || value > 250) continue;

        samples.add(HeartRateSample(timestamp: p.dateFrom, bpm: value.round()));
      }

      samples.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return samples;
    } catch (e) {
      debugPrint('Health Connect HR query error: $e');
      return [];
    }
  }

  /// Fetches active calories burned today
  Future<int> fetchTodayActiveCalories() async {
    if (!Platform.isAndroid) return 0;
    await _ensureConfigured();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );
      double total = 0.0;
      for (final p in points) {
        if (p.value is NumericHealthValue) {
          total += (p.value as NumericHealthValue).numericValue;
        }
      }
      return total.round();
    } catch (e) {
      debugPrint('Error fetching calories: $e');
      return 0;
    }
  }

  Future<int?> fetchTodayActiveCaloriesOrNull() async {
    if (!Platform.isAndroid) return null;
    await _ensureConfigured();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );
      if (points.isEmpty) return null;
      double total = 0;
      for (final point in points) {
        if (point.value is NumericHealthValue) {
          total += (point.value as NumericHealthValue).numericValue;
        }
      }
      return total.round();
    } catch (e) {
      debugPrint('Error fetching calories: $e');
      return null;
    }
  }

  /// Fetches last night's sleep, split into the primary nighttime session and
  /// any naps that were also recorded.
  ///
  /// Naps are reported separately and never replace the primary session.
  Future<SleepNightReport> fetchSleepNight({
    required double targetHours,
  }) async {
    if (!Platform.isAndroid) return SleepNightReport.empty;
    await _ensureConfigured();

    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(hours: 24));

    try {
      final points = await _fetchSleepPoints(start: windowStart, end: now);
      if (points.isEmpty) return SleepNightReport.empty;

      const recordKinds = <HealthDataType, SleepRecordKind>{
        HealthDataType.SLEEP_SESSION: SleepRecordKind.session,
        HealthDataType.SLEEP_ASLEEP: SleepRecordKind.asleep,
        HealthDataType.SLEEP_DEEP: SleepRecordKind.deep,
        HealthDataType.SLEEP_LIGHT: SleepRecordKind.light,
        HealthDataType.SLEEP_REM: SleepRecordKind.rem,
        HealthDataType.SLEEP_AWAKE: SleepRecordKind.awake,
      };

      final records = points
          .where((point) => recordKinds.containsKey(point.type))
          .map(
            (point) => SleepRecord(
              kind: recordKinds[point.type]!,
              start: point.dateFrom,
              end: point.dateTo,
              id: point.uuid,
            ),
          )
          .toList();

      final night = SleepDataProcessor.processNight(records: records, now: now);
      if (night == null) return SleepNightReport.empty;

      return SleepNightReport(
        primary: _toSleepSessionModel(night.primary, targetHours: targetHours),
        naps: night.naps
            .map(
              (nap) => SleepNap(
                startTime: nap.start,
                endTime: nap.end,
                minutes: nap.minutes,
              ),
            )
            .toList(),
        napMinutes: night.napMinutes,
        primaryIsNighttime: night.primaryIsNighttime,
      );
    } catch (e) {
      debugPrint('Error fetching sleep night: $e');
      return SleepNightReport.empty;
    }
  }

  /// Queries all sleep types at once, then falls back to one type at a time so
  /// that a single unauthorised or unsupported stage type cannot hide the
  /// sessions that *are* available.
  Future<List<HealthDataPoint>> _fetchSleepPoints({
    required DateTime start,
    required DateTime end,
  }) async {
    const types = <HealthDataType>[
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
    ];

    try {
      return await _health.getHealthDataFromTypes(
        types: types,
        startTime: start,
        endTime: end,
      );
    } catch (e) {
      debugPrint('Health Connect combined sleep query failed: $e');
    }

    final collected = <HealthDataPoint>[];
    for (final type in types) {
      try {
        collected.addAll(
          await _health.getHealthDataFromTypes(
            types: [type],
            startTime: start,
            endTime: end,
          ),
        );
      } catch (e) {
        debugPrint('Health Connect $type unavailable: $e');
      }
    }
    return collected;
  }

  SleepSessionModel _toSleepSessionModel(
    ProcessedSleepData processed, {
    required double targetHours,
  }) {
    final end = processed.session.end;
    final dateKey =
        '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    return SleepSessionModel(
      id: 'hc_sleep_${processed.session.start.millisecondsSinceEpoch}',
      dateKey: dateKey,
      startTime: processed.session.start,
      endTime: processed.session.end,
      totalMinutes: processed.totalMinutes,
      deepMinutes: processed.deepMinutes,
      lightMinutes: processed.lightMinutes,
      remMinutes: processed.remMinutes,
      awakeMinutes: processed.awakeMinutes,
      targetMinutes: (targetHours * 60).round(),
      dataQuality: processed.dataQuality,
      unknownMinutes: processed.unknownMinutes,
    );
  }

  /// Fetches workouts recorded in Health Connect
  Future<List<WorkoutModel>> fetchTodayWorkouts() async {
    if (!Platform.isAndroid) return [];
    await _ensureConfigured();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: midnight,
        endTime: now,
      );

      final workouts = <WorkoutModel>[];
      for (final p in points) {
        final duration = p.dateTo.difference(p.dateFrom).inMinutes;
        int? calories;
        WorkoutType type = WorkoutType.other;

        if (p.value is WorkoutHealthValue) {
          final wv = p.value as WorkoutHealthValue;
          calories = wv.totalEnergyBurned;
          final actName = wv.workoutActivityType.name.toLowerCase();
          type = WorkoutType.fromString(actName);
        }

        workouts.add(
          WorkoutModel(
            id: p.uuid,
            title: '${type.displayName} Session',
            type: type,
            startTime: p.dateFrom,
            durationMinutes: duration > 0 ? duration : 30,
            caloriesBurned: calories,
            isManual: false,
          ),
        );
      }
      return workouts;
    } catch (e) {
      debugPrint('Error fetching workouts: $e');
      return [];
    }
  }

  /// Queries real connection diagnostic status for each metric
  /// with thorough diagnosis distinguishing empty query from permission or query error.
  Future<List<MetricStatus>> getDetailedMetricStatuses() async {
    final isAvailable = await isHealthConnectAvailable();
    final hasPerm = await hasPermissions();
    final hasHrPerm = await hasHeartRatePermission();
    final hasRhrPerm = await hasRestingHeartRatePermission();

    final metrics = <MetricStatus>[];

    // 1. Steps
    final steps = await fetchTodayStepsOrNull();
    MetricSyncStatus stepsStatus;
    if (!isAvailable) {
      stepsStatus = MetricSyncStatus.unsupported;
    } else if (!hasPerm) {
      stepsStatus = MetricSyncStatus.permissionRequired;
    } else if (steps != null) {
      stepsStatus = MetricSyncStatus.available;
    } else {
      stepsStatus = MetricSyncStatus.noDataFound;
    }

    metrics.add(
      MetricStatus(
        key: 'steps',
        title: 'Daily Steps',
        description:
            'Passive step accumulation tracking general daily activity.',
        status: stepsStatus,
        lastValue: steps != null ? '$steps steps' : null,
        lastSyncedAt: steps != null ? DateTime.now() : null,
        explanation: steps != null
            ? 'Active steps verified and synced from Health Connect.'
            : 'No step records written today. Check that your tracker app has permission to write Steps to Health Connect.',
      ),
    );

    // 2. Resting Heart Rate
    final rhr = await fetchTodayRestingHeartRate();
    MetricSyncStatus rhrStatus;
    String rhrExplanation;

    if (!isAvailable) {
      rhrStatus = MetricSyncStatus.unsupported;
      rhrExplanation = 'Health Connect is not available on this device.';
    } else if (!hasRhrPerm) {
      rhrStatus = MetricSyncStatus.permissionRequired;
      rhrExplanation =
          'Permission READ_RESTING_HEART_RATE has not been granted. Tap "Request Access".';
    } else if (rhr != null) {
      rhrStatus = MetricSyncStatus.available;
      rhrExplanation = 'Resting heart rate verified from Health Connect.';
    } else {
      rhrStatus = MetricSyncStatus.noDataFound;
      rhrExplanation =
          'Health Connect permission is active and query succeeded, but 0 records were returned for RestingHeartRateRecord. '
          'The connected tracker or its companion app did not write a RestingHeartRateRecord. '
          'PULSE excludes this signal rather than treating it as zero or fabricating a value.';
    }

    metrics.add(
      MetricStatus(
        key: 'rhr',
        title: 'Resting Heart Rate',
        description:
            'Nocturnal / waking basal resting heart rate for baseline calibration.',
        status: rhrStatus,
        lastValue: rhr != null ? '${rhr.round()} bpm' : null,
        lastSyncedAt: rhr != null ? DateTime.now() : null,
        explanation: rhrExplanation,
      ),
    );

    // 3. Heart Rate Samples
    final hrSamples = await fetchTodayHeartRateSamples();
    MetricSyncStatus hrStatus;
    String hrExplanation;

    if (!isAvailable) {
      hrStatus = MetricSyncStatus.unsupported;
      hrExplanation = 'Health Connect is not available on this device.';
    } else if (!hasHrPerm) {
      hrStatus = MetricSyncStatus.permissionRequired;
      hrExplanation =
          'Permission READ_HEART_RATE has not been granted. Tap "Request Access".';
    } else if (hrSamples.isNotEmpty) {
      hrStatus = MetricSyncStatus.available;
      hrExplanation =
          '${hrSamples.length} continuous heart-rate samples synced from Health Connect.';
    } else {
      hrStatus = MetricSyncStatus.noDataFound;
      hrExplanation =
          'Health Connect permission is active and query succeeded across the last 24 hours, but 0 records were returned. '
          'The connected tracker may only write heart-rate records during workouts. '
          'PULSE estimates cardiovascular strain through workout duration, RPE, and movement when direct samples are absent.';
    }

    metrics.add(
      MetricStatus(
        key: 'heart_rate',
        title: 'Heart Rate Telemetry',
        description:
            'Continuous biometric heart rate monitoring during rest and workouts.',
        status: hrStatus,
        lastValue: hrSamples.isNotEmpty ? '${hrSamples.last.bpm} bpm' : null,
        lastSyncedAt: hrSamples.isNotEmpty ? hrSamples.last.timestamp : null,
        explanation: hrExplanation,
      ),
    );

    // 4. Sleep Session
    final sleepNight = await fetchSleepNight(targetHours: 8.0);
    final sleep = sleepNight.primary;
    final hasSleep = sleep != null && sleep.totalMinutes > 0;
    MetricSyncStatus sleepStatus;
    if (!isAvailable) {
      sleepStatus = MetricSyncStatus.unsupported;
    } else if (!hasPerm) {
      sleepStatus = MetricSyncStatus.permissionRequired;
    } else if (hasSleep) {
      sleepStatus = MetricSyncStatus.available;
    } else {
      sleepStatus = MetricSyncStatus.noDataFound;
    }

    final napNote = sleepNight.napMinutes > 0
        ? ' Naps tracked separately: ${sleepNight.napMinutes}m (not part of '
              'the night score).'
        : '';
    String? sleepExplanation;
    if (hasSleep) {
      String stage(int? minutes) =>
          minutes == null ? 'unavailable' : '${minutes}m';
      sleepExplanation =
          'Nighttime sleep verified: ${sleep.hours.toStringAsFixed(1)} hrs '
          '(Deep: ${stage(sleep.deepMinutes)}, Light: '
          '${stage(sleep.lightMinutes)}, REM: ${stage(sleep.remMinutes)}).'
          '$napNote';
    }

    metrics.add(
      MetricStatus(
        key: 'sleep',
        title: 'Sleep Sessions',
        description:
            'Nocturnal duration and hypnogram sleep stages (Deep, Light, REM).',
        status: sleepStatus,
        lastValue: hasSleep ? '${sleep.hours.toStringAsFixed(1)} hrs' : null,
        lastSyncedAt: sleep?.endTime,
        explanation:
            sleepExplanation ??
            'No sleep record detected for last night. Wear your tracker and sync its companion app to Health Connect.',
      ),
    );

    // 5. Active Calories
    final calories = await fetchTodayActiveCaloriesOrNull();
    MetricSyncStatus calStatus;
    if (!isAvailable) {
      calStatus = MetricSyncStatus.unsupported;
    } else if (!hasPerm) {
      calStatus = MetricSyncStatus.permissionRequired;
    } else if (calories != null) {
      calStatus = MetricSyncStatus.available;
    } else {
      calStatus = MetricSyncStatus.noDataFound;
    }

    metrics.add(
      MetricStatus(
        key: 'active_calories',
        title: 'Active Calories',
        description: 'Energy expenditure from active movement and exercise.',
        status: calStatus,
        lastValue: calories != null ? '$calories kcal' : null,
        lastSyncedAt: calories != null ? DateTime.now() : null,
        explanation: calories != null
            ? 'Active calorie expenditure recorded.'
            : 'No active calorie records written today.',
      ),
    );

    // 6. Workouts / Exercise Sessions
    final workouts = await fetchTodayWorkouts();
    MetricSyncStatus workoutStatus;
    if (!isAvailable) {
      workoutStatus = MetricSyncStatus.unsupported;
    } else if (!hasPerm) {
      workoutStatus = MetricSyncStatus.permissionRequired;
    } else if (workouts.isNotEmpty) {
      workoutStatus = MetricSyncStatus.available;
    } else {
      workoutStatus = MetricSyncStatus.noDataFound;
    }

    metrics.add(
      MetricStatus(
        key: 'workouts',
        title: 'Exercise & Workout Sessions',
        description:
            'Dedicated sport sessions (Running, Cycling, Strength, etc.).',
        status: workoutStatus,
        lastValue: workouts.isNotEmpty ? '${workouts.length} workouts' : null,
        lastSyncedAt: workouts.isNotEmpty ? workouts.first.startTime : null,
        explanation: workouts.isNotEmpty
            ? '${workouts.length} workout session(s) detected.'
            : 'No automatic workouts written to Health Connect today. You can log manual workouts anytime in the Strain tab.',
      ),
    );

    return metrics;
  }
}
