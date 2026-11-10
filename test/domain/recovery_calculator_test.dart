import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_fitness/domain/algorithms/recovery_calculator.dart';
import 'package:pulse_fitness/domain/models/checkin_model.dart';
import 'package:pulse_fitness/domain/models/recovery_result.dart';
import 'package:pulse_fitness/domain/models/sleep_session_model.dart';

void main() {
  group('RecoveryCalculator Unit Tests', () {
    test('Sleep score calculation handles normal, deficit, and oversleeping', () {
      const targetHours = 8.0;

      // Exactly target (8 hours = 480 mins): should score ~95
      final exactScore = RecoveryCalculator.calculateSleepScore(
        actualMinutes: 480,
        targetHours: targetHours,
      );
      expect(exactScore, closeTo(95.0, 1.0));

      // Sweet spot (8.8 hours = 528 mins, ~110% of target): should score ~98
      final sweetScore = RecoveryCalculator.calculateSleepScore(
        actualMinutes: 528,
        targetHours: targetHours,
      );
      expect(sweetScore, closeTo(98.3, 1.0));

      // Severe deficit (3 hours = 180 mins): should be low (<= 30)
      final deficitScore = RecoveryCalculator.calculateSleepScore(
        actualMinutes: 180,
        targetHours: targetHours,
      );
      expect(deficitScore, lessThanOrEqualTo(30.0));

      // Oversleeping (12 hours = 720 mins = 150% target):
      // Must not reward implausibly long sleep without limit; should drop to ~85
      final oversleepScore = RecoveryCalculator.calculateSleepScore(
        actualMinutes: 720,
        targetHours: targetHours,
      );
      expect(oversleepScore, lessThan(95.0));
      expect(oversleepScore, greaterThanOrEqualTo(70.0));
    });

    test(
      'RHR score calculation accurately reflects delta against baseline',
      () {
        const baseline = 58.0;

        // 3 bpm lower than baseline -> 100
        expect(
          RecoveryCalculator.calculateRhrScore(
            todayRhr: 54.0,
            baselineRhr: baseline,
          ),
          equals(100.0),
        );

        // Same as baseline -> 90
        expect(
          RecoveryCalculator.calculateRhrScore(
            todayRhr: 58.0,
            baselineRhr: baseline,
          ),
          equals(90.0),
        );

        // Elevated by 4 bpm (62 bpm) -> 69
        final mildElevated = RecoveryCalculator.calculateRhrScore(
          todayRhr: 62.0,
          baselineRhr: baseline,
        );
        expect(mildElevated, closeTo(69.0, 2.0));

        // Severely elevated by 12 bpm (70 bpm) -> low score (<= 30)
        final severeElevated = RecoveryCalculator.calculateRhrScore(
          todayRhr: 70.0,
          baselineRhr: baseline,
        );
        expect(severeElevated, lessThanOrEqualTo(30.0));
      },
    );

    test('Check-in normalization scales correctly', () {
      // Energy 1 -> 0, 10 -> 100
      expect(RecoveryCalculator.calculateEnergyScore(1), equals(0.0));
      expect(RecoveryCalculator.calculateEnergyScore(10), equals(100.0));
      expect(RecoveryCalculator.calculateEnergyScore(5), closeTo(44.4, 0.5));

      // Muscle Soreness: inverted (0 soreness -> 100, 10 soreness -> 0)
      expect(RecoveryCalculator.calculateSorenessScore(0), equals(100.0));
      expect(RecoveryCalculator.calculateSorenessScore(10), equals(0.0));
      expect(RecoveryCalculator.calculateSorenessScore(4), equals(60.0));

      // Fatigue: inverted (0 fatigue -> 100, 10 fatigue -> 0)
      expect(RecoveryCalculator.calculateFatigueScore(0), equals(100.0));
      expect(RecoveryCalculator.calculateFatigueScore(10), equals(0.0));
    });

    test(
      'Full data available gives high confidence and ready status for good metrics',
      () {
        final sleep = SleepSessionModel(
          id: '1',
          dateKey: '2026-10-26',
          startTime: DateTime.now().subtract(const Duration(hours: 8)),
          endTime: DateTime.now(),
          totalMinutes: 490, // ~8.16 hours
          deepMinutes: 90,
          lightMinutes: 250,
          remMinutes: 110,
          awakeMinutes: 30,
          targetMinutes: 480,
        );

        final checkIn = CheckInModel(
          dateKey: '2026-10-26',
          energy: 9,
          muscleSoreness: 1,
          fatigue: 2,
          timestamp: DateTime.now(),
        );

        final result = RecoveryCalculator.calculate(
          sleepSession: sleep,
          todayRhr: 56.0,
          historicalRhrs: [
            58.0,
            57.0,
            59.0,
            58.0,
            57.0,
          ], // 5 valid days baseline
          yesterdayStrain: 8.5,
          checkIn: checkIn,
          sleepTargetHours: 8.0,
        );

        expect(result.hasEnoughData, isTrue);
        expect(result.score, isNotNull);
        expect(result.score!, greaterThanOrEqualTo(80));
        expect(result.category, equals(RecoveryCategory.ready));
        expect(result.confidence, equals(ConfidenceLevel.high));
        expect(result.missingSignals, isEmpty);
        // Duration, Quality, RHR, Strain, Check-in
        expect(result.availableSignals.length, equals(5));
        expect(
          result.availableSignals.any((s) => s.contains('Sleep Quality')),
          isTrue,
        );
      },
    );

    test(
      'Missing signals are dynamically re-normalized without injecting zero',
      () {
        // User has sleep and check-in, but no RHR baseline (only 1 historical day) and no yesterday strain
        final sleep = SleepSessionModel(
          id: '2',
          dateKey: '2026-10-26',
          startTime: DateTime.now().subtract(const Duration(hours: 7)),
          endTime: DateTime.now(),
          totalMinutes: 450, // 7.5 hours
          targetMinutes: 480,
        );

        final checkIn = CheckInModel(
          dateKey: '2026-10-26',
          energy: 7,
          muscleSoreness: 2,
          fatigue: 3,
          timestamp: DateTime.now(),
        );

        final result = RecoveryCalculator.calculate(
          sleepSession: sleep,
          todayRhr: 60.0,
          historicalRhrs: [
            60.0,
          ], // only 1 day: insufficient for personal baseline!
          yesterdayStrain: null,
          checkIn: checkIn,
          sleepTargetHours: 8.0,
        );

        expect(result.hasEnoughData, isTrue);
        expect(result.score, isNotNull);
        // Normalized weights must sum to 1.0 (100%)
        final totalWeight = result.componentWeights.values.fold(
          0.0,
          (a, b) => a + b,
        );
        expect(totalWeight, closeTo(1.0, 0.001));
        // RHR and yesterday strain should NOT be in componentScores
        expect(result.componentScores.containsKey('Resting HR'), isFalse);
        expect(result.componentScores.containsKey('Recent Load'), isFalse);
        expect(
          result.missingSignals.any((s) => s.contains('Baseline')),
          isTrue,
        );
      },
    );

    test(
      'Insufficient data triggers "Not Enough Data" category and null score',
      () {
        // No sleep, no check-in, no RHR baseline
        final result = RecoveryCalculator.calculate(
          sleepSession: null,
          todayRhr: null,
          historicalRhrs: [],
          yesterdayStrain: null,
          checkIn: null,
          sleepTargetHours: 8.0,
        );

        expect(result.hasEnoughData, isFalse);
        expect(result.score, isNull);
        expect(result.category, equals(RecoveryCategory.notEnoughData));
        expect(result.confidence, equals(ConfidenceLevel.low));
      },
    );
  });
}
