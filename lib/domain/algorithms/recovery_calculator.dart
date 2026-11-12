import '../models/checkin_model.dart';
import '../models/recovery_result.dart';
import '../models/sleep_session_model.dart';
import 'nighttime_heart_rate_analyzer.dart';
import 'sleep_quality_analyzer.dart';

/// Transparent, deterministic, HRV-free recovery score calculation.
/// Designed for trackers that expose standard health signals through Health Connect,
/// including devices where nocturnal HRV is not reported.
class RecoveryCalculator {
  // Configurable heuristic weights (must sum to 1.0).
  //
  // Sleep *quality* is the primary sleep signal: how the night was built
  // (efficiency, deep, REM) matters more than how long it was, because a long
  // shallow night is not restorative. Duration is kept as a smaller signal and
  // its credit is capped by quality, so 8-9 hours of light, fragmented sleep
  // can no longer produce a high recovery score by length alone.
  static const double defaultSleepQualityWeight = 0.30;
  static const double defaultNightHrWeight = 0.18;
  static const double defaultSleepWeight = 0.15;
  static const double defaultStrainWeight = 0.15;
  static const double defaultEnergyWeight = 0.08;
  static const double defaultSorenessWeight = 0.08;
  static const double defaultFatigueWeight = 0.06;

  // Minimum consecutive RHR daily observations needed before establishing a personal baseline
  static const int minRhrBaselineObservations = 3;

  // Minimum active weight coverage to generate a score (35% threshold)
  static const double minWeightThreshold = 0.35;

