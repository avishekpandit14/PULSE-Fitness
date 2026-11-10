enum SleepDataQuality { measured, partial, unavailable }

/// A non-primary sleep period (daytime nap or an extra sleep block recorded by
/// the tracker) kept separate from the primary nighttime session so that a nap
/// can never replace or shrink the overnight sleep score.
class SleepNap {
  final DateTime startTime;
  final DateTime endTime;
  final int minutes;

  const SleepNap({
    required this.startTime,
    required this.endTime,
    required this.minutes,
  });

  double get hours => minutes / 60.0;
}

/// Result of classifying one day of sleep records into the primary nighttime
/// session plus any additional naps.
class SleepNightReport {
  final SleepSessionModel? primary;
  final List<SleepNap> naps;

  /// Sum of measured nap minutes. Never added to the primary sleep score.
  final int napMinutes;

  /// False when no record fell inside the night band and the longest session
  /// had to be used as a fallback (e.g. night-shift sleepers).
  final bool primaryIsNighttime;

  const SleepNightReport({
    this.primary,
    this.naps = const [],
    this.napMinutes = 0,
    this.primaryIsNighttime = false,
  });

  static const SleepNightReport empty = SleepNightReport();

  bool get hasNaps => naps.isNotEmpty;

  int get primaryMinutes => primary?.totalMinutes ?? 0;

  int get totalSleepMinutes => primaryMinutes + napMinutes;
}

class SleepSessionModel {
  final String id;
  final String dateKey;
  final DateTime startTime;
  final DateTime endTime;
  final int totalMinutes;
  final int? deepMinutes;
  final int? lightMinutes;
  final int? remMinutes;
  final int? awakeMinutes;
  final int targetMinutes;
  final double? consistencyScore; // 0-100
  final SleepDataQuality dataQuality;
  final int unknownMinutes;

  const SleepSessionModel({
    required this.id,
    required this.dateKey,
    required this.startTime,
    required this.endTime,
    required this.totalMinutes,
    this.deepMinutes,
    this.lightMinutes,
    this.remMinutes,
    this.awakeMinutes,
    this.targetMinutes = 480, // 8 hours default
    this.consistencyScore,
    this.dataQuality = SleepDataQuality.measured,
    this.unknownMinutes = 0,
  });

  double get hours => totalMinutes / 60.0;
  double get targetHours => targetMinutes / 60.0;
  double get targetRatio =>
      targetMinutes > 0 ? (totalMinutes / targetMinutes) : 1.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_key': dateKey,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_minutes': totalMinutes,
      'deep_minutes': deepMinutes,
      'light_minutes': lightMinutes,
      'rem_minutes': remMinutes,
      'awake_minutes': awakeMinutes,
      'target_minutes': targetMinutes,
      'consistency_score': consistencyScore,
      'data_quality': dataQuality.name,
      'unknown_minutes': unknownMinutes,
    };
  }

  factory SleepSessionModel.fromMap(Map<String, dynamic> map) {
    return SleepSessionModel(
      id: map['id'] as String,
      dateKey: map['date_key'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      totalMinutes: map['total_minutes'] as int? ?? 0,
      deepMinutes: map['deep_minutes'] as int?,
      lightMinutes: map['light_minutes'] as int?,
      remMinutes: map['rem_minutes'] as int?,
      awakeMinutes: map['awake_minutes'] as int?,
      targetMinutes: map['target_minutes'] as int? ?? 480,
      consistencyScore: (map['consistency_score'] as num?)?.toDouble(),
      dataQuality: SleepDataQuality.values.firstWhere(
        (quality) => quality.name == map['data_quality'],
        orElse: () => SleepDataQuality.measured,
      ),
      unknownMinutes: map['unknown_minutes'] as int? ?? 0,
    );
  }
}
