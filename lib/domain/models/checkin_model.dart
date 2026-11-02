class CheckInModel {
  final int? id;
  final String dateKey; // YYYY-MM-DD
  final int energy; // 1 to 10
  final int muscleSoreness; // 0 to 10
  final int fatigue; // 0 to 10
  final String? notes;
  final DateTime timestamp;

  const CheckInModel({
    this.id,
    required this.dateKey,
    required this.energy,
    required this.muscleSoreness,
    required this.fatigue,
    this.notes,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_key': dateKey,
      'energy': energy,
      'muscle_soreness': muscleSoreness,
      'fatigue': fatigue,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CheckInModel.fromMap(Map<String, dynamic> map) {
    return CheckInModel(
      id: map['id'] as int?,
      dateKey: map['date_key'] as String,
      energy: map['energy'] as int? ?? 5,
      muscleSoreness: map['muscle_soreness'] as int? ?? 3,
      fatigue: map['fatigue'] as int? ?? 3,
      notes: map['notes'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  CheckInModel copyWith({
    int? id,
    String? dateKey,
    int? energy,
    int? muscleSoreness,
    int? fatigue,
    String? notes,
    DateTime? timestamp,
  }) {
    return CheckInModel(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      energy: energy ?? this.energy,
      muscleSoreness: muscleSoreness ?? this.muscleSoreness,
      fatigue: fatigue ?? this.fatigue,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
