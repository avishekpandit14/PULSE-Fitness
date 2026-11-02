import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_fitness/domain/algorithms/recommendation_engine.dart';
import 'package:pulse_fitness/domain/algorithms/strain_calculator.dart';
import 'package:pulse_fitness/domain/models/heart_rate_sample.dart';
import 'package:pulse_fitness/domain/models/recommendation_result.dart';
import 'package:pulse_fitness/domain/models/recovery_result.dart';
import 'package:pulse_fitness/domain/models/strain_result.dart';
import 'package:pulse_fitness/domain/models/workout_model.dart';

void main() {
  group('StrainCalculator Unit Tests', () {
    test('Zero workouts and minimal movement yields very low strain', () {
      final result = StrainCalculator.calculate(
        todayWorkouts: [],
        steps: 800,
        activeCalories: 45,
        maxHeartRate: 190,
        recent7DaysLoads: [10.0, 11.0, 9.0],
      );

      expect(result.score, lessThan(3.0));
      expect(result.category, equals(StrainCategory.restorative));
      expect(result.workoutCount, equals(0));
    });

    test(
      'High intensity intervals with zone 4/5 yields high/all-out strain',
      () {
        final workout = WorkoutModel(
          id: 'w1',
          title: 'Track Intervals',
          type: WorkoutType.running,
          startTime: DateTime.now().subtract(const Duration(minutes: 55)),
          durationMinutes: 55,
          avgHeartRate: 172,
          maxHeartRate: 188,
          caloriesBurned: 620,
          hrZoneMinutes: [5, 10, 10, 20, 10], // Heavy in Z4 and Z5
        );

        final result = StrainCalculator.calculate(
          todayWorkouts: [workout],
          steps: 12000,
          activeCalories: 750,
          maxHeartRate: 190,
          recent7DaysLoads: [12.0, 14.0, 10.0],
        );

        expect(result.score, greaterThan(13.5));
        expect(result.hasHeartRateData, isTrue);
        expect(result.hrZoneMinutes[3], equals(20));
        expect(result.hrZoneMinutes[4], equals(10));
      },
    );

    test('Manual workout entry calculates load from RPE and duration', () {
      final manualWorkout = WorkoutModel(
        id: 'manual_1',
        title: 'Heavy Deadlifts',
        type: WorkoutType.strength,
        startTime: DateTime.now().subtract(const Duration(minutes: 60)),
        durationMinutes: 60,
        rpe: 8, // High perceived exertion
        isManual: true,
      );

      final result = StrainCalculator.calculate(
        todayWorkouts: [manualWorkout],
        steps: 4000,
        activeCalories: 250,
        maxHeartRate: 190,
        recent7DaysLoads: [8.0],
      );

      expect(result.score, greaterThan(8.0));
      expect(result.score, lessThan(18.0));
      expect(result.workoutCount, equals(1));
    });

    test(
      'Background steps and calories cannot artificially produce extreme workout strain',
      () {
        // 25,000 steps without workout
        final result = StrainCalculator.calculate(
          todayWorkouts: [],
          steps: 25000,
          activeCalories: 900,
          maxHeartRate: 190,
          recent7DaysLoads: [],
        );

        // Capped so daily walking alone stays in restorative/low bracket
        expect(result.score, lessThan(8.5));
        expect(result.category, equals(StrainCategory.restorative));
      },
    );

    test('Heart rate samples are deterministically mapped to 5 zones', () {
      final now = DateTime.now();
      // Max HR = 200 bpm:
      // Z1: 50-60% = 100-119 bpm
      // Z2: 60-70% = 120-139 bpm
      // Z3: 70-80% = 140-159 bpm
      // Z4: 80-90% = 160-179 bpm
      // Z5: 90-100% = 180-200 bpm
      final samples = [
        HeartRateSample(
          timestamp: now.subtract(const Duration(minutes: 5)),
          bpm: 110,
        ),
        HeartRateSample(
          timestamp: now.subtract(const Duration(minutes: 4)),
          bpm: 130,
        ),
        HeartRateSample(
          timestamp: now.subtract(const Duration(minutes: 3)),
          bpm: 150,
        ),
        HeartRateSample(
          timestamp: now.subtract(const Duration(minutes: 2)),
          bpm: 170,
        ),
        HeartRateSample(
          timestamp: now.subtract(const Duration(minutes: 1)),
          bpm: 190,
        ),
      ];

      final zones = StrainCalculator.calculateZonesFromHeartRateSamples(
        samples: samples,
        maxHeartRate: 200,
      );

      expect(zones.length, equals(5));
      expect(zones[0], equals(1)); // Z1
      expect(zones[1], equals(1)); // Z2
      expect(zones[2], equals(1)); // Z3
      expect(zones[3], equals(1)); // Z4
      expect(zones[4], equals(1)); // Z5
    });

    test('Recommended strain target adapts dynamically to recovery score', () {
      final highRecTarget = StrainCalculator.calculateRecommendedTarget(85);
      expect(highRecTarget.minTarget, equals(14.0));
      expect(highRecTarget.maxTarget, equals(18.0));
      expect(highRecTarget.getTargetStatus(15.5), equals('In Target Zone'));
      expect(highRecTarget.getTargetStatus(10.0), equals('Below Target'));
      expect(highRecTarget.getTargetStatus(19.0), equals('Overreaching'));

      final modRecTarget = StrainCalculator.calculateRecommendedTarget(50);
      expect(modRecTarget.minTarget, equals(10.0));
      expect(modRecTarget.maxTarget, equals(14.0));

      final lowRecTarget = StrainCalculator.calculateRecommendedTarget(20);
      expect(lowRecTarget.minTarget, equals(0.0));
      expect(lowRecTarget.maxTarget, equals(6.0));
    });

    test('Workout strain maps to individual workouts without fabrication', () {
      final workout1 = WorkoutModel(
        id: 'w1',
        title: 'Morning 5K',
        type: WorkoutType.running,
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
        durationMinutes: 30,
        avgHeartRate: 155,
        maxHeartRate: 175,
        caloriesBurned: 350,
      );

      final workout2 = WorkoutModel(
        id: 'w2',
        title: 'Evening Walk',
        type: WorkoutType.walking,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        durationMinutes: 20,
        caloriesBurned: 100,
        rpe: 3,
        isManual: true,
      );

      final result = StrainCalculator.calculate(
        todayWorkouts: [workout1, workout2],
        steps: 8000,
        activeCalories: 450,
        maxHeartRate: 190,
        recent7DaysLoads: [10.0],
      );

      expect(result.workoutStrainMap.containsKey('w1'), isTrue);
      expect(result.workoutStrainMap.containsKey('w2'), isTrue);
      expect(
        result.workoutStrainMap['w1']!,
        greaterThan(result.workoutStrainMap['w2']!),
      );
      expect(result.cardiovascularLoad, greaterThan(0.0));
      expect(result.movementStrain, greaterThan(0.0));
    });

    test('Missing movement signals are distinct from measured zero values', () {
      final result = StrainCalculator.calculate(
        todayWorkouts: const [],
        steps: 0,
        activeCalories: 0,
        maxHeartRate: 190,
        recent7DaysLoads: const [],
        stepsAvailable: false,
        activeCaloriesAvailable: false,
      );

      expect(result.score, equals(0.0));
      expect(result.stepsAvailable, isFalse);
      expect(result.activeCaloriesAvailable, isFalse);
      expect(result.totalCalories, isNull);
      expect(result.estimatedBasalCalories, isNull);
    });

    test('Persisted weekly load availability is carried into the result', () {
      final result = StrainCalculator.calculate(
        todayWorkouts: const [],
        steps: 0,
        activeCalories: 0,
        maxHeartRate: 190,
        recent7DaysLoads: const [8.0, 0.0],
        recent7DaysLoadAvailability: const [true, false],
      );

      expect(result.weeklyDailyLoads, equals([8.0, 0.0, 0.0]));
      expect(result.weeklyLoadAvailable, equals([true, false, true]));
    });
  });

  group('RecommendationEngine Unit Tests', () {
    test('High recovery and low acute strain suggests heavy training', () {
      const recovery = RecoveryResult(
        score: 88,
        category: RecoveryCategory.ready,
        confidence: ConfidenceLevel.high,
        shortExplanation: 'Optimal readiness',
        detailedExplanation: 'Detailed explanation',
        componentScores: {},
        componentWeights: {},
        availableSignals: ['Sleep', 'RHR'],
        missingSignals: [],
        todayRhr: 54,
        baselineRhr: 56,
      );

      const strain = StrainResult(
        score: 6.0,
        category: StrainCategory.light,
        totalCalories: 2000,
        activeCalories: 300,
        steps: 6000,
        workoutCount: 0,
        hrZoneMinutes: [0, 0, 0, 0, 0],
        weeklyDailyLoads: [6.0, 7.0, 6.5],
        acuteLoad: 6.5,
        explanation: 'Light strain',
        hasHeartRateData: false,
      );

      final rec = RecommendationEngine.generate(
        recovery: recovery,
        strain: strain,
      );
      expect(rec.suggestion, equals(TrainingSuggestion.heavy));
      expect(rec.safetyDisclaimer.isNotEmpty, isTrue);
    });

    test('Low recovery score suggests rest and regeneration', () {
      const recovery = RecoveryResult(
        score: 28,
        category: RecoveryCategory.restRecommended,
        confidence: ConfidenceLevel.high,
        shortExplanation: 'High fatigue',
        detailedExplanation: 'Detailed explanation',
        componentScores: {},
        componentWeights: {},
        availableSignals: ['Sleep', 'RHR'],
        missingSignals: [],
        todayRhr: 68,
        baselineRhr: 58,
      );

      const strain = StrainResult(
        score: 16.0,
        category: StrainCategory.high,
        totalCalories: 2800,
        activeCalories: 1100,
        steps: 14000,
        workoutCount: 1,
        hrZoneMinutes: [10, 20, 20, 10, 5],
        weeklyDailyLoads: [15.0, 16.0, 14.5],
        acuteLoad: 15.2,
        explanation: 'High strain',
        hasHeartRateData: true,
      );

      final rec = RecommendationEngine.generate(
        recovery: recovery,
        strain: strain,
      );
      expect(rec.suggestion, equals(TrainingSuggestion.rest));
      expect(rec.safetyDisclaimer.contains('heuristic guidance'), isTrue);
    });
  });
}
