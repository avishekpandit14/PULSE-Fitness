import '../models/recovery_result.dart';
import '../models/sleep_session_model.dart';

/// Deterministic sleep *quality* assessment.
///
/// Deliberately independent of total sleep duration: an eight hour night made
/// of restless, stage-poor sleep must not score the same as an eight hour night
/// with normal architecture. Duration is scored separately by
/// [RecoveryCalculator.calculateSleepScore] so the two never double count.
///
/// All bands below are transparent heuristic reference targets, documented in
/// the UI, and are not clinical thresholds. Sub-scores are re-normalised over
/// whatever the tracker actually reported: a missing stage is *excluded*, never
/// treated as zero, and the confidence drops instead.
class SleepQualityAnalyzer {
  /// Raw weights (must sum to 1.0 for a full-confidence assessment).
  static const double efficiencyWeight = 0.40;
  static const double deepSleepWeight = 0.30;
  static const double remSleepWeight = 0.30;

  /// Heuristic reference points, intentionally conservative and monotonic.
  static const double efficiencyFloor = 0.75;
  static const double efficiencyTarget = 0.95;
  static const double deepRatioTarget = 0.15;
  static const double remRatioTarget = 0.22;

  static SleepQualityResult analyze(SleepSessionModel session) {
    final asleepMinutes = session.totalMinutes;
    if (asleepMinutes <= 0) {
      return SleepQualityResult.unavailable(
        dataQuality: session.dataQuality,
        missingFactors: const [
          'Sleep architecture (no validated asleep intervals recorded)',
        ],
      );
    }

    final subScores = <String, double>{};
    final rawWeights = <String, double>{};
    final availableFactors = <String>[];
    final missingFactors = <String>[];

    // 1. Sleep efficiency (asleep time vs time in bed) - needs awake time.
    final awakeMinutes = session.awakeMinutes;
    final double? efficiency = awakeMinutes != null && awakeMinutes >= 0
        ? asleepMinutes / (asleepMinutes + awakeMinutes)
        : null;
    if (efficiency != null) {
      subScores['Efficiency'] = calculateEfficiencyScore(efficiency);
      rawWeights['Efficiency'] = efficiencyWeight;
      availableFactors.add(
        'Sleep efficiency ${(efficiency * 100).round()}% '
        '(${(awakeMinutes! / 60).toStringAsFixed(1)}h awake)',
      );
    } else {
      missingFactors.add(
        'Sleep efficiency (tracker reported no awake time for this session)',
      );
    }

    // 2. Deep sleep share - excluded entirely when stages are unavailable.
    final deepMinutes = session.deepMinutes;
    final double? deepRatio = deepMinutes != null
        ? (deepMinutes / asleepMinutes).clamp(0.0, 1.0)
        : null;
    if (deepRatio != null) {
      subScores['Deep Sleep'] = calculateStageScore(
        ratio: deepRatio,
        target: deepRatioTarget,
      );
      rawWeights['Deep Sleep'] = deepSleepWeight;
      availableFactors.add(
        'Deep sleep ${(deepRatio * 100).round()}% of measured sleep',
      );
    } else {
      missingFactors.add(
        'Deep sleep (tracker provided no deep stage for this session)',
      );
    }

    // 3. REM sleep share.
    final remMinutes = session.remMinutes;
    final double? remRatio = remMinutes != null
        ? (remMinutes / asleepMinutes).clamp(0.0, 1.0)
        : null;
    if (remRatio != null) {
      subScores['REM Sleep'] = calculateStageScore(
        ratio: remRatio,
        target: remRatioTarget,
      );
      rawWeights['REM Sleep'] = remSleepWeight;
      availableFactors.add(
        'REM sleep ${(remRatio * 100).round()}% of measured sleep',
      );
    } else {
      missingFactors.add(
        'REM sleep (tracker provided no REM stage for this session)',
      );
    }

    final lightMinutes = session.lightMinutes;
    final double? lightRatio = lightMinutes != null
        ? (lightMinutes / asleepMinutes).clamp(0.0, 1.0)
        : null;

    final availableWeight = rawWeights.values.fold(0.0, (a, b) => a + b);
    if (availableWeight <= 0 || subScores.isEmpty) {
      return SleepQualityResult(
        score: null,
        efficiency: efficiency,
        deepRatio: deepRatio,
        remRatio: remRatio,
        lightRatio: lightRatio,
        subScores: subScores,
        subWeights: const {},
        availableFactors: availableFactors,
        missingFactors: missingFactors,
        confidence: ConfidenceLevel.low,
        dataQuality: session.dataQuality,
      );
    }

    final normalizedWeights = <String, double>{};
    var weightedSum = 0.0;
    for (final entry in rawWeights.entries) {
      final normalized = entry.value / availableWeight;
      normalizedWeights[entry.key] = normalized;
      weightedSum += subScores[entry.key]! * normalized;
    }

    return SleepQualityResult(
      score: weightedSum.clamp(0.0, 100.0),
      efficiency: efficiency,
      deepRatio: deepRatio,
      remRatio: remRatio,
      lightRatio: lightRatio,
      subScores: subScores,
      subWeights: normalizedWeights,
      availableFactors: availableFactors,
      missingFactors: missingFactors,
      confidence: _confidence(
        availableWeight: availableWeight,
        dataQuality: session.dataQuality,
      ),
      dataQuality: session.dataQuality,
    );
  }

