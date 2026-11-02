import 'dart:math' as math;
import '../models/heart_rate_sample.dart';
import '../models/strain_result.dart';
import '../models/workout_model.dart';

/// Transparent, documented training load calculation.
/// Uses cardiovascular heart rate zones and duration when available,
/// perceived exertion (RPE) for manual workouts, and background daily movement.
class StrainCalculator {
  // Heart rate zone percentage thresholds (percentage of max HR)
  static const double zone1Min = 0.50;
  static const double zone2Min = 0.60;
  static const double zone3Min = 0.70;
  static const double zone4Min = 0.80;
  static const double zone5Min = 0.90;

  // Weight multipliers reflecting exponential cardiovascular stress per zone
  static const double z1Multiplier = 1.0;
  static const double z2Multiplier = 1.5;
  static const double z3Multiplier = 2.5;
  static const double z4Multiplier = 4.5;
  static const double z5Multiplier = 7.0;

  /// Calculates the daily strain score and load analysis.
  static StrainResult calculate({
    required List<WorkoutModel> todayWorkouts,
    required int steps,
    required int activeCalories,
    required int maxHeartRate,
    required List<double> recent7DaysLoads,
    List<bool>? recent7DaysLoadAvailability,
    List<HeartRateSample> hrSamples = const [],
    int? recoveryScore,
    bool stepsAvailable = true,
    bool activeCaloriesAvailable = true,
  }) {
    double totalRawImpulse = 0.0;
    final List<int> totalZoneMinutes = [0, 0, 0, 0, 0];
    bool hasHeartRateData = false;
    bool isMeasured = false;
    final Map<String, double> workoutStrainMap = {};

    // 1. Process workouts
    for (final workout in todayWorkouts) {
      double workoutImpulse = 0.0;

      if (workout.hrZoneMinutes != null && workout.hrZoneMinutes!.length == 5) {
        // High fidelity zone data available
        hasHeartRateData = true;
        isMeasured = !workout.isManual;
        for (int i = 0; i < 5; i++) {
          totalZoneMinutes[i] += workout.hrZoneMinutes![i];
        }
        workoutImpulse = _calculateImpulseFromZones(workout.hrZoneMinutes!);
      } else if (workout.avgHeartRate != null && workout.avgHeartRate! > 0) {
        // Average HR available
        hasHeartRateData = true;
        isMeasured = !workout.isManual;
        final zones = _estimateZonesFromAvgHr(
          durationMinutes: workout.durationMinutes,
          avgHr: workout.avgHeartRate!,
          maxHr: maxHeartRate,
        );
        for (int i = 0; i < 5; i++) {
          totalZoneMinutes[i] += zones[i];
        }
        workoutImpulse = _calculateImpulseFromZones(zones);
      } else {
        // Manual entry or no HR: use perceived exertion (RPE) & duration
        workoutImpulse = _calculateImpulseFromRpe(
          durationMinutes: workout.durationMinutes,
          rpe: workout.rpe,
          type: workout.type,
        );
      }

      totalRawImpulse += workoutImpulse;
      final individualStrain = _mapImpulseToStrainScore(workoutImpulse);
      workoutStrainMap[workout.id] = double.parse(
        individualStrain.toStringAsFixed(1),
      );
    }

    // 2. Continuous heart rate samples (if available and no workout zones recorded)
    if (hrSamples.isNotEmpty) {
      hasHeartRateData = true;
      isMeasured = true;

      // If no workout HR zones were captured, calculate zone minutes from continuous samples
      final totalWorkoutZoneMinutes = totalZoneMinutes.fold<int>(
        0,
        (a, b) => a + b,
      );
      if (totalWorkoutZoneMinutes == 0) {
        final sampleZones = calculateZonesFromHeartRateSamples(
          samples: hrSamples,
          maxHeartRate: maxHeartRate,
        );
        for (int i = 0; i < 5; i++) {
          totalZoneMinutes[i] = sampleZones[i];
        }
      }
    }

    // 3. Daily active movement stimulus (steps / active calories)
    // Capped so walking 10k steps never masquerades as intense HIIT training
    final double backgroundMovementImpulse = _calculateBackgroundImpulse(
      steps: steps,
      activeCalories: activeCalories,
    );
    totalRawImpulse += backgroundMovementImpulse;

    final double movementStrain = double.parse(
      _mapImpulseToStrainScore(backgroundMovementImpulse).toStringAsFixed(1),
    );

    // Convert raw impulse into standard 0.0 to 21.0 athletic strain score
    // Diminishing returns logarithmic curve: S = 21 * (1 - e^(-raw / 135))
    final double score = _mapImpulseToStrainScore(totalRawImpulse);

    // Determine strain category
    final StrainCategory category;
    if (score < 6.0) {
      category = StrainCategory.restorative;
    } else if (score < 10.0) {
      category = StrainCategory.low;
    } else if (score < 14.0) {
      category = StrainCategory.moderate;
    } else if (score < 18.0) {
      category = StrainCategory.high;
    } else {
      category = StrainCategory.allOut;
    }

    // Weekly acute load calculation (rolling 7-day average)
    final List<double> weeklyLoads = List<double>.from(recent7DaysLoads);
    final weeklyAvailability = List<bool>.from(
      recent7DaysLoadAvailability ??
          List<bool>.filled(weeklyLoads.length, true),
    );
    weeklyLoads.add(score);
    weeklyAvailability.add(true);
    if (weeklyLoads.length > 7) {
      weeklyLoads.removeRange(0, weeklyLoads.length - 7);
      weeklyAvailability.removeRange(0, weeklyAvailability.length - 7);
    }

    final availableLoads = <double>[
      for (var i = 0; i < weeklyLoads.length; i++)
        if (i >= weeklyAvailability.length || weeklyAvailability[i])
          weeklyLoads[i],
    ];
    final double acuteSum = availableLoads.fold(0.0, (a, b) => a + b);
    final double acuteLoad = availableLoads.isEmpty
        ? 0.0
        : acuteSum / availableLoads.length;

    // Cardiovascular Load component
    final double cardioImpulse =
        totalRawImpulse - (backgroundMovementImpulse * 0.5);
    final double cardiovascularLoad = double.parse(
      _mapImpulseToStrainScore(
        cardioImpulse > 0 ? cardioImpulse : 0.0,
      ).toStringAsFixed(1),
    );

    // Recommended Strain Target
    final recommendedTarget = calculateRecommendedTarget(recoveryScore);

    // Hourly Daily Progression Points
    final dailyProgression = _calculateDailyProgression(
      todayWorkouts: todayWorkouts,
      steps: steps,
      activeCalories: activeCalories,
      maxHeartRate: maxHeartRate,
      currentDailyStrain: score,
    );

    // Detailed explanation
    final explanation = _generateExplanation(
      score: score,
      workoutCount: todayWorkouts.length,
      hasHeartRateData: hasHeartRateData,
      totalZoneMinutes: totalZoneMinutes,
      steps: steps,
      isMeasured: isMeasured,
    );

    return StrainResult(
      score: double.parse(score.toStringAsFixed(1)),
      category: category,
      totalCalories: null,
      estimatedBasalCalories: null,
      activeCalories: activeCalories,
      steps: steps,
      workoutCount: todayWorkouts.length,
      hrZoneMinutes: totalZoneMinutes,
      weeklyDailyLoads: weeklyLoads,
      acuteLoad: double.parse(acuteLoad.toStringAsFixed(1)),
      explanation: explanation,
      hasHeartRateData: hasHeartRateData,
      isMeasured: isMeasured,
      cardiovascularLoad: cardiovascularLoad,
      movementStrain: movementStrain,
      workoutStrainMap: workoutStrainMap,
      dailyProgression: dailyProgression,
      recommendedTarget: recommendedTarget,
      stepsAvailable: stepsAvailable,
      activeCaloriesAvailable: activeCaloriesAvailable,
      weeklyLoadAvailable: weeklyAvailability,
    );
  }