  /// Computes the comprehensive recovery result.
  ///
  /// [sleepQuality] and [nightHeartRate] are optional so callers that only have
  /// a sleep session still work; quality is then derived from the session when
  /// stages are available. Nothing is ever substituted with a zero reading: an
  /// unavailable signal is excluded and the remaining weights are re-normalised.
  static RecoveryResult calculate({
    required SleepSessionModel? sleepSession,
    required double? todayRhr,
    required List<double> historicalRhrs,
    required double? yesterdayStrain,
    required CheckInModel? checkIn,
    required double sleepTargetHours,
    SleepQualityResult? sleepQuality,
    NighttimeHeartRateAnalysis? nightHeartRate,
    int napMinutes = 0,
  }) {
    final Map<String, double> componentScores = {};
    final Map<String, double> rawWeights = {};
    final List<String> availableSignals = [];
    final List<String> missingSignals = [];

    final quality =
        sleepQuality ??
        (sleepSession != null && sleepSession.totalMinutes > 0
            ? SleepQualityAnalyzer.analyze(sleepSession)
            : null);

    // 1. Sleep Quality Score (30%) - stages + efficiency, never duration alone.
    // This is deliberately scored and listed before duration: it is the primary
    // sleep driver of recovery, so two nights of equal length can, and should,
    // land far apart.
    if (quality != null && quality.score != null) {
      componentScores['Sleep Quality'] = quality.score!;
      rawWeights['Sleep Quality'] = defaultSleepQualityWeight;
      availableSignals.add(_qualitySignalLabel(quality));
    } else {
      missingSignals.add(
        'Sleep Quality (No sleep stage or awake data was reported, so quality '
        'could not be assessed)',
      );
    }

    // 2. Sleep Duration Score (15%) - secondary, and capped by quality so a
    // long shallow night cannot carry the score on hours alone.
    if (sleepSession != null && sleepSession.totalMinutes > 0) {
      final rawDurationScore = calculateSleepScore(
        actualMinutes: sleepSession.totalMinutes,
        targetHours: sleepTargetHours,
      );
      final durationScore = calculateRestorativeDurationScore(
        durationScore: rawDurationScore,
        qualityScore: quality?.score,
      );
      componentScores['Sleep Duration'] = durationScore;
      rawWeights['Sleep Duration'] = defaultSleepWeight;
      final capApplied = durationScore < rawDurationScore - 0.5;
      availableSignals.add(
        'Sleep Duration (${sleepSession.hours.toStringAsFixed(1)}h'
        '${capApplied ? ', credit capped by sleep quality' : ''})',
      );
    } else {
      missingSignals.add(
        'Sleep Session (No compatible nighttime sleep record was found)',
      );
    }

    // 3. Heart rate (18%): nighttime HR is preferred and scored against the
    // user's own nightly baseline. Resting HR is only used as a fallback, so the
    // two correlated signals can never be counted twice.
    final double? baselineRhr = _computeRhrBaseline(historicalRhrs);
    final int rhrObservationsCount = historicalRhrs.length;
    var heartRateScored = false;

    if (nightHeartRate != null && nightHeartRate.hasUsableData) {
      if (nightHeartRate.hasBaseline) {
        final nightScore = calculateNightHrScore(
          averageBpm: nightHeartRate.averageBpm!,
          baselineBpm: nightHeartRate.baselineBpm!,
          stabilityScore: nightHeartRate.stabilityScore,
          trendDeltaBpm: nightHeartRate.trendDeltaBpm,
        );
        componentScores['Nighttime HR'] = nightScore;
        rawWeights['Nighttime HR'] = defaultNightHrWeight;
        heartRateScored = true;
        availableSignals.add(
          'Nighttime HR (${nightHeartRate.averageBpm!.round()} bpm vs '
          '${nightHeartRate.baselineBpm!.round()} bpm baseline)',
        );
      } else {
        missingSignals.add(
          'Nighttime HR Baseline (${nightHeartRate.baselineNightCount}/'
          '${NighttimeHeartRateAnalyzer.minBaselineNights} nights logged. '
          'Nighttime HR is compared with your own history, not an absolute value.)',
        );
      }
    } else if (nightHeartRate != null) {
      missingSignals.add(
        'Nighttime Heart Rate (${nightHeartRate.sampleCount} usable samples; '
        'nighttime HR is excluded rather than estimated)',
      );
    }

    if (!heartRateScored) {
      if (todayRhr != null && todayRhr > 30 && todayRhr < 180) {
        if (baselineRhr != null) {
          final rhrScore = calculateRhrScore(
            todayRhr: todayRhr,
            baselineRhr: baselineRhr,
          );
          componentScores['Resting HR'] = rhrScore;
          rawWeights['Resting HR'] = defaultNightHrWeight;
          heartRateScored = true;
          availableSignals.add(
            'Resting HR (${todayRhr.round()} bpm vs baseline '
            '${baselineRhr.round()} bpm)',
          );
        } else {
          missingSignals.add(
            'RHR Baseline ($rhrObservationsCount/$minRhrBaselineObservations days logged. Baseline establishing...)',
          );
        }
      } else {
        missingSignals.add(
          'Heart Rate (No resting or nighttime heart rate sample recorded)',
        );
      }
    }

    // 4. Recent Training Load Score (15%)
    if (yesterdayStrain != null) {
      final strainScore = calculateStrainRecoveryScore(yesterdayStrain);
      componentScores['Recent Load'] = strainScore;
      rawWeights['Recent Load'] = defaultStrainWeight;
      availableSignals.add(
        'Recent Strain (${yesterdayStrain.toStringAsFixed(1)})',
      );
    } else {
      // If yesterday strain is unknown, omit signal rather than assuming zero
      missingSignals.add('Recent Training Load (No prior day strain tracked)');
    }

    // 5. Daily Check-in: Energy (9%), Soreness (8%), Fatigue (5%)
    if (checkIn != null) {
      final energyScore = calculateEnergyScore(checkIn.energy);
      final sorenessScore = calculateSorenessScore(checkIn.muscleSoreness);
      final fatigueScore = calculateFatigueScore(checkIn.fatigue);

      componentScores['Energy'] = energyScore;
      rawWeights['Energy'] = defaultEnergyWeight;

      componentScores['Muscle Soreness'] = sorenessScore;
      rawWeights['Muscle Soreness'] = defaultSorenessWeight;

      componentScores['Fatigue'] = fatigueScore;
      rawWeights['Fatigue'] = defaultFatigueWeight;

      availableSignals.add('Subjective Check-in (Energy, Soreness, Fatigue)');
    } else {
      missingSignals.add('Daily Check-in (Pending user morning check-in)');
    }

    // Calculate sum of active weights
    final double activeWeightSum = rawWeights.values.fold(0.0, (a, b) => a + b);

    // If active weight is below threshold, data is insufficient
    if (activeWeightSum < minWeightThreshold) {
      return RecoveryResult(
        score: null,
        category: RecoveryCategory.notEnoughData,
        confidence: ConfidenceLevel.low,
        shortExplanation:
            'Not enough data to calculate an accurate recovery estimate.',
        detailedExplanation:
            'Recovery calculation requires at least a nighttime sleep session from Health Connect '
            'or a completed subjective check-in. Total signal coverage is currently '
            '${(activeWeightSum * 100).round()}%, below the 35% minimum threshold.',
        componentScores: componentScores,
        componentWeights: {},
        availableSignals: availableSignals,
        missingSignals: missingSignals,
        baselineRhr: baselineRhr,
        todayRhr: todayRhr,
        rhrObservationsCount: rhrObservationsCount,
        sleepMinutes: sleepSession?.totalMinutes,
        sleepTargetMinutes: (sleepTargetHours * 60).round(),
        checkIn: checkIn,
        yesterdayStrain: yesterdayStrain,
        sleepQuality: quality,
        nightHeartRate: nightHeartRate,
        napMinutes: napMinutes,
      );
    }

    // Re-normalize weights to 1.0 (100%)
    final Map<String, double> normalizedWeights = {};
    double weightedScoreSum = 0.0;

    for (final entry in rawWeights.entries) {
      final normalizedWeight = entry.value / activeWeightSum;
      normalizedWeights[entry.key] = normalizedWeight;
      weightedScoreSum += (componentScores[entry.key]! * normalizedWeight);
    }

    final int finalScore = weightedScoreSum.round().clamp(1, 99);

    // Determine category
    final RecoveryCategory category;
    if (finalScore >= 67) {
      category = RecoveryCategory.ready;
    } else if (finalScore >= 34) {
      category = RecoveryCategory.moderate;
    } else {
      category = RecoveryCategory.restRecommended;
    }

    // Determine confidence level based on raw coverage percentage
    final ConfidenceLevel confidence;
    if (activeWeightSum >= 0.85) {
      confidence = ConfidenceLevel.high;
    } else if (activeWeightSum >= 0.50) {
      confidence = ConfidenceLevel.moderate;
    } else {
      confidence = ConfidenceLevel.low;
    }

    // Explainable contributions, largest absolute influence first.
    final factors = <RecoveryFactor>[];
    for (final entry in normalizedWeights.entries) {
      final name = entry.key;
      factors.add(
        RecoveryFactor(
          name: name,
          impactPoints: (componentScores[name]! - 50.0) * entry.value,
          detail: _factorDetail(
            name: name,
            sleepSession: sleepSession,
            quality: quality,
            nightHeartRate: nightHeartRate,
            baselineRhr: baselineRhr,
            todayRhr: todayRhr,
            yesterdayStrain: yesterdayStrain,
            checkIn: checkIn,
            sleepTargetHours: sleepTargetHours,
          ),
        ),
      );
    }
    factors.sort(
      (a, b) => b.impactPoints.abs().compareTo(a.impactPoints.abs()),
    );

    // Explanations
    final String shortExplanation = _buildShortExplanation(
      category: category,
      componentScores: componentScores,
      baselineRhr: baselineRhr,
      todayRhr: todayRhr,
      quality: quality,
      nightHeartRate: nightHeartRate,
    );

    final String detailedExplanation = _buildDetailedExplanation(
      category: category,
      score: finalScore,
      coveragePercent: (activeWeightSum * 100).round(),
      availableSignals: availableSignals,
      missingSignals: missingSignals,
      quality: quality,
      nightHeartRate: nightHeartRate,
    );

    return RecoveryResult(
      score: finalScore,
      category: category,
      confidence: confidence,
      shortExplanation: shortExplanation,
      detailedExplanation: detailedExplanation,
      componentScores: componentScores,
      componentWeights: normalizedWeights,
      availableSignals: availableSignals,
      missingSignals: missingSignals,
      baselineRhr: baselineRhr,
      todayRhr: todayRhr,
      rhrObservationsCount: rhrObservationsCount,
      sleepMinutes: sleepSession?.totalMinutes,
      sleepTargetMinutes: (sleepTargetHours * 60).round(),
      checkIn: checkIn,
      yesterdayStrain: yesterdayStrain,
      sleepQuality: quality,
      nightHeartRate: nightHeartRate,
      factors: factors,
      napMinutes: napMinutes,
    );
  }

