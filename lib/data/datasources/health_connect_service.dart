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
    if (!Platform.isAndroid) {
      return [];
    }

    await _ensureConfigured();

    final now = DateTime.now();
    final startTime = now.subtract(const Duration(hours: 24));

    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startTime,
        endTime: now,
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

  /// Fetches the nocturnal sleep session, preventing 24+ hour reporting
  /// by isolating last night's session and computing actual stage durations.
  Future<SleepSessionModel?> fetchTodaySleepSession({
    required double targetHours,
  }) async {
    if (!Platform.isAndroid) return null;
    await _ensureConfigured();

    final now = DateTime.now();
    // Look back up to 24 hours to find last night's sleep
    final startTime = now.subtract(const Duration(hours: 24));

    try {
      final points = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.SLEEP_SESSION,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_AWAKE,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_REM,
        ],
        startTime: startTime,
        endTime: now,
      );

      if (points.isEmpty) return null;

      final recordKinds = <HealthDataType, SleepRecordKind>{
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
      final processed = SleepDataProcessor.process(records: records, now: now);
      if (processed == null) return null;

      final dateKey =
          '${processed.session.end.year.toString().padLeft(4, '0')}-${processed.session.end.month.toString().padLeft(2, '0')}-${processed.session.end.day.toString().padLeft(2, '0')}';
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

      /* 1. Separate full sessions from stages
      final sessions =
          points
              .where(
                (p) =>
                    p.type == HealthDataType.SLEEP_SESSION &&
                    p.dateTo.isAfter(p.dateFrom),
              )
              .toList()
            ..sort((a, b) => b.dateTo.compareTo(a.dateTo));

      // Separate individual stage records
      final stagePoints = points
          .where((p) => p.type != HealthDataType.SLEEP_SESSION)
          .toList();

      if (sessions.isNotEmpty) {
        // Find the primary sleep session that ended recently (within last 16 hours)
        final primarySession = sessions.firstWhere(
          (s) => s.dateTo.isAfter(now.subtract(const Duration(hours: 16))),
          orElse: () => sessions.first,
        );

        final rawMinutes = primarySession.dateTo
            .difference(primarySession.dateFrom)
            .inMinutes;

        // Extract stages falling within or near this session
        final sessionStages = stagePoints.where((p) {
          return !p.dateTo.isBefore(
                primarySession.dateFrom.subtract(const Duration(minutes: 30)),
              ) &&
              !p.dateFrom.isAfter(
                primarySession.dateTo.add(const Duration(minutes: 30)),
              );
        }).toList();

        int deepMins = 0;
        int lightMins = 0;
        int remMins = 0;
        int awakeMins = 0;

        for (final sp in sessionStages) {
          final dur = sp.dateTo.difference(sp.dateFrom).inMinutes;
          if (dur <= 0) continue;
          switch (sp.type) {
            case HealthDataType.SLEEP_DEEP:
              deepMins += dur;
              break;
            case HealthDataType.SLEEP_LIGHT:
              lightMins += dur;
              break;
            case HealthDataType.SLEEP_REM:
              remMins += dur;
              break;
            case HealthDataType.SLEEP_AWAKE:
              awakeMins += dur;
              break;
            default:
              break;
          }
        }

        final stagesTotalSleep = deepMins + lightMins + remMins;
        int effectiveTotalMinutes;

        // If stages exist, the true asleep time is the sum of deep + light + rem
        // This directly fixes cases where an unclosed session reports 24+ hours
        if (stagesTotalSleep > 0 && stagesTotalSleep <= 14 * 60) {
          effectiveTotalMinutes = stagesTotalSleep;
        } else if (rawMinutes > 0 && rawMinutes <= 14 * 60) {
          // If raw session is realistic (under 14 hours), subtract awake minutes if known
          effectiveTotalMinutes = (rawMinutes - awakeMins).clamp(60, 14 * 60);
        } else {
          // If session was unclosed/abnormally long (>14 hours, e.g. 24.6h):
          // Bound strictly to a realistic sleep duration (max 10h)
          effectiveTotalMinutes = (targetHours * 60).round().clamp(360, 600);
        }

        final dateKey =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        return SleepSessionModel(
          id: 'hc_sleep_${primarySession.dateFrom.millisecondsSinceEpoch}',
          dateKey: dateKey,
          startTime: primarySession.dateFrom,
          endTime: primarySession.dateTo,
          totalMinutes: effectiveTotalMinutes,
          deepMinutes: deepMins > 0 ? deepMins : null,
          lightMinutes: lightMins > 0 ? lightMins : null,
          remMinutes: remMins > 0 ? remMins : null,
          awakeMinutes: awakeMins > 0 ? awakeMins : null,
          targetMinutes: (targetHours * 60).round(),
        );
      }

      // 2. If no parent SLEEP_SESSION record, cluster nocturnal stages
      final asleepTypes = {
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
      };

      final intervals =
          stagePoints
              .where(
                (p) =>
                    asleepTypes.contains(p.type) &&
                    p.dateTo.isAfter(p.dateFrom),
              )
              .toList()
            ..sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

      if (intervals.isEmpty) return null;

      // Cluster intervals: find the latest night's cluster (gaps < 90 mins)
      final clusters = <List<HealthDataPoint>>[];
      List<HealthDataPoint> currentCluster = [intervals.first];

      for (int i = 1; i < intervals.length; i++) {
        final prev = intervals[i - 1];
        final curr = intervals[i];
        if (curr.dateFrom.difference(prev.dateTo).inMinutes < 90) {
          currentCluster.add(curr);
        } else {
          clusters.add(currentCluster);
          currentCluster = [curr];
        }
      }
      clusters.add(currentCluster);

      // Choose the latest cluster (last night's sleep)
      final primaryCluster = clusters.last;
      int clusterDeep = 0;
      int clusterLight = 0;
      int clusterRem = 0;
      int clusterAwake = 0;
      int clusterTotal = 0;

      for (final p in primaryCluster) {
        final dur = p.dateTo.difference(p.dateFrom).inMinutes;
        if (dur <= 0) continue;
        clusterTotal += dur;
        switch (p.type) {
          case HealthDataType.SLEEP_DEEP:
            clusterDeep += dur;
            break;
          case HealthDataType.SLEEP_LIGHT:
            clusterLight += dur;
            break;
          case HealthDataType.SLEEP_REM:
            clusterRem += dur;
            break;
          default:
            break;
        }
      }

      // Check awake records matching cluster window
      final clusterStart = primaryCluster.first.dateFrom;
      final clusterEnd = primaryCluster.last.dateTo;
      for (final p in stagePoints.where(
        (p) => p.type == HealthDataType.SLEEP_AWAKE,
      )) {
        if (!p.dateTo.isBefore(clusterStart) &&
            !p.dateFrom.isAfter(clusterEnd)) {
          clusterAwake += p.dateTo.difference(p.dateFrom).inMinutes;
        }
      }

      // Clamp cluster duration to a maximum of 14 hours
      final clampedTotal = (clusterDeep + clusterLight + clusterRem > 0)
          ? (clusterDeep + clusterLight + clusterRem)
          : clusterTotal.clamp(60, 14 * 60);

      final dateKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      return SleepSessionModel(
        id: 'hc_sleep_${clusterStart.millisecondsSinceEpoch}',
        dateKey: dateKey,
        startTime: clusterStart,
        endTime: clusterEnd,
        totalMinutes: clampedTotal,
        deepMinutes: clusterDeep > 0 ? clusterDeep : null,
        lightMinutes: clusterLight > 0 ? clusterLight : null,
        remMinutes: clusterRem > 0 ? clusterRem : null,
        awakeMinutes: clusterAwake > 0 ? clusterAwake : null,
        targetMinutes: (targetHours * 60).round(),
      ); */
    } catch (e) {
      debugPrint('Error fetching sleep session: $e');
      return null;
    }
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
    final sleep = await fetchTodaySleepSession(targetHours: 8.0);
    MetricSyncStatus sleepStatus;
    if (!isAvailable) {
      sleepStatus = MetricSyncStatus.unsupported;
    } else if (!hasPerm) {
      sleepStatus = MetricSyncStatus.permissionRequired;
    } else if (sleep != null) {
      sleepStatus = MetricSyncStatus.available;
    } else {
      sleepStatus = MetricSyncStatus.noDataFound;
    }

    metrics.add(
      MetricStatus(
        key: 'sleep',
        title: 'Sleep Sessions',
        description:
            'Nocturnal duration and hypnogram sleep stages (Deep, Light, REM).',
        status: sleepStatus,
        lastValue: sleep != null
            ? '${sleep.hours.toStringAsFixed(1)} hrs'
            : null,
        lastSyncedAt: sleep?.endTime,
        explanation: sleep != null
            ? 'Sleep session verified: ${sleep.hours.toStringAsFixed(1)} hrs recorded (Deep: ${sleep.deepMinutes ?? 0}m, Light: ${sleep.lightMinutes ?? 0}m, REM: ${sleep.remMinutes ?? 0}m).'
            : 'No sleep record detected for last night. Wear your tracker and sync its companion app to Health Connect.',
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