  /// Calculates individual workout strain score.
  static double calculateWorkoutStrain(WorkoutModel workout, int maxHeartRate) {
    double impulse = 0.0;
    if (workout.hrZoneMinutes != null && workout.hrZoneMinutes!.length == 5) {
      impulse = _calculateImpulseFromZones(workout.hrZoneMinutes!);
    } else if (workout.avgHeartRate != null && workout.avgHeartRate! > 0) {
      final zones = _estimateZonesFromAvgHr(
        durationMinutes: workout.durationMinutes,
        avgHr: workout.avgHeartRate!,
        maxHr: maxHeartRate,
      );
      impulse = _calculateImpulseFromZones(zones);
    } else {
      impulse = _calculateImpulseFromRpe(
        durationMinutes: workout.durationMinutes,
        rpe: workout.rpe,
        type: workout.type,
      );
    }
    return double.parse(_mapImpulseToStrainScore(impulse).toStringAsFixed(1));
  }

  /// Calculates heart rate zone minutes from continuous samples.
  static List<int> calculateZonesFromHeartRateSamples({
    required List<HeartRateSample> samples,
    required int maxHeartRate,
  }) {
    final List<int> zoneMinutes = [0, 0, 0, 0, 0];
    if (samples.isEmpty || maxHeartRate <= 0) return zoneMinutes;

    final z1Bpm = (maxHeartRate * zone1Min).round();
    final z2Bpm = (maxHeartRate * zone2Min).round();
    final z3Bpm = (maxHeartRate * zone3Min).round();
    final z4Bpm = (maxHeartRate * zone4Min).round();
    final z5Bpm = (maxHeartRate * zone5Min).round();

    // Approximate each sample duration based on timestamps (capped at 5 minutes per sample)
    for (int i = 0; i < samples.length; i++) {
      final sample = samples[i];
      int durationMins = 1;
      if (i < samples.length - 1) {
        final diffMins = samples[i + 1].timestamp
            .difference(sample.timestamp)
            .inMinutes;
        durationMins = diffMins.clamp(1, 5);
      }

      if (sample.bpm >= z5Bpm) {
        zoneMinutes[4] += durationMins;
      } else if (sample.bpm >= z4Bpm) {
        zoneMinutes[3] += durationMins;
      } else if (sample.bpm >= z3Bpm) {
        zoneMinutes[2] += durationMins;
      } else if (sample.bpm >= z2Bpm) {
        zoneMinutes[1] += durationMins;
      } else if (sample.bpm >= z1Bpm) {
        zoneMinutes[0] += durationMins;
      }
    }

    return zoneMinutes;
  }

