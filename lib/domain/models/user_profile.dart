class UserProfile {
  final String name;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final double sleepTargetHours;
  final int? configuredMaxHeartRate;
  final int typicalTrainingFrequencyDays; // days per week (e.g. 3, 4, 5)
  final bool isDemoMode;
  final bool onboardingCompleted;

  const UserProfile({
    this.name = 'Athlete',
    this.age = 28,
    this.heightCm,
    this.weightKg,
    this.sleepTargetHours = 8.0,
    this.configuredMaxHeartRate,
    this.typicalTrainingFrequencyDays = 4,
    this.isDemoMode = false,
    this.onboardingCompleted = false,
  });

  /// Deterministic estimated maximum heart rate if not manually configured
  int get calculatedMaxHeartRate {
    if (configuredMaxHeartRate != null && configuredMaxHeartRate! > 0) {
      return configuredMaxHeartRate!;
    }
    final effectiveAge = age ?? 28;
    // Standard Tanaka formula: 208 - (0.7 * age)
    return (208 - (0.7 * effectiveAge)).round();
  }

  UserProfile copyWith({
    String? name,
    int? age,
    double? heightCm,
    double? weightKg,
    double? sleepTargetHours,
    int? configuredMaxHeartRate,
    int? typicalTrainingFrequencyDays,
    bool? isDemoMode,
    bool? onboardingCompleted,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      sleepTargetHours: sleepTargetHours ?? this.sleepTargetHours,
      configuredMaxHeartRate:
          configuredMaxHeartRate ?? this.configuredMaxHeartRate,
      typicalTrainingFrequencyDays:
          typicalTrainingFrequencyDays ?? this.typicalTrainingFrequencyDays,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'sleep_target_hours': sleepTargetHours,
      'configured_max_hr': configuredMaxHeartRate,
      'training_frequency_days': typicalTrainingFrequencyDays,
      'is_demo_mode': isDemoMode ? 1 : 0,
      'onboarding_completed': onboardingCompleted ? 1 : 0,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? 'Athlete',
      age: map['age'] as int?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      sleepTargetHours: (map['sleep_target_hours'] as num?)?.toDouble() ?? 8.0,
      configuredMaxHeartRate: map['configured_max_hr'] as int?,
      typicalTrainingFrequencyDays: map['training_frequency_days'] as int? ?? 4,
      isDemoMode: (map['is_demo_mode'] as int?) == 1,
      onboardingCompleted: (map['onboarding_completed'] as int?) == 1,
    );
  }
}
