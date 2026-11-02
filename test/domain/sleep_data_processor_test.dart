import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_fitness/domain/algorithms/sleep_data_processor.dart';
import 'package:pulse_fitness/domain/models/sleep_session_model.dart';

void main() {
  final wake = DateTime(2026, 11, 2, 6, 27);
  final bedtime = DateTime(2026, 11, 2, 0, 9);

  test('uses the selected overnight session window for total sleep', () {
    final result = SleepDataProcessor.process(
      now: wake,
      records: [
        SleepRecord(kind: SleepRecordKind.session, start: bedtime, end: wake),
        SleepRecord(
          kind: SleepRecordKind.deep,
          start: DateTime(2026, 11, 2, 0, 30),
          end: DateTime(2026, 11, 2, 2),
        ),
        SleepRecord(
          kind: SleepRecordKind.light,
          start: DateTime(2026, 11, 2, 2),
          end: DateTime(2026, 11, 2, 5),
        ),
        SleepRecord(
          kind: SleepRecordKind.rem,
          start: DateTime(2026, 11, 2, 5),
          end: DateTime(2026, 11, 2, 6),
        ),
        SleepRecord(
          kind: SleepRecordKind.awake,
          start: DateTime(2026, 11, 2, 6),
          end: wake,
        ),
      ],
    );

    expect(result, isNotNull);
    expect(result!.totalMinutes, equals(330));
    expect(result.dataQuality, equals(SleepDataQuality.partial));
    expect(result.unknownMinutes, equals(21));
    expect(result.session.start, equals(bedtime));
    expect(result.session.end, equals(wake));
    expect(
      (result.deepMinutes ?? 0) +
          (result.lightMinutes ?? 0) +
          (result.remMinutes ?? 0) +
          (result.awakeMinutes ?? 0),
      lessThanOrEqualTo(378),
    );
  });

  test('deduplicates duplicate and overlapping stage records', () {
    final result = SleepDataProcessor.process(
      now: wake,
      records: [
        SleepRecord(kind: SleepRecordKind.session, start: bedtime, end: wake),
        SleepRecord(
          kind: SleepRecordKind.deep,
          start: DateTime(2026, 11, 2, 1),
          end: DateTime(2026, 11, 2, 2),
          id: 'a',
        ),
        SleepRecord(
          kind: SleepRecordKind.deep,
          start: DateTime(2026, 11, 2, 1),
          end: DateTime(2026, 11, 2, 2),
          id: 'duplicate',
        ),
        SleepRecord(
          kind: SleepRecordKind.light,
          start: DateTime(2026, 11, 2, 1, 45),
          end: DateTime(2026, 11, 2, 3),
        ),
      ],
    );

    expect(result!.deepMinutes, equals(60));
    expect(result.lightMinutes, equals(60));
    expect(result.totalMinutes, equals(120));
    expect(result.dataQuality, equals(SleepDataQuality.partial));
    expect(result.unknownMinutes, equals(258));
  });

  test('keeps stage and awake totals within the selected sleep window', () {
    final result = SleepDataProcessor.process(
      now: wake,
      records: [
        SleepRecord(kind: SleepRecordKind.session, start: bedtime, end: wake),
        SleepRecord(
          kind: SleepRecordKind.deep,
          start: DateTime(2026, 11, 2, 1),
          end: DateTime(2026, 11, 2, 2),
        ),
        SleepRecord(
          kind: SleepRecordKind.awake,
          start: DateTime(2026, 11, 2, 1, 30),
          end: DateTime(2026, 11, 2, 2, 30),
        ),
      ],
    );

    final stageAndAwake =
        (result!.deepMinutes ?? 0) + (result.awakeMinutes ?? 0);
    expect(stageAndAwake, lessThanOrEqualTo(378));
    expect(result.deepMinutes, equals(30));
    expect(result.awakeMinutes, equals(60));
  });

  test('does not add generic asleep records to detailed stages', () {
    final result = SleepDataProcessor.process(
      now: wake,
      records: [
        SleepRecord(kind: SleepRecordKind.session, start: bedtime, end: wake),
        SleepRecord(kind: SleepRecordKind.asleep, start: bedtime, end: wake),
        SleepRecord(
          kind: SleepRecordKind.deep,
          start: DateTime(2026, 11, 2, 1),
          end: DateTime(2026, 11, 2, 2),
        ),
        SleepRecord(
          kind: SleepRecordKind.light,
          start: DateTime(2026, 11, 2, 2),
          end: DateTime(2026, 11, 2, 5),
        ),
        SleepRecord(
          kind: SleepRecordKind.rem,
          start: DateTime(2026, 11, 2, 5),
          end: DateTime(2026, 11, 2, 6),
        ),
      ],
    );

    expect(result!.totalMinutes, equals(378));
    expect(result.deepMinutes, equals(60));
    expect(result.lightMinutes, equals(180));
    expect(result.remMinutes, equals(60));
  });

  test(
    'selects the most recent overnight session and ignores another date',
    () {
      final result = SleepDataProcessor.process(
        now: wake,
        records: [
          SleepRecord(
            kind: SleepRecordKind.session,
            start: DateTime(2026, 11, 1, 22),
            end: DateTime(2026, 11, 1, 23),
          ),
          SleepRecord(kind: SleepRecordKind.session, start: bedtime, end: wake),
          SleepRecord(kind: SleepRecordKind.asleep, start: bedtime, end: wake),
        ],
      );

      expect(result!.session.start, equals(bedtime));
      expect(result.session.end, equals(wake));
      expect(result.totalMinutes, equals(378));
    },
  );

  test('marks sparse detailed stages as partial without inferring gaps', () {
    final result = SleepDataProcessor.process(
      now: wake,
      records: [
        SleepRecord(kind: SleepRecordKind.session, start: bedtime, end: wake),
        SleepRecord(
          kind: SleepRecordKind.deep,
          start: DateTime(2026, 11, 2, 1),
          end: DateTime(2026, 11, 2, 2),
        ),
      ],
    );

    expect(result!.totalMinutes, equals(60));
    expect(result.dataQuality, equals(SleepDataQuality.partial));
    expect(result.unknownMinutes, equals(318));
  });

  test('reports a parent session without asleep intervals as unavailable', () {
    final result = SleepDataProcessor.process(
      now: wake,
      records: [
        SleepRecord(kind: SleepRecordKind.session, start: bedtime, end: wake),
      ],
    );

    expect(result!.totalMinutes, equals(0));
    expect(result.dataQuality, equals(SleepDataQuality.unavailable));
    expect(result.unknownMinutes, equals(378));
  });
}
