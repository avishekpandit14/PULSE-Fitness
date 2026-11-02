class HeartRateSample {
  final DateTime timestamp;
  final int bpm;

  const HeartRateSample({required this.timestamp, required this.bpm});

  Map<String, dynamic> toMap() {
    return {'timestamp': timestamp.toIso8601String(), 'bpm': bpm};
  }

  factory HeartRateSample.fromMap(Map<String, dynamic> map) {
    return HeartRateSample(
      timestamp: DateTime.parse(map['timestamp'] as String),
      bpm: map['bpm'] as int,
    );
  }
}