  /// Calculates Recommended Strain target based on Recovery Score.
  static RecommendedStrainTarget calculateRecommendedTarget(
    int? recoveryScore,
  ) {
    if (recoveryScore == null) {
      return const RecommendedStrainTarget(
        minTarget: 8.0,
        maxTarget: 12.0,
        label: 'Baseline Target',
        explanation:
            'Recovery score is establishing. Aim for moderate, steady aerobic volume.',
      );
    }

    if (recoveryScore >= 67) {
      return const RecommendedStrainTarget(
        minTarget: 14.0,
        maxTarget: 18.0,
        label: 'High Optimal',
        explanation:
            'Your physiological markers indicate prime recovery. Your body is primed to absorb heavy training load or speedwork.',
      );
    } else if (recoveryScore >= 34) {
      return const RecommendedStrainTarget(
        minTarget: 10.0,
        maxTarget: 14.0,
        label: 'Moderate Optimal',
        explanation:
            'Maintain steady aerobic base or moderate resistance. Avoid extreme overload to preserve tomorrow’s recovery.',
      );
    } else {
      return const RecommendedStrainTarget(
        minTarget: 0.0,
        maxTarget: 6.0,
        label: 'Restorative Target',
        explanation:
            'Telemetry indicates acute fatigue. Focus on light walking, hydration, and restorative regeneration today.',
      );
    }
  }

