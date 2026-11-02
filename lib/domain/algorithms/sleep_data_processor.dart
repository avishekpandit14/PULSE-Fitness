import '../models/sleep_session_model.dart';

enum SleepRecordKind { session, asleep, deep, light, rem, awake }

class SleepRecord {
  final SleepRecordKind kind;
  final DateTime start;
  final DateTime end;
  final String? id;

  const SleepRecord({
    required this.kind,
    required this.start,
    required this.end,
    this.id,
  });

  Duration get duration => end.difference(start);
}

class ProcessedSleepData {
  final SleepRecord session;
  final int totalMinutes;
  final int? deepMinutes;
  final int? lightMinutes;
  final int? remMinutes;
  final int? awakeMinutes;
  final SleepDataQuality dataQuality;
  final int unknownMinutes;

  const ProcessedSleepData({
    required this.session,
    required this.totalMinutes,
    this.deepMinutes,
    this.lightMinutes,
    this.remMinutes,
    this.awakeMinutes,
    this.dataQuality = SleepDataQuality.measured,
    this.unknownMinutes = 0,
  });
}

class SleepDataProcessor {
  static ProcessedSleepData? process({
    required List<SleepRecord> records,
    required DateTime now,
    Duration recentWindow = const Duration(hours: 24),
  }) {
    final valid = records
        .where((record) => record.end.isAfter(record.start))
        .toList();
    if (valid.isEmpty) return null;

    final sessionCandidates = valid
        .where((record) => record.kind == SleepRecordKind.session)
        .where(
          (record) =>
              record.end.isAfter(now.subtract(recentWindow)) &&
              !record.start.isAfter(now),
        )
        .toList();

    final session = sessionCandidates.isNotEmpty
        ? _selectSession(sessionCandidates, now)
        : _buildSessionFromStages(valid, now);
    if (session == null) return null;

    final windowStart = session.start;
    final windowEnd = session.end.isAfter(now) ? now : session.end;
    if (!windowEnd.isAfter(windowStart)) return null;

    final inWindow = valid
        .where(
          (record) =>
              record.kind != SleepRecordKind.session &&
              record.end.isAfter(windowStart) &&
              record.start.isBefore(windowEnd),
        )
        .map((record) => _clip(record, windowStart, windowEnd))
        .toList();

    final awakeRecords = _resolveOverlaps(
      inWindow.where((record) => record.kind == SleepRecordKind.awake).toList(),
    );
    final awake = _unionDuration(awakeRecords);
    final detailedStages = <SleepRecordKind>[
      SleepRecordKind.deep,
      SleepRecordKind.light,
      SleepRecordKind.rem,
    ];
    final stageDurations = <SleepRecordKind, int>{};

    var resolvedStages = _resolveOverlaps(
      inWindow.where((record) => detailedStages.contains(record.kind)).toList(),
    );
    for (final awakeRecord in awakeRecords) {
      resolvedStages = resolvedStages
          .expand((stage) => _subtractInterval(stage, awakeRecord))
          .toList();
    }
    final genericAsleep = _resolveOverlaps(
      inWindow
          .where((record) => record.kind == SleepRecordKind.asleep)
          .toList(),
    );
    final measuredAsleep = genericAsleep
        .expand(
          (record) => resolvedStages.fold<List<SleepRecord>>(
            [record],
            (fragments, stage) => fragments
                .expand((fragment) => _subtractInterval(fragment, stage))
                .toList(),
          ),
        )
        .expand(
          (record) => awakeRecords.fold<List<SleepRecord>>(
            [record],
            (fragments, awakeRecord) => fragments
                .expand((fragment) => _subtractInterval(fragment, awakeRecord))
                .toList(),
          ),
        )
        .toList();
    final measuredIntervals = [...resolvedStages, ...measuredAsleep];
    final measuredMinutes = _unionDuration(measuredIntervals);
    final expectedSleepMinutes =
        (_windowMinutes(windowStart, windowEnd) - awake).clamp(
          0,
          _windowMinutes(windowStart, windowEnd),
        );
    final quality = measuredMinutes == 0
        ? SleepDataQuality.unavailable
        : measuredMinutes < expectedSleepMinutes
        ? SleepDataQuality.partial
        : SleepDataQuality.measured;
    final unknownMinutes = (expectedSleepMinutes - measuredMinutes).clamp(
      0,
      expectedSleepMinutes,
    );
    for (final kind in detailedStages) {
      stageDurations[kind] = _unionDuration(
        resolvedStages.where((record) => record.kind == kind).toList(),
      );
    }

    return ProcessedSleepData(
      session: session,
      totalMinutes: measuredMinutes,
      deepMinutes: _nullable(stageDurations[SleepRecordKind.deep]),
      lightMinutes: _nullable(stageDurations[SleepRecordKind.light]),
      remMinutes: _nullable(stageDurations[SleepRecordKind.rem]),
      awakeMinutes: awake > 0 ? awake : null,
      dataQuality: quality,
      unknownMinutes: unknownMinutes,
    );
  }

