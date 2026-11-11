# PULSE

PULSE is a local-first Flutter application for recovery, sleep, and training-load insights using Android Health Connect data.

It is designed for people using affordable fitness trackers whose companion apps can write standard records to Health Connect. PULSE does not require Whoop, a specific watch brand, an account, or an application-owned cloud backend.

> PULSE is an experimental wellness application, not a medical device. Its scores are heuristic estimates and must not be used for diagnosis or treatment decisions.

## Features

- Sleep duration and sleep-stage processing
- Duplicate and overlapping sleep-record handling
- Partial and unavailable sleep-data states without fabricated values
- Recovery scoring using sleep, resting heart rate, recent strain, and optional check-ins
- Training-load estimation using workouts, heart-rate zones, steps, and active calories
- Android Health Connect integration
- Local SQLite persistence
- Demo mode with clearly labeled synthetic data
- No application-owned cloud backend or advertising SDK

## Data flow

```text
Fitness tracker
      ↓
Tracker companion app
      ↓
Android Health Connect
      ↓
PULSE local processing
      ↓
On-device recovery and strain views
```

Compatibility depends on whether the companion app writes the required Health Connect records. PULSE has not been validated against every tracker or companion application.

## Supported Health Connect data

PULSE currently reads:

- Steps
- Heart rate
- Resting heart rate
- Active calories
- Sleep sessions and available sleep stages
- Exercise and workout sessions

A tracker may provide only some of these signals. Missing data is excluded from calculations rather than silently treated as zero.

## Sleep data behavior

PULSE selects a recent sleep session, clips records to that session, removes duplicate and overlapping intervals, and calculates sleep from validated non-overlapping asleep or stage intervals.

When stage coverage is incomplete:

- measured intervals are reported separately from unknown time;
- unknown gaps are excluded from total sleep;
- missing stage values remain unavailable;
- the UI labels partial data.

## Recovery and strain

Recovery and strain are deterministic heuristics, not clinical measurements. Available recovery signals are weighted and missing signals are excluded with weight re-normalization.

Strain uses workout duration and heart-rate zones when available, average heart rate when zone data is unavailable, perceived exertion for manual workouts, and steps or active calories as background movement context.

Active calories are kept separate from basal calories. PULSE does not present an unvalidated fixed basal estimate as measured data.

## Privacy

Health Connect data is processed locally by the application and may be stored in local SQLite for the app experience. See [PRIVACY.md](PRIVACY.md) for the current data-handling explanation.

## Development

Requirements:

- Flutter SDK compatible with the project
- Android SDK and Health Connect for device testing
- JDK compatible with the configured Android toolchain

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

Hardware compatibility must be tested with the specific tracker and companion app before making a compatibility claim.

## Release signing

Release signing credentials must remain outside the repository. The Android Gradle configuration expects:

```text
PULSE_KEYSTORE_PATH
PULSE_KEYSTORE_PASSWORD
PULSE_KEY_ALIAS
PULSE_KEY_PASSWORD
```

Never place real values in source files, `.env` files, issues, or pull requests.

## Limitations

- Tracker and companion-app support is not universal.
- Companion-app synchronization may be delayed or incomplete.
- Some trackers provide no resting-heart-rate record.
- Sleep-stage coverage varies by source.
- Recovery and strain scores are heuristic estimates.
- PULSE is not a medical device.

## License

PULSE is proposed for release under the MIT License. See [LICENSE](LICENSE).
