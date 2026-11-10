import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_fitness/domain/algorithms/nighttime_heart_rate_analyzer.dart';
import 'package:pulse_fitness/domain/models/heart_rate_sample.dart';

final sleepStart = DateTime(2026, 11, 9, 23);
final sleepEnd = DateTime(2026, 11, 10, 7);

/// Generates `count` samples spread evenly across the sleep window.
List<HeartRateSample> steadySamples(
  List<int> bpmPattern, {
  Duration step = const Duration(minutes: 30),
}) {
  final samples = <HeartRateSample>[];
  for (var i = 0; i < bpmPattern.length; i++) {
    samples.add(
      HeartRateSample(timestamp: sleepStart.add(step * i), bpm: bpmPattern[i]),
    );
  }
  return samples;
}

void main() {
  group('NighttimeHeartRateAnalyzer', () {
    test('too few samples are reported as unavailable, never invented', () {
      final result = NighttimeHeartRateAnalyzer.analyze(
        samples: steadySamples([56, 57]),
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
        historicalNightlyAverages: [58, 57, 59],
      );

      expect(result.quality, equals(NighttimeHrQuality.insufficient));
      expect(result.averageBpm, isNull);
      expect(result.hasUsableData, isFalse);
      expect(result.limitations, isNotEmpty);
    });

    test('no samples at all yields an explicit insufficient analysis', () {
      final result = NighttimeHeartRateAnalyzer.analyze(
        samples: const [],
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
      );

      expect(result.sampleCount, equals(0));
      expect(result.quality, equals(NighttimeHrQuality.insufficient));
      expect(result.averageBpm, isNull);
      expect(result.limitations.single, contains('Only 0'));
    });

    test(
      'elevated nighttime BPM is detected against the personal baseline',
      () {
        final result = NighttimeHeartRateAnalyzer.analyze(
          samples: steadySamples(List.filled(16, 66)),
          sleepStart: sleepStart,
          sleepEnd: sleepEnd,
          historicalNightlyAverages: [58, 57, 59], // baseline 58
        );

        expect(result.hasBaseline, isTrue);
        expect(result.baselineBpm, closeTo(58.0, 0.01));
        expect(result.averageBpm, closeTo(66.0, 0.01));
        expect(result.baselineDeltaBpm!, greaterThan(5));
        expect(result.quality, equals(NighttimeHrQuality.measured));
      },
    );

    test('stable nighttime BPM produces a high stability reading', () {
      final result = NighttimeHeartRateAnalyzer.analyze(
        samples: steadySamples(List.generate(16, (i) => i.isEven ? 57 : 58)),
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
        historicalNightlyAverages: [58, 57, 58],
      );

      expect(result.averageBpm, closeTo(57.5, 0.01));
      expect(result.baselineDeltaBpm, closeTo(-0.17, 0.2));
      expect(result.stabilityScore, equals(100.0));
      expect(result.trendDeltaBpm, closeTo(0.0, 0.5));
    });

    test('a spiking sample is treated as an artifact', () {
      final pattern = List.filled(16, 57)..[7] = 190;
      final result = NighttimeHeartRateAnalyzer.analyze(
        samples: steadySamples(pattern),
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
        historicalNightlyAverages: [57, 58, 57],
      );

      expect(result.excludedArtifacts, equals(1));
      expect(result.averageBpm, closeTo(57.0, 0.01));
      // Highest uses the 95th percentile, so the spike cannot define it.
      expect(result.highestBpm!, lessThan(100));
      expect(result.limitations.any((l) => l.contains('artifact')), isTrue);
    });

    test('sparse coverage lowers confidence and is disclosed', () {
      // All samples crowded into the first hour of an eight hour night.
      final samples = List.generate(
        6,
        (i) => HeartRateSample(
          timestamp: sleepStart.add(Duration(minutes: 5 * i)),
          bpm: 56 + i,
        ),
      );
      final result = NighttimeHeartRateAnalyzer.analyze(
        samples: samples,
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
        historicalNightlyAverages: [58, 58, 58],
      );

      expect(result.coverage!, lessThan(0.5));
      expect(result.quality, equals(NighttimeHrQuality.limited));
      expect(result.limitations.any((l) => l.contains('coverage')), isTrue);
    });

    test('baseline needs three nights before it is used', () {
      final noBaseline = NighttimeHeartRateAnalyzer.analyze(
        samples: steadySamples(List.filled(16, 60)),
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
        historicalNightlyAverages: [58, 59], // only two nights
      );

      expect(noBaseline.hasBaseline, isFalse);
      expect(noBaseline.baselineDeltaBpm, isNull);
      expect(noBaseline.baselineNightCount, equals(2));
      expect(noBaseline.limitations.any((l) => l.contains('baseline')), isTrue);
    });

    test('samples outside the sleep window are ignored', () {
      final result = NighttimeHeartRateAnalyzer.analyze(
        samples: [
          HeartRateSample(
            timestamp: sleepStart.subtract(const Duration(hours: 3)),
            bpm: 150,
          ),
          ...steadySamples(List.filled(16, 57)),
        ],
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
        historicalNightlyAverages: [57, 57, 57],
      );

      expect(result.sampleCount, equals(16));
      expect(result.averageBpm, closeTo(57.0, 0.01));
    });

    test('invalid sleep window is reported instead of dividing by zero', () {
      final result = NighttimeHeartRateAnalyzer.analyze(
        samples: steadySamples(List.filled(10, 57)),
        sleepStart: sleepEnd,
        sleepEnd: sleepStart,
      );

      expect(result.quality, equals(NighttimeHrQuality.insufficient));
      expect(result.averageBpm, isNull);
      expect(result.limitations.single, contains('Sleep window'));
    });
  });
}
