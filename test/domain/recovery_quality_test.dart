import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_fitness/domain/algorithms/nighttime_heart_rate_analyzer.dart';
import 'package:pulse_fitness/domain/algorithms/recovery_calculator.dart';
import 'package:pulse_fitness/domain/models/checkin_model.dart';
import 'package:pulse_fitness/domain/models/recovery_result.dart';
import 'package:pulse_fitness/domain/models/sleep_session_model.dart';

SleepSessionModel nightSleep({
  int totalMinutes = 480,
  int? deepMinutes = 96,
  int? lightMinutes = 264,
  int? remMinutes = 120,
  int? awakeMinutes = 20,
}) {
  return SleepSessionModel(
    id: 'night',
    dateKey: '2026-11-10',
    startTime: DateTime(2026, 11, 9, 23),
    endTime: DateTime(2026, 11, 10, 7),
    totalMinutes: totalMinutes,
    deepMinutes: deepMinutes,
    lightMinutes: lightMinutes,
    remMinutes: remMinutes,
    awakeMinutes: awakeMinutes,
  );
}

NighttimeHeartRateAnalysis nightHr({
  double? averageBpm = 57,
  double? baselineBpm = 58,
  double? stabilityScore = 90,
  double? trendDeltaBpm = -1,
  NighttimeHrQuality quality = NighttimeHrQuality.measured,
}) {
  return NighttimeHeartRateAnalysis(
    sampleCount: quality == NighttimeHrQuality.insufficient ? 2 : 16,
    quality: quality,
    averageBpm: averageBpm,
    medianBpm: averageBpm,
    lowestBpm: averageBpm == null ? null : averageBpm - 4,
    highestBpm: averageBpm == null ? null : averageBpm + 6,
    stabilityScore: stabilityScore,
    trendDeltaBpm: trendDeltaBpm,
    coverage: quality == NighttimeHrQuality.insufficient ? 0.1 : 0.9,
    baselineBpm: baselineBpm,
    baselineNightCount: baselineBpm == null ? 2 : 5,
    baselineDeltaBpm: (averageBpm != null && baselineBpm != null)
        ? averageBpm - baselineBpm
        : null,
  );
}

final checkIn = CheckInModel(
  dateKey: '2026-11-10',
  energy: 7,
  muscleSoreness: 3,
  fatigue: 3,
  timestamp: DateTime(2026, 11, 10, 7),
);

RecoveryResult recovery({
  SleepSessionModel? sleep,
  NighttimeHeartRateAnalysis? nightHrData,
  double? todayRhr,
  List<double> historicalRhrs = const [],
  int napMinutes = 0,
}) {
  return RecoveryCalculator.calculate(
    sleepSession: sleep ?? nightSleep(),
    todayRhr: todayRhr,
    historicalRhrs: historicalRhrs,
    yesterdayStrain: 8.0,
    checkIn: checkIn,
    sleepTargetHours: 8.0,
    nightHeartRate: nightHrData,
    napMinutes: napMinutes,
  );
}