  /// Calculates sleep component score (0-100) based on target ratio.
  /// Does not reward implausible oversleeping without limit.
  static double calculateSleepScore({
    required int actualMinutes,
    required double targetHours,
  }) {
    final targetMinutes = (targetHours * 60).clamp(240, 720).toDouble();
    if (targetMinutes <= 0) return 70.0;

    final ratio = actualMinutes / targetMinutes;

    if (ratio <= 0.4) {
      // Under 40% of target (e.g. <3.2h for 8h): severe sleep deficit
      return (ratio / 0.4 * 30.0).clamp(5.0, 30.0);
    } else if (ratio < 1.0) {
      // 40% to 100% of target: linear progression from 30 to 95
      final progress = (ratio - 0.4) / 0.6;
      return 30.0 + (progress * 65.0);
    } else if (ratio <= 1.15) {
      // 100% to 115% of target: optimal sweet spot (95 to 100)
      final bonus = (ratio - 1.0) / 0.15;
      return 95.0 + (bonus * 5.0);
    } else {
      // Oversleeping (>115%): slight penalty for lethargy / prolonged bed rest
      // At 140% target (e.g. 11.2h), drops to ~85. Does not collapse, but plateaus.
      final excess = ratio - 1.15;
      final penalty = excess * 40.0;
      return (100.0 - penalty).clamp(70.0, 100.0);
    }
  }

