enum StrainCategory {
  restorative, // 0.0 - 5.9
  low, // 6.0 - 9.9
  moderate, // 10.0 - 13.9
  high, // 14.0 - 17.9
  allOut; // 18.0 - 21.0

  String get displayName {
    switch (this) {
      case StrainCategory.restorative:
        return 'Restorative';
      case StrainCategory.low:
        return 'Low Strain';
      case StrainCategory.moderate:
        return 'Moderate Strain';
      case StrainCategory.high:
        return 'High Strain';
      case StrainCategory.allOut:
        return 'All-Out Strain';
    }
  }

  // Backward compatibility alias for tests
  static const StrainCategory light = StrainCategory.low;
}

class StrainProgressPoint {
  final DateTime timestamp;
  final double score;

  const StrainProgressPoint({required this.timestamp, required this.score});
}

class RecommendedStrainTarget {
  final double minTarget;
  final double maxTarget;
  final String label;
  final String explanation;

  const RecommendedStrainTarget({
    required this.minTarget,
    required this.maxTarget,
    required this.label,
    required this.explanation,
  });

  String getTargetStatus(double currentStrain) {
    if (currentStrain < minTarget) {
      return 'Below Target';
    } else if (currentStrain <= maxTarget) {
      return 'In Target Zone';
    } else {
      return 'Overreaching';
    }
  }
}

class StrainResult {
  final double score; // 0.0 to 21.0 scale
  final StrainCategory category;
  final int? totalCalories;
  final int? estimatedBasalCalories;
  final int activeCalories;
  final int steps;
  final int workoutCount;
  final List<int> hrZoneMinutes; // [Z1, Z2, Z3, Z4, Z5]
  final List<double> weeklyDailyLoads; // 7 days of daily strain scores
  final double acuteLoad; // 7-day rolling average
  final String explanation;
  final bool hasHeartRateData;
  final bool isMeasured;
  final double cardiovascularLoad;
  final double movementStrain;
  final Map<String, double>
  workoutStrainMap; // workout id -> workout strain score
  final List<StrainProgressPoint> dailyProgression;
  final RecommendedStrainTarget recommendedTarget;
  final bool stepsAvailable;
  final bool activeCaloriesAvailable;
  final List<bool> weeklyLoadAvailable;

  const StrainResult({
    required this.score,
    required this.category,
    required this.totalCalories,
    this.estimatedBasalCalories,
    required this.activeCalories,
    required this.steps,
    required this.workoutCount,
    required this.hrZoneMinutes,
    required this.weeklyDailyLoads,
    required this.acuteLoad,
    required this.explanation,
    required this.hasHeartRateData,
    this.isMeasured = false,
    this.cardiovascularLoad = 0.0,
    this.movementStrain = 0.0,
    this.workoutStrainMap = const {},
    this.dailyProgression = const [],
    this.recommendedTarget = const RecommendedStrainTarget(
      minTarget: 10.0,
      maxTarget: 14.0,
      label: 'Moderate Optimal',
      explanation: 'Maintain steady aerobic volume or technique.',
    ),
    this.stepsAvailable = true,
    this.activeCaloriesAvailable = true,
    this.weeklyLoadAvailable = const [],
  });

  static const String disclaimer =
      'Calculated as an algorithmic training load estimate based on workout duration, '
      'heart rate intensity zones, and active movement. This is not an official WHOOP or Athlytic score.';
}