  static SleepRecord? _selectSession(
    List<SleepRecord> candidates,
    DateTime now,
  ) {
    if (candidates.isEmpty) return null;
    final sorted = [...candidates]
      ..sort((a, b) {
        final endComparison = b.end.compareTo(a.end);
        return endComparison != 0 ? endComparison : b.start.compareTo(a.start);
      });
    return sorted.firstWhere(
      (record) => !record.end.isAfter(now),
      orElse: () => sorted.first,
    );
  }

  static SleepRecord? _buildSessionFromStages(
    List<SleepRecord> records,
    DateTime now,
  ) {
    final intervals =
        records
            .where(
              (record) =>
                  record.kind != SleepRecordKind.session &&
                  record.end.isAfter(now.subtract(const Duration(hours: 24))) &&
                  !record.start.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    if (intervals.isEmpty) return null;

    final clusters = <List<SleepRecord>>[];
    var cluster = <SleepRecord>[intervals.first];
    for (final interval in intervals.skip(1)) {
      final previousEnd = cluster
          .map((record) => record.end)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (interval.start.difference(previousEnd) <=
          const Duration(minutes: 90)) {
        cluster.add(interval);
      } else {
        clusters.add(cluster);
        cluster = [interval];
      }
    }
    clusters.add(cluster);
    final selected = clusters.last;
    final start = selected
        .map((record) => record.start)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final end = selected
        .map((record) => record.end)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return SleepRecord(kind: SleepRecordKind.session, start: start, end: end);
  }

  static SleepRecord _clip(SleepRecord record, DateTime start, DateTime end) {
    final clippedStart = record.start.isAfter(start) ? record.start : start;
    final clippedEnd = record.end.isBefore(end) ? record.end : end;
    return SleepRecord(
      kind: record.kind,
      start: clippedStart,
      end: clippedEnd,
      id: record.id,
    );
  }

  static List<SleepRecord> _resolveOverlaps(List<SleepRecord> records) {
    final sorted = [...records]
      ..sort((a, b) {
        final startComparison = a.start.compareTo(b.start);
        if (startComparison != 0) return startComparison;
        return _stagePriority(a.kind).compareTo(_stagePriority(b.kind));
      });
    final result = <SleepRecord>[];
    for (final record in sorted) {
      var fragments = <SleepRecord>[record];
      for (final existing in result) {
        final next = <SleepRecord>[];
        for (final fragment in fragments) {
          next.addAll(_subtractInterval(fragment, existing));
        }
        fragments = next;
      }
      result.addAll(fragments);
    }
    return result;
  }

  static List<SleepRecord> _subtractInterval(
    SleepRecord source,
    SleepRecord blocker,
  ) {
    if (!source.start.isBefore(blocker.end) ||
        !source.end.isAfter(blocker.start)) {
      return [source];
    }
    final fragments = <SleepRecord>[];
    if (source.start.isBefore(blocker.start)) {
      fragments.add(
        SleepRecord(kind: source.kind, start: source.start, end: blocker.start),
      );
    }
    if (source.end.isAfter(blocker.end)) {
      fragments.add(
        SleepRecord(kind: source.kind, start: blocker.end, end: source.end),
      );
    }
    return fragments;
  }

  static int _unionDuration(List<SleepRecord> records) {
    if (records.isEmpty) return 0;
    final sorted = [...records]..sort((a, b) => a.start.compareTo(b.start));
    var start = sorted.first.start;
    var end = sorted.first.end;
    var total = 0;
    for (final record in sorted.skip(1)) {
      if (!record.start.isAfter(end)) {
        if (record.end.isAfter(end)) end = record.end;
      } else {
        total += _windowMinutes(start, end);
        start = record.start;
        end = record.end;
      }
    }
    return total + _windowMinutes(start, end);
  }

  static int _windowMinutes(DateTime start, DateTime end) =>
      end.difference(start).inMinutes;

  static int _stagePriority(SleepRecordKind kind) {
    switch (kind) {
      case SleepRecordKind.deep:
        return 0;
      case SleepRecordKind.light:
        return 1;
      case SleepRecordKind.rem:
        return 2;
      case SleepRecordKind.awake:
        return 3;
      case SleepRecordKind.asleep:
      case SleepRecordKind.session:
        return 4;
    }
  }

  static int? _nullable(int? minutes) =>
      minutes == null || minutes <= 0 ? null : minutes;
}