  /// Caps the duration component by how restorative the night actually was.
  ///
  /// Duration credit can never exceed the midpoint between a perfect quality
  /// score (100) and the measured quality: at quality 100 the full duration
  /// score is available, while at quality 40 the cap is 70. Eight restless
  /// hours therefore cannot be scored like eight well-architected hours, even
  /// though both are the same length.
  ///
  /// When quality cannot be assessed (no stage or awake data) the duration
  /// score is returned unchanged - missing tracker data is never punished as if
  /// it were bad sleep.
  static double calculateRestorativeDurationScore({
    required double durationScore,
    double? qualityScore,
  }) {
    if (qualityScore == null) return durationScore.clamp(0.0, 100.0);
    final cap = (100.0 + qualityScore.clamp(0.0, 100.0)) / 2.0;
    return durationScore.clamp(0.0, cap);
  }

  /// Calculates resting heart rate recovery score (0-100) relative to personal baseline.
  static double calculateRhrScore({
    required double todayRhr,
    required double baselineRhr,
  }) {
    final delta = todayRhr - baselineRhr;

    if (delta <= -3.0) {
      // Significantly below baseline indicates strong autonomic recovery
      return 100.0;
    } else if (delta <= 0.0) {
      // At or slightly below baseline (88 to 98)
      return 90.0 - (delta * 3.0);
    } else if (delta <= 5.0) {
      // Slightly elevated (e.g. +1 to +5 bpm): mild autonomic stress (65 to 85)
      return 85.0 - (delta * 4.0);
    } else if (delta <= 10.0) {
      // Moderately elevated (+6 to +10 bpm): significant fatigue (35 to 60)
      return 65.0 - ((delta - 5.0) * 6.0);
    } else {
      // Severely elevated (+10+ bpm): poor recovery, possible illness or overtraining (10 to 30)
      final score = 35.0 - ((delta - 10.0) * 3.0);
      return score.clamp(5.0, 35.0);
    }
  }

  /// Nighttime heart rate score (0-100).
  ///
  /// Combines the deviation from the user's own nightly average (65%), how
  /// stable the night was (20%) and whether heart rate settled through the night
  /// (15%). Stability is dispersion of sampled BPM values, not HRV.
  static double calculateNightHrScore({
    required double averageBpm,
    required double baselineBpm,
    double? stabilityScore,
    double? trendDeltaBpm,
  }) {
    var weighted = 0.0;
    var weights = 0.0;

    final deltaScore = calculateRhrScore(
      todayRhr: averageBpm,
      baselineRhr: baselineBpm,
    );
    weighted += deltaScore * 0.65;
    weights += 0.65;

    if (stabilityScore != null) {
      weighted += stabilityScore.clamp(0.0, 100.0) * 0.20;
      weights += 0.20;
    }
    if (trendDeltaBpm != null) {
      weighted += _trendScore(trendDeltaBpm) * 0.15;
      weights += 0.15;
    }
    if (weights <= 0) return deltaScore;
    return (weighted / weights).clamp(0.0, 100.0);
  }

  /// A heart rate that trends *up* across the night is the abnormal pattern.
  /// Flat or gently falling values score highest; steep rises lose points.
  static double _trendScore(double deltaBpm) {
    if (deltaBpm <= 0) return 100.0;
    return (100.0 - deltaBpm * 5.0).clamp(40.0, 100.0);
  }