  /// Calculates cumulative strain progression throughout the day.
  static List<StrainProgressPoint> _calculateDailyProgression({
    required List<WorkoutModel> todayWorkouts,
    required int steps,
    required int activeCalories,
    required int maxHeartRate,
    required double currentDailyStrain,
  }) {
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day, 6, 0);

    // If current time is early morning, create minimal curve
    if (now.isBefore(morning)) {
      return [
        StrainProgressPoint(
          timestamp: DateTime(now.year, now.month, now.day, 0, 0),
          score: 0.0,
        ),
        StrainProgressPoint(timestamp: now, score: currentDailyStrain),
      ];
    }

    final points = <StrainProgressPoint>[];
    points.add(StrainProgressPoint(timestamp: morning, score: 0.0));

    // Sort workouts chronologically
    final sortedWorkouts = List<WorkoutModel>.from(todayWorkouts)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    double runningImpulse = 0.0;
    final totalBgImpulse = _calculateBackgroundImpulse(
      steps: steps,
      activeCalories: activeCalories,
    );

    // Spread background movement across waking hours until now
    final totalWakingMinutes = now
        .difference(morning)
        .inMinutes
        .clamp(60, 18 * 60);

    DateTime cursor = morning.add(const Duration(hours: 2));

    while (cursor.isBefore(now)) {
      final elapsedMinutes = cursor.difference(morning).inMinutes;
      final movementFraction = (elapsedMinutes / totalWakingMinutes).clamp(
        0.0,
        1.0,
      );
      runningImpulse = totalBgImpulse * movementFraction;

      // Add workout impulses that finished before this cursor
      for (final w in sortedWorkouts) {
        if (!w.startTime.isAfter(cursor)) {
          final wImpulse = calculateWorkoutImpulse(w, maxHeartRate);
          runningImpulse += wImpulse;
        }
      }

      final score = double.parse(
        _mapImpulseToStrainScore(runningImpulse).toStringAsFixed(1),
      );
      points.add(
        StrainProgressPoint(
          timestamp: cursor,
          score: score.clamp(0.0, currentDailyStrain),
        ),
      );
      cursor = cursor.add(const Duration(hours: 2));
    }

