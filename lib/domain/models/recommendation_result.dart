enum TrainingSuggestion {
  heavy,
  moderate,
  light,
  rest;

  String get displayName {
    switch (this) {
      case TrainingSuggestion.heavy:
        return 'Heavy Training';
      case TrainingSuggestion.moderate:
        return 'Moderate Training';
      case TrainingSuggestion.light:
        return 'Light / Active Recovery';
      case TrainingSuggestion.rest:
        return 'Rest & Regeneration';
    }
  }
}

class RecommendationResult {
  final TrainingSuggestion suggestion;
  final String title;
  final String description;
  final List<String> mainFactors;
  final String safetyDisclaimer;

  const RecommendationResult({
    required this.suggestion,
    required this.title,
    required this.description,
    required this.mainFactors,
    this.safetyDisclaimer =
        'Notice: Recommendations are heuristic guidance generated from lifestyle data. '
        'They do not guarantee injury prevention or optimal physiological outcomes. '
        'Always listen to your body, warm up adequately, and consult a medical practitioner if needed.',
  });
}
