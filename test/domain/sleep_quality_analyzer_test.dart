import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_fitness/domain/algorithms/sleep_quality_analyzer.dart';
import 'package:pulse_fitness/domain/models/recovery_result.dart';
import 'package:pulse_fitness/domain/models/sleep_session_model.dart';

SleepSessionModel session({
  required int totalMinutes,
  int? deepMinutes,
  int? lightMinutes,
  int? remMinutes,
  int? awakeMinutes,
  SleepDataQuality dataQuality = SleepDataQuality.measured,
}) {
  return SleepSessionModel(
    id: 'test',
    dateKey: '2026-11-10',
    startTime: DateTime(2026, 11, 9, 23),
    endTime: DateTime(2026, 11, 10, 7),
    totalMinutes: totalMinutes,
    deepMinutes: deepMinutes,
    lightMinutes: lightMinutes,
    remMinutes: remMinutes,
    awakeMinutes: awakeMinutes,
    dataQuality: dataQuality,
  );
}

void main() {
  group('SleepQualityAnalyzer', () {
    test('two 8 hour nights with different architecture score differently', () {
      // Good: 20% deep, 25% REM, only 20 min awake.
      final good = SleepQualityAnalyzer.analyze(
        session(
          totalMinutes: 480,
          deepMinutes: 96,
          lightMinutes: 264,
          remMinutes: 120,
          awakeMinutes: 20,
        ),
      );

      // Poor: same 8 hours but stage-poor and fragmented.
      final poor = SleepQualityAnalyzer.analyze(
        session(
          totalMinutes: 480,
          deepMinutes: 24,
          lightMinutes: 432,
          remMinutes: 24,
          awakeMinutes: 90,
        ),
      );

      expect(good.score, isNotNull);
      expect(poor.score, isNotNull);
      expect(good.score!, greaterThan(poor.score!));
      expect(good.confidence, equals(ConfidenceLevel.high));
      // Duration is identical, so only quality can separate them.
      expect(good.score! - poor.score!, greaterThan(25));
    });

    test('duration alone never produces a quality score', () {
      final result = SleepQualityAnalyzer.analyze(
        session(totalMinutes: 480), // no stages, no awake time
      );

      expect(result.score, isNull);
      expect(result.isAvailable, isFalse);
      expect(result.confidence, equals(ConfidenceLevel.low));
      expect(result.missingFactors.length, equals(3));
    });

    test('missing deep/REM stages are excluded, not treated as zero', () {
      final onlyEfficiency = SleepQualityAnalyzer.analyze(
        session(totalMinutes: 480, awakeMinutes: 30),
      );

      expect(onlyEfficiency.score, isNotNull);
      expect(onlyEfficiency.deepRatio, isNull);
      expect(onlyEfficiency.remRatio, isNull);
      expect(onlyEfficiency.subScores.containsKey('Deep Sleep'), isFalse);
      expect(onlyEfficiency.subScores.containsKey('REM Sleep'), isFalse);
      // Only 40% of the raw weight is available, so confidence must be low.
      expect(onlyEfficiency.confidence, equals(ConfidenceLevel.low));
      expect(onlyEfficiency.missingFactors.length, equals(2));

      final partial = SleepQualityAnalyzer.analyze(
        session(
          totalMinutes: 480,
          awakeMinutes: 30,
          deepMinutes: 90,
          remMinutes: null,
        ),
      );
      expect(partial.subScores.containsKey('REM Sleep'), isFalse);
      expect(partial.confidence, equals(ConfidenceLevel.moderate));
    });

    test('efficiency score is bounded and monotonic', () {
      expect(SleepQualityAnalyzer.calculateEfficiencyScore(1.0), equals(100));
      expect(SleepQualityAnalyzer.calculateEfficiencyScore(0.95), equals(100));
      expect(SleepQualityAnalyzer.calculateEfficiencyScore(0.70), equals(0));
      expect(
        SleepQualityAnalyzer.calculateEfficiencyScore(0.85),
        closeTo(50.0, 0.5),
      );
      expect(
        SleepQualityAnalyzer.calculateEfficiencyScore(0.90),
        greaterThan(SleepQualityAnalyzer.calculateEfficiencyScore(0.80)),
      );
    });

    test('stage score scales to its reference target without an upper cap', () {
      expect(
        SleepQualityAnalyzer.calculateStageScore(ratio: 0.0, target: 0.15),
        equals(0),
      );
      expect(
        SleepQualityAnalyzer.calculateStageScore(ratio: 0.075, target: 0.15),
        closeTo(50.0, 0.5),
      );
      expect(
        SleepQualityAnalyzer.calculateStageScore(ratio: 0.15, target: 0.15),
        equals(100),
      );
      expect(
        SleepQualityAnalyzer.calculateStageScore(ratio: 0.3, target: 0.15),
        equals(100),
      );
    });

    test('partial stage extraction downgrades confidence', () {
      final partial = SleepQualityAnalyzer.analyze(
        session(
          totalMinutes: 480,
          deepMinutes: 96,
          remMinutes: 120,
          awakeMinutes: 20,
          dataQuality: SleepDataQuality.partial,
        ),
      );

      expect(partial.score, isNotNull);
      expect(partial.confidence, isNot(equals(ConfidenceLevel.high)));
      expect(partial.dataQuality, equals(SleepDataQuality.partial));
    });

    test('empty session is reported as unavailable rather than zero', () {
      final result = SleepQualityAnalyzer.analyze(session(totalMinutes: 0));

      expect(result.score, isNull);
      expect(result.missingFactors, isNotEmpty);
    });
  });
}