  /// Calculates recent training load score (0-100) based on yesterday's strain.
  static double calculateStrainRecoveryScore(double yesterdayStrain) {
    if (yesterdayStrain <= 6.0) {
      // Rest or active recovery day
      return 95.0;
    } else if (yesterdayStrain <= 11.0) {
      // Moderate aerobic load
      return 82.0;
    } else if (yesterdayStrain <= 15.0) {
      // High training load
      return 68.0;
    } else {
      // All-out intense exertion
      return 45.0;
    }
  }

  /// Normalizes energy rating (1-10) to 0-100.
  static double calculateEnergyScore(int energy) {
    final clamped = energy.clamp(1, 10);
    return ((clamped - 1) / 9.0) * 100.0;
  }

  /// Normalizes muscle soreness rating (0-10) to 0-100 (inverted: 0 soreness = 100 score).
  static double calculateSorenessScore(int soreness) {
    final clamped = soreness.clamp(0, 10);
    return ((10 - clamped) / 10.0) * 100.0;
  }

  /// Normalizes fatigue rating (0-10) to 0-100 (inverted: 0 fatigue = 100 score).
  static double calculateFatigueScore(int fatigue) {
    final clamped = fatigue.clamp(0, 10);
    return ((10 - clamped) / 10.0) * 100.0;
  }

  /// Computes personal baseline RHR from historical observations.
  /// Requires at least [minRhrBaselineObservations] valid samples.
  static double? _computeRhrBaseline(List<double> historicalRhrs) {
    final valid = historicalRhrs.where((r) => r >= 35 && r <= 150).toList();
    if (valid.length < minRhrBaselineObservations) {
      return null;
    }
    // Simple 7-day moving average (or up to 14 days)
    final recent = valid.length > 14 ? valid.sublist(valid.length - 14) : valid;
    final sum = recent.fold(0.0, (a, b) => a + b);
    return sum / recent.length;
  }

  static String _qualitySignalLabel(SleepQualityResult quality) {
    final parts = <String>[];
    if (quality.deepRatio != null) {
      parts.add('Deep ${(quality.deepRatio! * 100).round()}%');
    }
    if (quality.remRatio != null) {
      parts.add('REM ${(quality.remRatio! * 100).round()}%');
    }
    if (quality.efficiency != null) {
      parts.add('Efficiency ${(quality.efficiency! * 100).round()}%');
    }
    final detail = parts.isEmpty ? 'limited stage data' : parts.join(', ');
    return 'Sleep Quality (${quality.score!.round()}/100 — $detail)';
  }

  static String _factorDetail({
    required String name,
    required SleepSessionModel? sleepSession,
    required SleepQualityResult? quality,
    required NighttimeHeartRateAnalysis? nightHeartRate,
    required double? baselineRhr,
    required double? todayRhr,
    required double? yesterdayStrain,
    required CheckInModel? checkIn,
    required double sleepTargetHours,
  }) {
    switch (name) {
      case 'Sleep Duration':
        final hours = (sleepSession?.hours ?? 0).toStringAsFixed(1);
        final base =
            '$hours h of ${sleepTargetHours.toStringAsFixed(1)} h target';
        final qualityScore = quality?.score;
        if (sleepSession == null || qualityScore == null) return base;
        final rawScore = calculateSleepScore(
          actualMinutes: sleepSession.totalMinutes,
          targetHours: sleepTargetHours,
        );
        final capped = calculateRestorativeDurationScore(
          durationScore: rawScore,
          qualityScore: qualityScore,
        );
        if (capped >= rawScore - 0.5) return base;
        return '$base • capped to ${capped.round()} by sleep quality';
      case 'Sleep Quality':
        if (quality == null) return 'Not assessed';
        return quality.availableFactors.isEmpty
            ? 'Limited stage data'
            : quality.availableFactors.join(' • ');
      case 'Nighttime HR':
        final avg = nightHeartRate?.averageBpm?.round();
        final base = nightHeartRate?.baselineBpm?.round();
        final delta = nightHeartRate?.baselineDeltaBpm?.round();
        if (avg == null || base == null) return 'Nighttime HR not established';
        final sign = (delta ?? 0) >= 0 ? '+' : '';
        return '$avg bpm vs $base bpm baseline ($sign$delta bpm)';
      case 'Resting HR':
        if (todayRhr == null || baselineRhr == null) return 'No baseline yet';
        final delta = (todayRhr - baselineRhr).round();
        final sign = delta >= 0 ? '+' : '';
        return '${todayRhr.round()} bpm vs ${baselineRhr.round()} bpm baseline '
            '($sign$delta bpm)';
      case 'Recent Load':
        return yesterdayStrain == null
            ? 'No prior day strain'
            : 'Yesterday strain ${yesterdayStrain.toStringAsFixed(1)}';
      case 'Energy':
        return 'Rated ${checkIn?.energy ?? 0}/10';
      case 'Muscle Soreness':
        return 'Rated ${checkIn?.muscleSoreness ?? 0}/10 soreness';
      case 'Fatigue':
        return 'Rated ${checkIn?.fatigue ?? 0}/10 fatigue';
      default:
        return '';
    }
  }