void main() {
  group('Recovery with sleep quality and nighttime HR', () {
    test('equal 8 hour nights score differently by quality', () {
      final good = recovery(sleep: nightSleep(), nightHrData: nightHr());
      final poor = recovery(
        sleep: nightSleep(
          deepMinutes: 24,
          lightMinutes: 432,
          remMinutes: 24,
          awakeMinutes: 90,
        ),
        nightHrData: nightHr(),
      );

      expect(good.score, isNotNull);
      expect(poor.score, isNotNull);
      expect(good.score!, greaterThan(poor.score!));
      expect(
        good.componentScores['Sleep Quality']!,
        greaterThan(poor.componentScores['Sleep Quality']!),
      );
      // Same length, so the raw duration score is the same, but the shallow
      // night keeps less duration credit because quality caps it.
      expect(
        good.componentScores['Sleep Duration']!,
        greaterThan(poor.componentScores['Sleep Duration']!),
      );
    });

    test('duration credit is capped by sleep quality', () {
      final good = recovery(nightHrData: nightHr());
      final poor = recovery(
        sleep: nightSleep(
          deepMinutes: 24,
          lightMinutes: 432,
          remMinutes: 24,
          awakeMinutes: 90,
        ),
        nightHrData: nightHr(),
      );

      // Eight hours either way: only the architecture differs.
      expect(good.componentScores['Sleep Duration']!, greaterThan(90));
      expect(poor.componentScores['Sleep Duration']!, lessThan(70));
    });

    test('sleep quality outweighs duration in the score', () {
      final result = recovery(
        sleep: nightSleep(
          deepMinutes: 24,
          lightMinutes: 432,
          remMinutes: 24,
          awakeMinutes: 90,
        ),
        nightHrData: nightHr(),
      );

      expect(
        result.componentWeights['Sleep Quality']!,
        greaterThan(result.componentWeights['Sleep Duration']!),
      );
      expect(
        result.componentWeights['Sleep Quality']!,
        greaterThanOrEqualTo(0.30),
      );
    });

    test('eight hours of shallow sleep cannot read as a high score', () {
      final poor = recovery(
        sleep: nightSleep(
          deepMinutes: 24,
          lightMinutes: 432,
          remMinutes: 24,
          awakeMinutes: 90,
        ),
        nightHrData: nightHr(),
      );
      final good = recovery(nightHrData: nightHr());

      expect(poor.score!, lessThanOrEqualTo(67));
      expect(poor.category, isNot(equals(RecoveryCategory.ready)));
      expect(good.score!, greaterThanOrEqualTo(poor.score! + 15));
    });

    test('duration keeps full credit when stage data is missing', () {
      final result = RecoveryCalculator.calculate(
        sleepSession: nightSleep(
          deepMinutes: null,
          lightMinutes: null,
          remMinutes: null,
          awakeMinutes: null,
        ),
        todayRhr: null,
        historicalRhrs: const [],
        yesterdayStrain: null,
        checkIn: null,
        sleepTargetHours: 8.0,
      );

      // Quality is excluded (unknown), never treated as a zero that would cap
      // the duration credit.
      expect(result.componentScores.containsKey('Sleep Quality'), isFalse);
      expect(result.componentScores['Sleep Duration'], closeTo(95.0, 0.5));
    });

    test('naps are display-only and never change the recovery score', () {
      final withoutNap = recovery(nightHrData: nightHr());
      final withNap = recovery(nightHrData: nightHr(), napMinutes: 90);

      expect(withNap.score, equals(withoutNap.score));
      expect(withNap.napMinutes, equals(90));
      expect(withNap.componentScores, equals(withoutNap.componentScores));
    });

    test('missing nighttime HR is excluded, not counted as zero', () {
      final result = recovery(
        nightHrData: nightHr(
          averageBpm: null,
          baselineBpm: null,
          stabilityScore: null,
          trendDeltaBpm: null,
          quality: NighttimeHrQuality.insufficient,
        ),
      );

      expect(result.score, isNotNull);
      expect(result.componentScores.containsKey('Nighttime HR'), isFalse);
      expect(result.componentScores.containsKey('Resting HR'), isFalse);
      expect(
        result.missingSignals.any((s) => s.contains('Nighttime Heart Rate')),
        isTrue,
      );
      final totalWeight = result.componentWeights.values.fold(
        0.0,
        (a, b) => a + b,
      );
      expect(totalWeight, closeTo(1.0, 0.001));
    });

    test('elevated nighttime BPM lowers recovery against the baseline', () {
      final settled = recovery(nightHrData: nightHr(averageBpm: 56));
      final elevated = recovery(nightHrData: nightHr(averageBpm: 66));

      expect(settled.score!, greaterThan(elevated.score!));
      expect(
        settled.componentScores['Nighttime HR']!,
        greaterThan(elevated.componentScores['Nighttime HR']!),
      );
    });

    test('nighttime HR replaces resting HR instead of double counting', () {
      final result = recovery(
        nightHrData: nightHr(),
        todayRhr: 56,
        historicalRhrs: [58, 57, 59],
      );

      expect(result.componentScores.containsKey('Nighttime HR'), isTrue);
      expect(result.componentScores.containsKey('Resting HR'), isFalse);

      final hrWeight = result.componentScores.keys
          .where((key) => key.contains('HR'))
          .length;
      expect(hrWeight, equals(1));
    });

    test('resting HR is used when no nightly baseline exists yet', () {
      final result = recovery(
        nightHrData: nightHr(baselineBpm: null),
        todayRhr: 56,
        historicalRhrs: [58, 57, 59],
      );

      expect(result.componentScores.containsKey('Nighttime HR'), isFalse);
      expect(result.componentScores.containsKey('Resting HR'), isTrue);
      expect(
        result.missingSignals.any((s) => s.contains('Nighttime HR Baseline')),
        isTrue,
      );
    });

    test('explainable factors add up to the score offset from neutral', () {
      final result = recovery(nightHrData: nightHr());

      expect(result.factors, isNotEmpty);
      final sum = result.factors.fold(
        0.0,
        (total, factor) => total + factor.impactPoints,
      );
      expect(sum, closeTo(result.score! - 50.0, 1.5));
      // Largest absolute influence is listed first for readability.
      expect(
        result.factors.first.impactPoints.abs(),
        greaterThanOrEqualTo(result.factors.last.impactPoints.abs()),
      );
    });

    test('incomplete data still produces a score with reduced confidence', () {
      final result = RecoveryCalculator.calculate(
        sleepSession: nightSleep(totalMinutes: 420, deepMinutes: null),
        todayRhr: null,
        historicalRhrs: const [],
        yesterdayStrain: null,
        checkIn: null,
        sleepTargetHours: 8.0,
        nightHeartRate: nightHr(
          averageBpm: null,
          baselineBpm: null,
          quality: NighttimeHrQuality.insufficient,
        ),
      );

      expect(result.hasEnoughData, isTrue);
      expect(result.confidence, isNot(equals(ConfidenceLevel.high)));
      expect(result.missingSignals.length, greaterThanOrEqualTo(3));
    });

    test('a very short night cannot score like a full night', () {
      final full = recovery(nightHrData: nightHr());
      final short = recovery(
        sleep: nightSleep(
          totalMinutes: 300,
          deepMinutes: 60,
          lightMinutes: 180,
          remMinutes: 60,
          awakeMinutes: 20,
        ),
        nightHrData: nightHr(),
      );

      expect(full.score!, greaterThan(short.score!));
    });
  });
}
