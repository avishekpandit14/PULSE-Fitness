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
  });

  bool get hasEnoughData => score != null;
}
