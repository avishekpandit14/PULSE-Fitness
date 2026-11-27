import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_fitness/domain/algorithms/sleep_quality_analyzer.dart';
import 'package:pulse_fitness/domain/models/recovery_result.dart';
import 'package:pulse_fitness/domain/models/sleep_session_model.dart';
import 'package:pulse_fitness/domain/models/workout_model.dart';
import 'package:pulse_fitness/presentation/screens/dashboard/widgets/monitor_cards.dart';
import 'package:pulse_fitness/presentation/screens/dashboard/widgets/sleep_summary_card.dart';
import 'package:pulse_fitness/presentation/screens/dashboard/widgets/today_activities_card.dart';

/// The dashboard cards are row-heavy, so a long label or a wide font can make a
/// row demand more width than the screen has. Each card is laid out at the
/// narrowest supported width and must render without overflowing.
void main() {
  const double narrowWidth = 320;
  const double narrowHeight = 900;

  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    tester.view.physicalSize = const Size(narrowWidth, narrowHeight);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: card),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  SleepSessionModel night({
    int totalMinutes = 396,
    SleepDataQuality quality = SleepDataQuality.measured,
    int unknownMinutes = 0,
  }) => SleepSessionModel(
    id: 'night-1',
    dateKey: '2026-11-17',
    startTime: DateTime(2026, 11, 16, 23, 10),
    endTime: DateTime(2026, 11, 17, 5, 50),
    totalMinutes: totalMinutes,
    deepMinutes: 78,
    lightMinutes: 210,
    remMinutes: 96,
    awakeMinutes: 12,
    consistencyScore: 88,
    dataQuality: quality,
    unknownMinutes: unknownMinutes,
  );

  testWidgets('sleep card fits without a session', (tester) async {
    await pumpCard(
      tester,
      SleepSummaryCard(sleepSession: null, targetHours: 8, onTap: () {}),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Sleep Record Unavailable'), findsOneWidget);
  });

  testWidgets('sleep card fits when the night has partial data', (
    tester,
  ) async {
    await pumpCard(
      tester,
      SleepSummaryCard(
        sleepSession: night(
          quality: SleepDataQuality.partial,
          unknownMinutes: 45,
        ),
        targetHours: 8,
        onTap: () {},
        naps: [
          SleepNap(
            startTime: DateTime(2026, 11, 17, 14),
            endTime: DateTime(2026, 11, 17, 14, 40),
            minutes: 40,
          ),
        ],
        napMinutes: 40,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('45 minutes of the sleep window'),
      findsOneWidget,
    );
  });

  testWidgets('sleep card fits for a fully measured night', (tester) async {
    await pumpCard(
      tester,
      SleepSummaryCard(sleepSession: night(), targetHours: 8, onTap: () {}),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Deep'), findsOneWidget);
  });

  testWidgets('monitor cards fit in both the data and no-data states', (
    tester,
  ) async {
    await pumpCard(
      tester,
      Column(
        children: [
          SleepMonitorCard(
            quality: const SleepQualityResult(
              score: 95,
              confidence: ConfidenceLevel.high,
              dataQuality: SleepDataQuality.measured,
              efficiency: 0.94,
              deepRatio: 0.19,
              remRatio: 0.26,
            ),
            napMinutes: 0,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          SleepMonitorCard(quality: null, napMinutes: 0, onTap: () {}),
          const SizedBox(height: 12),
          HeartMonitorCard(restingHeartRate: 62, baselineRhr: 56, onTap: () {}),
          const SizedBox(height: 12),
          HeartMonitorCard(
            restingHeartRate: null,
            baselineRhr: null,
            onTap: () {},
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('NO STAGE DATA'), findsOneWidget);
    expect(find.text('NO DATA'), findsOneWidget);
  });

  testWidgets('activities card fits when empty and when it lists several', (
    tester,
  ) async {
    await pumpCard(
      tester,
      TodayActivitiesCard(workouts: const [], onTap: () {}),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('NONE YET'), findsOneWidget);

    final workouts = List.generate(
      5,
      (i) => WorkoutModel(
        id: 'w$i',
        title: 'Evening strength session number ${i + 1}',
        type: WorkoutType.strength,
        startTime: DateTime(2026, 11, 17, 18, i * 10),
        durationMinutes: 55,
        avgHeartRate: 132,
        caloriesBurned: 412,
      ),
    );

    await pumpCard(
      tester,
      TodayActivitiesCard(workouts: workouts, onTap: () {}),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('5 SESSIONS'), findsOneWidget);
    expect(find.text('+2 more today'), findsOneWidget);
  });
}
