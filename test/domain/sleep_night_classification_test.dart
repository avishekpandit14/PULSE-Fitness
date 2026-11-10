import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_fitness/domain/algorithms/sleep_data_processor.dart';

void main() {
  // 20:00, so last night AND this afternoon's nap are both in the past.
  final now = DateTime(2026, 11, 10, 20);
  final nightStart = DateTime(2026, 11, 9, 23, 30);
  final nightEnd = DateTime(2026, 11, 10, 6, 0); // 390 min = 6h 30m
  final napStart = DateTime(2026, 11, 10, 14, 0);
  final napEnd = DateTime(2026, 11, 10, 15, 30); // 90 min

  List<SleepRecord> nightRecords() => [
    SleepRecord(
      kind: SleepRecordKind.session,
      start: nightStart,
      end: nightEnd,
    ),
    SleepRecord(
      kind: SleepRecordKind.deep,
      start: nightStart,
      end: DateTime(2026, 11, 10, 1, 0), // 90
    ),
    SleepRecord(
      kind: SleepRecordKind.light,
      start: DateTime(2026, 11, 10, 1, 0),
      end: DateTime(2026, 11, 10, 5, 30), // 270
    ),
    SleepRecord(
      kind: SleepRecordKind.rem,
      start: DateTime(2026, 11, 10, 5, 30),
      end: nightEnd, // 30
    ),
  ];

  List<SleepRecord> napRecords({DateTime? start, DateTime? end}) => [
    SleepRecord(
      kind: SleepRecordKind.session,
      start: start ?? napStart,
      end: end ?? napEnd,
    ),
    SleepRecord(
      kind: SleepRecordKind.light,
      start: start ?? napStart,
      end: end ?? napEnd,
    ),
  ];

  group('Primary nighttime sleep vs naps', () {
    test('6h30m night plus a 90 minute nap are reported separately', () {
      final night = SleepDataProcessor.processNight(
        now: now,
        records: [...nightRecords(), ...napRecords()],
      );

      expect(night, isNotNull);
      expect(night!.primary.totalMinutes, equals(390));
      expect(night.primary.session.end, equals(nightEnd));
      expect(night.naps.length, equals(1));
      expect(night.naps.single.minutes, equals(90));
      expect(night.napMinutes, equals(90));
      expect(night.primaryIsNighttime, isTrue);
    });

    test('a nap is never selected as the primary session', () {
      // The nap ends later than the night, so "latest record" logic would pick it.
      final night = SleepDataProcessor.processNight(
        now: now,
        records: [...nightRecords(), ...napRecords()],
      );

      expect(night!.primary.session.start, equals(nightStart));
      expect(night.primary.session.end, equals(nightEnd));
      expect(night.naps.every((nap) => nap.start.isAfter(nightEnd)), isTrue);
      // The nap does not reduce the primary duration.
      expect(night.primary.totalMinutes, equals(390));
    });

    test('a long afternoon block still does not replace a shorter night', () {
      final longNapStart = DateTime(2026, 11, 10, 12);
      final longNapEnd = DateTime(2026, 11, 10, 16); // 4 hours
      final night = SleepDataProcessor.processNight(
        now: now,
        records: [
          ...nightRecords(),
          ...napRecords(start: longNapStart, end: longNapEnd),
        ],
      );

      expect(night!.primary.totalMinutes, equals(390));
      expect(night.napMinutes, equals(240));
    });

    test('overlapping duplicate sessions are not double counted', () {
      final night = SleepDataProcessor.processNight(
        now: now,
        records: [
          ...nightRecords(),
          SleepRecord(
            kind: SleepRecordKind.session,
            start: nightStart.add(const Duration(minutes: 10)),
            end: nightEnd,
          ),
        ],
      );

      expect(night!.naps, isEmpty);
      expect(night.napMinutes, equals(0));
      expect(night.primary.totalMinutes, equals(390));
    });

    test('a sleep session crossing midnight is classified as nighttime', () {
      expect(
        SleepDataProcessor.isNighttimeSession(nightStart, nightEnd),
        isTrue,
      );
      expect(
        SleepDataProcessor.nightOverlapMinutes(nightStart, nightEnd),
        equals(390),
      );
      expect(SleepDataProcessor.isNighttimeSession(napStart, napEnd), isFalse);
    });

    test('a short evening sleep is a nap, not the primary night', () {
      final eveningStart = DateTime(2026, 11, 10, 19, 30);
      final eveningEnd = DateTime(2026, 11, 10, 20, 30);
      final night = SleepDataProcessor.processNight(
        now: DateTime(2026, 11, 10, 21),
        records: [
          ...nightRecords(),
          ...napRecords(start: eveningStart, end: eveningEnd),
        ],
      );

      expect(night!.primary.totalMinutes, equals(390));
      expect(night.naps.single.minutes, equals(60));
    });

    test('falls back to the longest session when nothing is at night', () {
      final daySleepStart = DateTime(2026, 11, 10, 12);
      final daySleepEnd = DateTime(2026, 11, 10, 15);
      final night = SleepDataProcessor.processNight(
        now: now,
        records: napRecords(start: daySleepStart, end: daySleepEnd),
      );

      expect(night, isNotNull);
      expect(night!.primaryIsNighttime, isFalse);
      expect(night.primary.totalMinutes, equals(180));
      expect(night.naps, isEmpty);
    });

    test('a session without any asleep interval stays unavailable', () {
      final night = SleepDataProcessor.processNight(
        now: now,
        records: [
          SleepRecord(
            kind: SleepRecordKind.session,
            start: nightStart,
            end: nightEnd,
          ),
        ],
      );

      expect(night, isNotNull);
      expect(night!.primary.totalMinutes, equals(0));
      expect(night.naps, isEmpty);
    });

    test('naps outside the recent window are ignored', () {
      final oldStart = DateTime(2026, 11, 8, 14);
      final oldEnd = DateTime(2026, 11, 8, 15, 30);
      final night = SleepDataProcessor.processNight(
        now: now,
        records: [
          ...nightRecords(),
          ...napRecords(start: oldStart, end: oldEnd),
        ],
      );

      expect(night!.naps, isEmpty);
      expect(night.primary.totalMinutes, equals(390));
    });

    test('stage-only records still produce a primary night', () {
      // No parent SLEEP_SESSION record: stages are clustered instead.
      final night = SleepDataProcessor.processNight(
        now: now,
        records: nightRecords().skip(1).toList(),
      );

      expect(night, isNotNull);
      expect(night!.primaryIsNighttime, isTrue);
      expect(night.primary.totalMinutes, equals(390));
    });
  });
}
