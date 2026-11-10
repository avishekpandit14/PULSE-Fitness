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

/// A secondary sleep period kept apart from the primary nighttime session.
class ProcessedNap {
  final SleepRecord interval;
  final int minutes;

  const ProcessedNap({required this.interval, required this.minutes});

  DateTime get start => interval.start;
  DateTime get end => interval.end;
}

/// One night of sleep split into the primary nighttime session and any naps.
class ProcessedSleepNight {
  final ProcessedSleepData primary;
  final List<ProcessedNap> naps;
  final bool primaryIsNighttime;

  const ProcessedSleepNight({
    required this.primary,
    this.naps = const [],
    this.primaryIsNighttime = true,
  });

  int get napMinutes => naps.fold(0, (sum, nap) => sum + nap.minutes);
}

class SleepDataProcessor {
  static const Duration defaultRecentWindow = Duration(hours: 24);

  /// Maximum gap between stage records that still belongs to one sleep block.
  static const Duration clusterGap = Duration(minutes: 90);

  /// Local clock band (18:00 -> 12:00 the next day) used to tell overnight
  /// sleep apart from daytime naps. Chosen so that a sleep block crossing
  /// midnight is handled naturally by interval overlap arithmetic.
  static const int nightBandStartHour = 18;
  static const int nightBandEndHour = 12;

  /// Two records overlapping by more than this share of the shorter one are
  /// treated as the same sleep period so the duration is not counted twice.
  static const double duplicateOverlapRatio = 0.5;

  static ProcessedSleepData? process({
    required List<SleepRecord> records,
    required DateTime now,
    Duration recentWindow = defaultRecentWindow,
  }) {
    final valid = _validRecords(records);
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
        : _latestCluster(valid, now, recentWindow);
    if (session == null) return null;

    return _buildProcessed(session, valid, now);
  }

  /// Splits a day of sleep records into the primary nighttime session and the
  /// naps that were also recorded.
  ///
  /// The primary session is never simply "the latest record": it is the longest
  /// session whose majority falls inside the night band. When no record touches
  /// the night band (e.g. a night-shift sleeper) the longest session is used as
  /// a fallback and the secondary periods are still reported as naps.
  static ProcessedSleepNight? processNight({
    required List<SleepRecord> records,
    required DateTime now,
    Duration recentWindow = defaultRecentWindow,
  }) {
    final valid = _validRecords(records);
    if (valid.isEmpty) return null;

    final windowStart = now.subtract(recentWindow);
    final inWindow = valid
        .where(
          (record) =>
              record.end.isAfter(windowStart) && !record.start.isAfter(now),
        )
        .toList();
    if (inWindow.isEmpty) return null;

    final sessionRecords = inWindow
        .where((record) => record.kind == SleepRecordKind.session)
        .toList();

    final candidates = sessionRecords.isNotEmpty
        ? sessionRecords
        : _clusterSessions(inWindow, now: now, windowStart: windowStart);
    if (candidates.isEmpty) return null;

    final built = candidates
        .map((candidate) => _buildProcessed(candidate, valid, now))
        .whereType<ProcessedSleepData>()
        .toList();
    if (built.isEmpty) return null;

    final deduped = _dedupeSessions(built);
    final nighttime = deduped
        .where(
          (data) => isNighttimeSession(data.session.start, data.session.end),
        )
        .toList();

    final primary = nighttime.isNotEmpty
        ? _pickPrimary(nighttime)
        : _pickPrimary(deduped);
    final primaryIsNighttime = nighttime.isNotEmpty;

    final naps = <ProcessedNap>[];
    for (final data in deduped) {
      if (identical(data, primary)) continue;
      if (data.totalMinutes <= 0) continue;
      if (_overlapRatio(data.session, primary.session) >=
          duplicateOverlapRatio) {
        continue;
      }
      final duplicatesExistingNap = naps.any(
        (nap) =>
            _overlapRatio(data.session, nap.interval) >= duplicateOverlapRatio,
      );
      if (duplicatesExistingNap) continue;
      naps.add(
        ProcessedNap(interval: data.session, minutes: data.totalMinutes),
      );
    }
    naps.sort((a, b) => a.start.compareTo(b.start));

    return ProcessedSleepNight(
      primary: primary,
      naps: naps,
      primaryIsNighttime: primaryIsNighttime,
    );
  }

  /// True when the majority of the [start]-[end] window sits inside a night
  /// band (18:00 -> 12:00). Works for sessions that cross midnight.
  static bool isNighttimeSession(DateTime start, DateTime end) {
    final total = end.difference(start).inMinutes;
    if (total <= 0) return false;
    return nightOverlapMinutes(start, end) * 2 >= total;
  }

