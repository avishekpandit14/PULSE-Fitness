enum SleepDataQuality { measured, partial, unavailable }

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
