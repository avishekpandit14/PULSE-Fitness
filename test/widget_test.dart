import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_fitness/domain/models/recovery_result.dart';
import 'package:pulse_fitness/domain/models/strain_result.dart';
import 'package:pulse_fitness/presentation/screens/dashboard/widgets/circular_recovery_gauge.dart';
import 'package:pulse_fitness/presentation/screens/strain/widgets/circular_strain_gauge.dart';
import 'package:pulse_fitness/presentation/screens/strain/widgets/recommended_strain_card.dart';
import 'package:pulse_fitness/presentation/screens/strain/widgets/weekly_strain_history_card.dart';
import 'package:pulse_fitness/presentation/widgets/confidence_badge.dart';

void main() {
  testWidgets('ConfidenceBadge renders high confidence correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ConfidenceBadge(confidence: ConfidenceLevel.high),
      ),
    );

    expect(find.text('HIGH CONFIDENCE'), findsOneWidget);
  });

  testWidgets('CircularRecoveryGauge displays not enough data cleanly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CircularRecoveryGauge(recovery: null),
      ),
    );

    expect(find.text('RECOVERY'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('NOT ENOUGH DATA'), findsOneWidget);
  });

  testWidgets('CircularStrainGauge renders daily score and category badge', (
    WidgetTester tester,
  ) async {
    const testStrain = StrainResult(
      score: 14.8,
      category: StrainCategory.high,
      totalCalories: 2400,
      activeCalories: 800,
      steps: 11000,
      workoutCount: 1,
      hrZoneMinutes: [5, 10, 15, 20, 5],
      weeklyDailyLoads: [10.0, 12.0, 14.8],
      acuteLoad: 12.3,
      explanation: 'Optimal stimulus achieved.',
      hasHeartRateData: true,
      cardiovascularLoad: 11.2,
      movementStrain: 3.6,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CircularStrainGauge(strain: testStrain)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('14.8'), findsOneWidget);
    expect(find.text('HIGH STRAIN'), findsOneWidget);
    expect(find.text('DAILY STRAIN'), findsOneWidget);
  });

  testWidgets('RecommendedStrainCard displays target range and status', (
    WidgetTester tester,
  ) async {
    const testStrain = StrainResult(
      score: 15.2,
      category: StrainCategory.high,
      totalCalories: 2200,
      activeCalories: 750,
      steps: 10000,
      workoutCount: 1,
      hrZoneMinutes: [5, 10, 15, 15, 0],
      weeklyDailyLoads: [12.0, 15.2],
      acuteLoad: 13.6,
      explanation: 'Target zone active',
      hasHeartRateData: true,
      recommendedTarget: RecommendedStrainTarget(
        minTarget: 14.0,
        maxTarget: 18.0,
        label: 'Optimal Overload',
        explanation: 'Prime day for heavy cardiovascular volume.',
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecommendedStrainCard(strain: testStrain, recoveryScore: 82.0),
        ),
      ),
    );

    expect(find.text('14.0 – 18.0'), findsOneWidget);
    expect(find.text('IN TARGET ZONE'), findsOneWidget);
    expect(find.text('82% Recovery'), findsOneWidget);
    expect(find.text('Optimal Overload'), findsOneWidget);
  });

  testWidgets('WeeklyStrainHistoryCard displays average and chart axis', (
    WidgetTester tester,
  ) async {
    const testStrain = StrainResult(
      score: 12.0,
      category: StrainCategory.moderate,
      totalCalories: 2000,
      activeCalories: 500,
      steps: 8000,
      workoutCount: 1,
      hrZoneMinutes: [5, 10, 15, 5, 0],
      weeklyDailyLoads: [10.0, 11.0, 12.0, 14.0, 8.0, 13.0, 12.0],
      acuteLoad: 11.4,
      explanation: 'Moderate loading',
      hasHeartRateData: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WeeklyStrainHistoryCard(strain: testStrain)),
      ),
    );

    expect(find.text('7-DAY STRAIN HISTORY'), findsOneWidget);
    expect(find.text('AVG: 11.4'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
  });
}
