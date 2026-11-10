import '../models/recommendation_result.dart';
import '../models/recovery_result.dart';
import '../models/strain_result.dart';

/// Deterministic training recommendation generator.
/// Evaluates recovery readiness against accumulated acute training strain.
class RecommendationEngine {
  static RecommendationResult generate({
    required RecoveryResult recovery,
    required StrainResult strain,
  }) {
    final List<String> factors = [];

    // If recovery data is not enough
    if (!recovery.hasEnoughData) {
      return const RecommendationResult(
        suggestion: TrainingSuggestion.moderate,
        title: 'Moderate / Baseline Training',
        description:
            'Insufficient recovery telemetry available today. Train according to your intuitive perceived readiness, maintaining moderate intensity.',
        mainFactors: [
          'Recovery score not yet established (missing sleep or check-in)',
          'Defaulting to conservative baseline recommendations',
        ],
      );
    }

    final score = recovery.score!;
    final acuteLoad = strain.acuteLoad;
    final rhrDelta = (recovery.todayRhr != null && recovery.baselineRhr != null)
        ? (recovery.todayRhr! - recovery.baselineRhr!)
        : null;

    // Evaluate factors
    if (recovery.sleepMinutes != null) {
      final sleepHrs = (recovery.sleepMinutes! / 60.0).toStringAsFixed(1);
      factors.add('Sleep duration logged at $sleepHrs hrs');
    }

    final quality = recovery.sleepQuality;
    if (quality != null && quality.isAvailable) {
      final percent = quality.score!.round();
      final stageNote = quality.hasStageData
          ? ' with stage data'
          : ' from duration and efficiency only';
      factors.add('Sleep quality scored $percent/100$stageNote');
    }

    final nightHr = recovery.nightHeartRate;
    if (nightHr != null && nightHr.hasBaseline) {
      final delta = nightHr.baselineDeltaBpm!.round();
      final direction = delta >= 0 ? '+' : '';
      factors.add(
        'Nighttime HR ${nightHr.averageBpm!.round()} bpm '
        '($direction$delta bpm vs your nightly baseline)',
      );
    }

    if (rhrDelta != null) {
      if (rhrDelta <= 0) {
        factors.add(
          'Resting HR nominal or below baseline (${rhrDelta.round()} bpm)',
        );
      } else {
        factors.add(
          'Resting HR elevated by +${rhrDelta.round()} bpm above baseline',
        );
      }
    }

    if (acuteLoad > 14.0) {
      factors.add(
        'High 7-day cumulative strain (${acuteLoad.toStringAsFixed(1)})',
      );
    } else if (acuteLoad < 8.0) {
      factors.add('Low acute training load (${acuteLoad.toStringAsFixed(1)})');
    }

    if (recovery.checkIn != null) {
      factors.add(
        'Check-in: Energy ${recovery.checkIn!.energy}/10, Soreness ${recovery.checkIn!.muscleSoreness}/10',
      );
    }

    // Recommendation logic
    if (score >= 67) {
      // Ready state
      if (acuteLoad < 15.0) {
        return RecommendationResult(
          suggestion: TrainingSuggestion.heavy,
          title: 'Prime Readiness: High Intensity / Overload',
          description:
              'Your physiological markers indicate excellent recovery. Ideal for maximum effort, interval training, heavy resistance, or setting personal bests.',
          mainFactors: factors,
        );
      } else {
        return RecommendationResult(
          suggestion: TrainingSuggestion.moderate,
          title: 'High Readiness with Accumulated Fatigue',
          description:
              'Recovery is strong, but your 7-day training strain is elevated. A solid moderate session will stimulate fitness without triggering excessive fatigue.',
          mainFactors: factors,
        );
      }
    } else if (score >= 34) {
      // Moderate state
      if (rhrDelta != null && rhrDelta > 4) {
        return RecommendationResult(
          suggestion: TrainingSuggestion.light,
          title: 'Light Aerobic / Active Recovery',
          description:
              'Elevated resting heart rate indicates partial recovery. Prioritize Zone 2 aerobic base building, light mobility, or technical drills.',
          mainFactors: factors,
        );
      }
      return RecommendationResult(
        suggestion: TrainingSuggestion.moderate,
        title: 'Aerobic Maintenance & Moderate Training',
        description:
            'Body is in a stable maintenance state. Safe for standard workouts, steady-state cardio, or moderate sub-maximal lifting.',
        mainFactors: factors,
      );
    } else {
      // Rest recommended state
      return RecommendationResult(
        suggestion: TrainingSuggestion.rest,
        title: 'Rest & Deep Regeneration',
        description:
            'Telemetry indicates significant physiological fatigue. High-intensity training today is counter-productive. Prioritize sleep, hydration, and gentle walking.',
        mainFactors: factors,
      );
    }
  }
}