  static String _buildShortExplanation({
    required RecoveryCategory category,
    required Map<String, double> componentScores,
    required double? baselineRhr,
    required double? todayRhr,
    required SleepQualityResult? quality,
    required NighttimeHeartRateAnalysis? nightHeartRate,
  }) {
    final goodArchitecture =
        (quality?.score ?? 0) >= 70 && quality?.hasStageData == true;

    switch (category) {
      case RecoveryCategory.ready:
        if (goodArchitecture && nightHeartRate?.hasBaseline == true) {
          return 'Sleep architecture and overnight heart rate both look settled, so your body is primed for a productive session.';
        }
        if (todayRhr != null &&
            baselineRhr != null &&
            todayRhr <= baselineRhr) {
          return 'Cardiovascular indicators and rest duration show optimal readiness for high-intensity training.';
        }
        return 'Sufficient rest and subjective vitality indicate your body is ready for productive training load.';
      case RecoveryCategory.moderate:
        if (quality != null &&
            quality.isAvailable &&
            quality.score! < 60 &&
            nightHeartRate?.hasBaseline == true) {
          return 'Sleep length is acceptable, but lighter or more fragmented sleep and overnight heart rate suggest a moderate day.';
        }
        return 'Balanced recovery profile. Suitable for aerobic maintenance, strength progression, or technique drills.';
      case RecoveryCategory.restRecommended:
        if (todayRhr != null &&
            baselineRhr != null &&
            todayRhr > baselineRhr + 4) {
          return 'Elevated resting heart rate and cumulative fatigue suggest prioritising active recovery or sleep.';
        }
        if (nightHeartRate != null &&
            nightHeartRate.hasBaseline &&
            (nightHeartRate.baselineDeltaBpm ?? 0) > 4) {
          return 'Your overnight heart rate ran above your personal baseline, pointing to incomplete recovery.';
        }
        return 'Restorative recovery needed. Low sleep or elevated fatigue indicates higher vulnerability to overtraining.';
      case RecoveryCategory.notEnoughData:
        return 'Sync sleep or complete your morning check-in to establish recovery.';
    }
  }

  static String _buildDetailedExplanation({
    required RecoveryCategory category,
    required int score,
    required int coveragePercent,
    required List<String> availableSignals,
    required List<String> missingSignals,
    required SleepQualityResult? quality,
    required NighttimeHeartRateAnalysis? nightHeartRate,
  }) {
    final buffer = StringBuffer();
    buffer.write(
      'Recovery estimate of $score/100 derived from $coveragePercent% available telemetry signals. ',
    );

    if (missingSignals.isNotEmpty) {
      buffer.write(
        'Missing signals (${missingSignals.length}) were excluded and remaining weights were re-normalized to 100%. ',
      );
    }

    if (quality != null && quality.isAvailable) {
      buffer.write(
        'Sleep quality (${quality.score!.round()}/100) is scored from stage '
        'composition and efficiency and carries more weight than duration, so '
        'two nights of equal length can score differently. ',
      );
      buffer.write(
        'The duration credit is capped by quality, which keeps a long shallow '
        'night from reading as restorative. ',
      );
    }

    if (nightHeartRate != null && nightHeartRate.hasBaseline) {
      buffer.write(
        'Overnight heart rate is compared only with your own nightly baseline, '
        'never with an absolute ideal value. ',
      );
    }

    buffer.write(
      'This heuristic model does not infer or require HRV and works with any compatible Health Connect source.',
    );

    return buffer.toString();
  }
}
