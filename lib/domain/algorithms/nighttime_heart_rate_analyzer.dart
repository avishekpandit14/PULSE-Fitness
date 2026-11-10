import '../models/heart_rate_sample.dart';

/// How much trustworthy nighttime heart rate data was available.
enum NighttimeHrQuality { measured, limited, insufficient }

/// Deterministic analysis of the continuous nighttime heart rate samples that
/// Health Connect exposes while the user sleeps.
///
/// This class intentionally contains **no HRV calculation** (no RMSSD, no SDNN,
/// no "recovery variability"): the device does not expose beat-to-beat data, so
/// anything derived from intermittent BPM samples would be fabricated. The
/// stability figure below measures dispersion of the sampled BPM values only and
/// is labelled as such everywhere it is displayed.
class NighttimeHeartRateAnalyzer {
  /// Minimum usable samples before any statistic is reported.
  static const int minSamples = 5;

  /// Samples this far from the night median are treated as movement artifacts
  /// (rolling over, a watch slipping) and excluded from the descriptive stats.
  static const double artifactDeviationBpm = 35.0;

  /// A night baseline needs at least this many previous nights, mirroring the
  /// multi-day rule already used for the resting HR baseline.
  static const int minBaselineNights = 3;

  /// Bucket size used to describe how densely the night was covered.
  static const Duration coverageBucket = Duration(minutes: 30);

  /// Samples within this band around the median count as "stable".
  static const double stabilityBandBpm = 8.0;

  static NighttimeHeartRateAnalysis analyze({
    required List<HeartRateSample> samples,
    required DateTime sleepStart,
    required DateTime sleepEnd,
    List<double> historicalNightlyAverages = const [],
  }) {
    final windowMinutes = sleepEnd.difference(sleepStart).inMinutes;
    if (windowMinutes <= 0) {
      return const NighttimeHeartRateAnalysis(
        sampleCount: 0,
        quality: NighttimeHrQuality.insufficient,
        limitations: [
          'Sleep window is invalid, so nighttime HR was not analysed.',
        ],
      );
    }

    final inWindow =
        samples
            .where(
              (sample) =>
                  !sample.timestamp.isBefore(sleepStart) &&
                  !sample.timestamp.isAfter(sleepEnd) &&
                  sample.bpm > 30 &&
                  sample.bpm <= 220,
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final coverage = _coverage(
      samples: inWindow,
      sleepStart: sleepStart,
      sleepEnd: sleepEnd,
    );

    if (inWindow.length < minSamples) {
      return NighttimeHeartRateAnalysis(
        sampleCount: inWindow.length,
        coverage: coverage,
        quality: NighttimeHrQuality.insufficient,
        limitations: [
          'Only ${inWindow.length} nighttime heart rate samples were available '
              '(minimum $minSamples), so nighttime HR was excluded from scoring.',
        ],
      );
    }

    final bpmValues = inWindow.map((sample) => sample.bpm.toDouble()).toList();
    final median = _median(bpmValues);
    final effective = inWindow
        .where((sample) => (sample.bpm - median).abs() <= artifactDeviationBpm)
        .toList();
    final excludedArtifacts = inWindow.length - effective.length;

    final limitations = <String>[];
    if (excludedArtifacts > 0) {
      limitations.add(
        '$excludedArtifacts sample(s) differed from the night median by more '
        'than ${artifactDeviationBpm.round()} bpm and were treated as movement '
        'artifacts.',
      );
    }
    if (coverage < 0.5) {
      limitations.add(
        'Nighttime HR coverage was only ${(coverage * 100).round()}%, so the '
        'averages describe part of the night rather than all of it.',
      );
    }

    if (effective.length < minSamples) {
      return NighttimeHeartRateAnalysis(
        sampleCount: inWindow.length,
        excludedArtifacts: excludedArtifacts,
        coverage: coverage,
        quality: NighttimeHrQuality.insufficient,
        limitations: [
          ...limitations,
          'Too few artifact-free samples remained to describe the night.',
        ],
      );
    }

    final effectiveBpm = effective
        .map((sample) => sample.bpm.toDouble())
        .toList();
    final average = _mean(effectiveBpm);
    final effectiveMedian = _median(effectiveBpm);
    if (average < 40) {
      limitations.add(
        'Average nighttime HR of ${average.round()} bpm is unusually low; it is '
        'compared with your own history only and is never treated as a medical '
        'finding.',
      );
    }

    final midpoint = effective.length ~/ 2;
    final firstHalf = _mean(
      effectiveBpm.sublist(0, midpoint).isEmpty
          ? effectiveBpm
          : effectiveBpm.sublist(0, midpoint),
    );
    final secondHalf = _mean(effectiveBpm.sublist(midpoint));

    final close = effectiveBpm
        .where((bpm) => (bpm - effectiveMedian).abs() <= stabilityBandBpm)
        .length;
    final stability = close / effectiveBpm.length * 100.0;

    final baseline = _baseline(historicalNightlyAverages);
    final baselineNights = _validBaselines(historicalNightlyAverages).length;
    if (baseline == null) {
      limitations.add(
        'Nighttime HR baseline not established yet '
        '($baselineNights/$minBaselineNights nights).',
      );
    }

    return NighttimeHeartRateAnalysis(
      sampleCount: inWindow.length,
      excludedArtifacts: excludedArtifacts,
      averageBpm: average,
      medianBpm: effectiveMedian,
      lowestBpm: effectiveBpm.reduce((a, b) => a < b ? a : b),
      highestBpm: _percentile(effectiveBpm, 0.95),
      firstHalfAverageBpm: firstHalf,
      secondHalfAverageBpm: secondHalf,
      trendDeltaBpm: secondHalf - firstHalf,
      stabilityScore: stability,
      coverage: coverage,
      baselineBpm: baseline,
      baselineNightCount: baselineNights,
      baselineDeltaBpm: baseline != null ? average - baseline : null,
      quality: coverage >= 0.5
          ? NighttimeHrQuality.measured
          : NighttimeHrQuality.limited,
      limitations: limitations,
    );
  }

  static List<double> _validBaselines(List<double> values) => values
      .where((value) => value.isFinite && value >= 30 && value <= 150)
      .toList();

  /// Mean of the most recent valid nightly averages, or null below the minimum
  /// number of nights. Mirrors the multi-day rule of the resting HR baseline.
  static double? _baseline(List<double> historicalNightlyAverages) {
    final valid = _validBaselines(historicalNightlyAverages);
    if (valid.length < minBaselineNights) return null;
    final recent = valid.length > 14 ? valid.sublist(valid.length - 14) : valid;
    return _mean(recent);
  }

  static double _coverage({
    required List<HeartRateSample> samples,
    required DateTime sleepStart,
    required DateTime sleepEnd,
  }) {
    final totalMinutes = sleepEnd.difference(sleepStart).inMinutes;
    if (totalMinutes <= 0) return 0;
    final buckets = (totalMinutes / coverageBucket.inMinutes).ceil();
    if (buckets <= 0) return 0;
    final covered = <int>{};
    for (final sample in samples) {
      final offset = sample.timestamp.difference(sleepStart).inMinutes;
      if (offset < 0) continue;
      covered.add(offset ~/ coverageBucket.inMinutes);
    }
    return (covered.length / buckets).clamp(0.0, 1.0);
  }

  static double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.fold(0.0, (a, b) => a + b) / values.length;
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return (sorted[middle - 1] + sorted[middle]) / 2.0;
  }

