import '../algorithms/nighttime_heart_rate_analyzer.dart';
import '../algorithms/sleep_quality_analyzer.dart';
import 'checkin_model.dart';

enum RecoveryCategory {
  ready,
  moderate,
  restRecommended,
  notEnoughData;

  String get displayName {
    switch (this) {
      case RecoveryCategory.ready:
        return 'Ready';
      case RecoveryCategory.moderate:
        return 'Moderate';
      case RecoveryCategory.restRecommended:
        return 'Rest Recommended';
      case RecoveryCategory.notEnoughData:
        return 'Not Enough Data';
    }
  }
}

enum ConfidenceLevel {
  high,
  moderate,
  low;

  String get displayName {
    switch (this) {
      case ConfidenceLevel.high:
        return 'High Confidence';
      case ConfidenceLevel.moderate:
        return 'Moderate Confidence';
      case ConfidenceLevel.low:
        return 'Low Confidence';
    }
  }
}

/// One explainable contribution to the final recovery score.
///
/// [impactPoints] is the number of score points this signal added (positive) or
/// removed (negative) relative to a neutral 50/100 reading. The impacts add up
/// to roughly `score - 50`, so the UI can show exactly what moved the number.
class RecoveryFactor {
  final String name;
  final double impactPoints;
  final String detail;

  const RecoveryFactor({
    required this.name,
    required this.impactPoints,
    required this.detail,
  });

  bool get isPositive => impactPoints >= 0;
}

class RecoveryResult {
  final int? score; // null if not enough data
  final RecoveryCategory category;
  final ConfidenceLevel confidence;
  final String shortExplanation;
  final String detailedExplanation;
  final Map<String, double> componentScores; // 0-100 for each active component
  final Map<String, double>
  componentWeights; // effective normalized weights (0-1.0)
  final List<String> availableSignals;
  final List<String> missingSignals;
  final double? baselineRhr;
  final double? todayRhr;
  final int rhrObservationsCount;
  final int? sleepMinutes;
  final int sleepTargetMinutes;
  final CheckInModel? checkIn;
  final double? yesterdayStrain;

  /// Sleep quality assessment derived from stages + efficiency (null when the
  /// tracker reported nothing assessable).
  final SleepQualityResult? sleepQuality;

  /// Nighttime heart rate analysis; never HRV, only BPM sample statistics.
  final NighttimeHeartRateAnalysis? nightHeartRate;

  /// Signed, explainable contributions that produced [score].
  final List<RecoveryFactor> factors;

  /// Measured nap minutes for the day. Display-only: naps never change the
  /// recovery score or replace the primary nighttime session.
  final int napMinutes;

  const RecoveryResult({
    this.score,
    required this.category,
    required this.confidence,
    required this.shortExplanation,
    required this.detailedExplanation,
    required this.componentScores,
    required this.componentWeights,
    required this.availableSignals,
    required this.missingSignals,
    this.baselineRhr,
    this.todayRhr,
    this.rhrObservationsCount = 0,
    this.sleepMinutes,
    this.sleepTargetMinutes = 480,
    this.checkIn,
    this.yesterdayStrain,
    this.sleepQuality,
    this.nightHeartRate,
    this.factors = const [],
    this.napMinutes = 0,
  });

  bool get hasEnoughData => score != null;

  bool get hasSleepQuality => sleepQuality?.isAvailable ?? false;
}