    // Add current time point
    points.add(StrainProgressPoint(timestamp: now, score: currentDailyStrain));
    return points;
  }

  /// Calculates raw impulse for a workout.
  static double calculateWorkoutImpulse(
    WorkoutModel workout,
    int maxHeartRate,
  ) {
    if (workout.hrZoneMinutes != null && workout.hrZoneMinutes!.length == 5) {
      return _calculateImpulseFromZones(workout.hrZoneMinutes!);
    } else if (workout.avgHeartRate != null && workout.avgHeartRate! > 0) {
      final zones = _estimateZonesFromAvgHr(
        durationMinutes: workout.durationMinutes,
        avgHr: workout.avgHeartRate!,
        maxHr: maxHeartRate,
      );
      return _calculateImpulseFromZones(zones);
    } else {
      return _calculateImpulseFromRpe(
        durationMinutes: workout.durationMinutes,
        rpe: workout.rpe,
        type: workout.type,
      );
    }
  }

  /// Calculates training impulse from HR zone durations.
  static double _calculateImpulseFromZones(List<int> zoneMinutes) {
    return (zoneMinutes[0] * z1Multiplier) +
        (zoneMinutes[1] * z2Multiplier) +
        (zoneMinutes[2] * z3Multiplier) +
        (zoneMinutes[3] * z4Multiplier) +
        (zoneMinutes[4] * z5Multiplier);
  }

  /// Estimates approximate zone distribution if only average HR is known.
  static List<int> _estimateZonesFromAvgHr({
    required int durationMinutes,
    required int avgHr,
    required int maxHr,
  }) {
    final intensity = maxHr > 0 ? (avgHr / maxHr) : 0.65;
    final List<int> zones = [0, 0, 0, 0, 0];

    if (intensity < zone2Min) {
      zones[0] = durationMinutes;
    } else if (intensity < zone3Min) {
      zones[0] = (durationMinutes * 0.25).round();
      zones[1] = durationMinutes - zones[0];
    } else if (intensity < zone4Min) {
      zones[1] = (durationMinutes * 0.35).round();
      zones[2] = durationMinutes - zones[1];
    } else if (intensity < zone5Min) {
      zones[2] = (durationMinutes * 0.30).round();
      zones[3] = durationMinutes - zones[2];
    } else {
      zones[3] = (durationMinutes * 0.40).round();
      zones[4] = durationMinutes - zones[3];
    }
    return zones;
  }

  /// Calculates impulse from subjective RPE (1-10) and duration.
  static double _calculateImpulseFromRpe({
    required int durationMinutes,
    required int rpe,
    required WorkoutType type,
  }) {
    final clampedRpe = rpe.clamp(1, 10);
    // Exponential perceived exertion factor: (RPE / 5)^1.6
    final rpeMultiplier = math.pow(clampedRpe / 5.0, 1.6).toDouble();

    double sportFactor = 1.0;
    if (type == WorkoutType.hiit) sportFactor = 1.3;
    if (type == WorkoutType.running) sportFactor = 1.15;
    if (type == WorkoutType.strength) sportFactor = 1.0;
    if (type == WorkoutType.walking) sportFactor = 0.6;

    return durationMinutes * rpeMultiplier * sportFactor * 1.5;
  }

  /// Calculates background non-workout movement impulse (capped at 30.0).
  static double _calculateBackgroundImpulse({
    required int steps,
    required int activeCalories,
  }) {
    // 1,000 steps roughly equals 1.2 background impulse, capped at 20.0
    final stepsImpulse = (steps / 1000.0) * 1.2;
    // 100 active calories outside workouts equals ~2.0 impulse, capped at 15.0
    final caloriesImpulse = (activeCalories / 100.0) * 2.0;

    final combined = (stepsImpulse * 0.5) + (caloriesImpulse * 0.5);
    return combined.clamp(0.0, 30.0);
  }

  /// Maps raw physiological impulse to the 0.0 - 21.0 logarithmic scale.
  static double _mapImpulseToStrainScore(double rawImpulse) {
    if (rawImpulse <= 0.0) return 0.0;
    // Asymptote at 21.0
    final score = 21.0 * (1.0 - math.exp(-rawImpulse / 135.0));
    return score.clamp(0.0, 21.0);
  }

  static String _generateExplanation({
    required double score,
    required int workoutCount,
    required bool hasHeartRateData,
    required List<int> totalZoneMinutes,
    required int steps,
    required bool isMeasured,
  }) {
    final buffer = StringBuffer();
    buffer.write('Daily strain of ${score.toStringAsFixed(1)} based on ');

    if (workoutCount > 0) {
      buffer.write(
        '$workoutCount workout session${workoutCount > 1 ? 's' : ''} ',
      );
      if (hasHeartRateData && isMeasured) {
        final highZones = totalZoneMinutes[3] + totalZoneMinutes[4];
        buffer.write(
          'with ${highZones}m in threshold/anaerobic zones (Z4/Z5) measured by sensor. ',
        );
      } else {
        buffer.write('using duration and perceived exertion ratings (RPE). ');
      }
    } else {
      buffer.write(
        'baseline daily movement of $steps steps without recorded workouts. ',
      );
    }

    buffer.write(StrainResult.disclaimer);
    return buffer.toString();
  }
}