  /// Nearest-rank percentile, used so a single spike cannot define the "highest"
  /// nighttime value.
  static double _percentile(List<double> values, double percentile) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final index = ((sorted.length - 1) * percentile).round().clamp(
      0,
      sorted.length - 1,
    );
    return sorted[index];
  }
}

class NighttimeHeartRateAnalysis {
  final int sampleCount;
  final int excludedArtifacts;
  final double? averageBpm;
  final double? medianBpm;
  final double? lowestBpm;
  final double? highestBpm;
  final double? firstHalfAverageBpm;
  final double? secondHalfAverageBpm;
  final double? trendDeltaBpm;

  /// 0-100 share of samples lying within +/-8 bpm of the night median. This is a
  /// dispersion descriptor of sampled BPM values, explicitly **not** HRV.
  final double? stabilityScore;
  final double? coverage;
  final double? baselineBpm;
  final int baselineNightCount;
  final double? baselineDeltaBpm;
  final NighttimeHrQuality quality;
  final List<String> limitations;

  const NighttimeHeartRateAnalysis({
    required this.sampleCount,
    required this.quality,
    this.excludedArtifacts = 0,
    this.averageBpm,
    this.medianBpm,
    this.lowestBpm,
    this.highestBpm,
    this.firstHalfAverageBpm,
    this.secondHalfAverageBpm,
    this.trendDeltaBpm,
    this.stabilityScore,
    this.coverage,
    this.baselineBpm,
    this.baselineNightCount = 0,
    this.baselineDeltaBpm,
    this.limitations = const [],
  });

  bool get hasUsableData =>
      quality != NighttimeHrQuality.insufficient && averageBpm != null;

  bool get hasBaseline => baselineBpm != null;
}
