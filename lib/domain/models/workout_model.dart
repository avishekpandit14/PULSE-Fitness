enum WorkoutType {
  running,
  cycling,
  swimming,
  strength,
  hiit,
  walking,
  other;

  String get displayName {
    switch (this) {
      case WorkoutType.running:
        return 'Running';
      case WorkoutType.cycling:
        return 'Cycling';
      case WorkoutType.swimming:
        return 'Swimming';
      case WorkoutType.strength:
        return 'Strength Training';
      case WorkoutType.hiit:
        return 'HIIT';
      case WorkoutType.walking:
        return 'Walking';
      case WorkoutType.other:
        return 'Workout';
    }
  }

  static WorkoutType fromString(String val) {
    return WorkoutType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => WorkoutType.other,
    );
  }
}

class WorkoutModel {
  final String id;
  final String title;
  final WorkoutType type;
  final DateTime startTime;
  final int durationMinutes;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int? caloriesBurned;
  final int rpe; // 1 to 10
  final bool isManual;
  final List<int>? hrZoneMinutes; // [z1, z2, z3, z4, z5]
  final String? notes;

  const WorkoutModel({
    required this.id,
    required this.title,
    required this.type,
    required this.startTime,
    required this.durationMinutes,
    this.avgHeartRate,
    this.maxHeartRate,
    this.caloriesBurned,
    this.rpe = 6,
    this.isManual = false,
    this.hrZoneMinutes,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'start_time': startTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'avg_hr': avgHeartRate,
      'max_hr': maxHeartRate,
      'calories': caloriesBurned,
      'rpe': rpe,
      'is_manual': isManual ? 1 : 0,
      'hr_zones': hrZoneMinutes?.join(','),
      'notes': notes,
    };
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    List<int>? zones;
    if (map['hr_zones'] != null && (map['hr_zones'] as String).isNotEmpty) {
      zones = (map['hr_zones'] as String)
          .split(',')
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .toList();
    }

    return WorkoutModel(
      id: map['id'] as String,
      title: map['title'] as String,
      type: WorkoutType.fromString(map['type'] as String? ?? 'other'),
      startTime: DateTime.parse(map['start_time'] as String),
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      avgHeartRate: map['avg_hr'] as int?,
      maxHeartRate: map['max_hr'] as int?,
      caloriesBurned: map['calories'] as int?,
      rpe: map['rpe'] as int? ?? 6,
      isManual: (map['is_manual'] as int?) == 1,
      hrZoneMinutes: zones,
      notes: map['notes'] as String?,
    );
  }
}