  /// Efficiency score: 100% at [efficiencyTarget] and above, 0 at or below
  /// [efficiencyFloor], linear in between.
  static double calculateEfficiencyScore(double efficiency) {
    final clamped = efficiency.clamp(0.0, 1.0);
    if (clamped >= efficiencyTarget) return 100.0;
    if (clamped <= efficiencyFloor) return 0.0;
    return (clamped - efficiencyFloor) /
        (efficiencyTarget - efficiencyFloor) *
        100.0;
  }

  /// Monotonic stage score: reaches 100 at [target] share of measured sleep and
  /// scales linearly below it. No upper penalty, because there is no defensible
  /// reason to punish a larger share of a restorative stage.
  static double calculateStageScore({
    required double ratio,
    required double target,
  }) {
    if (target <= 0) return 100.0;
    return (ratio / target).clamp(0.0, 1.0) * 100.0;
  }

  static ConfidenceLevel _confidence({
    required double availableWeight,
    required SleepDataQuality dataQuality,
  }) {
    ConfidenceLevel level;
    if (availableWeight >= 0.9) {
      level = ConfidenceLevel.high;
    } else if (availableWeight >= 0.6) {
      level = ConfidenceLevel.moderate;
    } else {
      level = ConfidenceLevel.low;
    }
    // Partial / unavailable stage extraction downgrades confidence, because
    // some of the measured sleep was never classified by the tracker.
    if (dataQuality == SleepDataQuality.partial &&
        level == ConfidenceLevel.high) {
      return ConfidenceLevel.moderate;
    }
    if (dataQuality == SleepDataQuality.unavailable) {
      return ConfidenceLevel.low;
    }
    return level;
  }
}

class SleepQualityResult {
  /// 0-100, or null when the tracker reported nothing that can be assessed.
  final double? score;
  final double? efficiency;
  final double? deepRatio;
  final double? remRatio;
  final double? lightRatio;
  final Map<String, double> subScores;
  final Map<String, double> subWeights;
  final List<String> availableFactors;
  final List<String> missingFactors;
  final ConfidenceLevel confidence;
  final SleepDataQuality dataQuality;

  const SleepQualityResult({
    required this.score,
    required this.confidence,
    required this.dataQuality,
    this.efficiency,
    this.deepRatio,
    this.remRatio,
    this.lightRatio,
    this.subScores = const {},
    this.subWeights = const {},
    this.availableFactors = const [],
    this.missingFactors = const [],
  });

  factory SleepQualityResult.unavailable({
    required SleepDataQuality dataQuality,
    List<String> missingFactors = const [],
  }) {
    return SleepQualityResult(
      score: null,
      confidence: ConfidenceLevel.low,
      dataQuality: dataQuality,
      missingFactors: missingFactors,
    );
  }

  bool get isAvailable => score != null;

  bool get hasStageData => deepRatio != null || remRatio != null;
}