  /// Minutes of [start]-[end] that fall inside any night band. Deterministic
  /// interval arithmetic, no timezone assumptions beyond local `DateTime` walls.
  static int nightOverlapMinutes(DateTime start, DateTime end) {
    var overlap = 0;
    var day = DateTime(start.year, start.month, start.day - 1);
    final lastDay = DateTime(end.year, end.month, end.day);
    while (!day.isAfter(lastDay)) {
      final bandStart = DateTime(
        day.year,
        day.month,
        day.day,
        nightBandStartHour,
      );
      final bandEnd = DateTime(
        day.year,
        day.month,
        day.day + 1,
        nightBandEndHour,
      );
      final clippedStart = start.isAfter(bandStart) ? start : bandStart;
      final clippedEnd = end.isBefore(bandEnd) ? end : bandEnd;
      if (clippedEnd.isAfter(clippedStart)) {
        overlap += clippedEnd.difference(clippedStart).inMinutes;
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return overlap;
  }

  static List<SleepRecord> _validRecords(List<SleepRecord> records) =>
      records.where((record) => record.end.isAfter(record.start)).toList();

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

  static SleepRecord? _latestCluster(
    List<SleepRecord> records,
    DateTime now,
    Duration recentWindow,
  ) {
    final clusters = _clusterSessions(
      records,
      now: now,
      windowStart: now.subtract(recentWindow),
    );
    return clusters.isEmpty ? null : clusters.last;
  }

  /// Groups stage records into sleep blocks separated by more than
  /// [clusterGap]. Used only when the tracker does not report a parent
  /// `SLEEP_SESSION` record.
  static List<SleepRecord> _clusterSessions(
    List<SleepRecord> records, {
    required DateTime now,
    required DateTime windowStart,
  }) {
    final intervals =
        records
            .where(
              (record) =>
                  record.kind != SleepRecordKind.session &&
                  record.end.isAfter(windowStart) &&
                  !record.start.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    if (intervals.isEmpty) return const [];

    final clusters = <List<SleepRecord>>[];
    var cluster = <SleepRecord>[intervals.first];
    for (final interval in intervals.skip(1)) {
      final previousEnd = cluster
          .map((record) => record.end)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (interval.start.difference(previousEnd) <= clusterGap) {
        cluster.add(interval);
      } else {
        clusters.add(cluster);
        cluster = [interval];
      }
    }
    clusters.add(cluster);

    return clusters.map((records) {
      final start = records
          .map((record) => record.start)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final end = records
          .map((record) => record.end)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return SleepRecord(kind: SleepRecordKind.session, start: start, end: end);
    }).toList();
  }

  static ProcessedSleepData? _buildProcessed(
    SleepRecord session,
    List<SleepRecord> valid,
    DateTime now,
  ) {
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

  /// Keeps the longest session of each overlapping group so duplicate or
  /// partially duplicated tracker records are not counted twice.
  static List<ProcessedSleepData> _dedupeSessions(
    List<ProcessedSleepData> sessions,
  ) {
    final sorted = [...sessions]
      ..sort((a, b) {
        final minutes = b.totalMinutes.compareTo(a.totalMinutes);
        return minutes != 0
            ? minutes
            : a.session.start.compareTo(b.session.start);
      });
    final result = <ProcessedSleepData>[];
    for (final session in sorted) {
      final overlaps = result.any(
        (existing) =>
            _overlapRatio(session.session, existing.session) >=
            duplicateOverlapRatio,
      );
      if (!overlaps) result.add(session);
    }
    return result;
  }

  static ProcessedSleepData _pickPrimary(List<ProcessedSleepData> sessions) {
    final sorted = [...sessions]
      ..sort((a, b) {
        final minutes = b.totalMinutes.compareTo(a.totalMinutes);
        if (minutes != 0) return minutes;
        final window = _windowMinutes(
          b.session.start,
          b.session.end,
        ).compareTo(_windowMinutes(a.session.start, a.session.end));
        return window != 0
            ? window
            : a.session.start.compareTo(b.session.start);
      });
    return sorted.first;
  }

  static double _overlapRatio(SleepRecord a, SleepRecord b) {
    final start = a.start.isAfter(b.start) ? a.start : b.start;
    final end = a.end.isBefore(b.end) ? a.end : b.end;
    if (!end.isAfter(start)) return 0;
    final overlap = end.difference(start).inMinutes;
    final shortest = [
      _windowMinutes(a.start, a.end),
      _windowMinutes(b.start, b.end),
    ].reduce((x, y) => x < y ? x : y);
    if (shortest <= 0) return 0;
    return overlap / shortest;
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
