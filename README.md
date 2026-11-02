# PULSE Fitness

PULSE is a Flutter app that turns Android Health Connect data into simple
recovery, sleep, and training-load insights. It is designed to work with
affordable fitness trackers when their companion app writes compatible records
to Health Connect.

PULSE is an experimental wellness app, not a medical device. Its scores are
heuristic estimates and are not intended for diagnosis or treatment.

## Features

- Recovery score using sleep, resting heart rate, recent strain, and check-ins
- Sleep duration and available sleep-stage analysis
- Duplicate and overlapping sleep-record handling
- Training-load and heart-rate-zone views
- Health Connect sync for steps, heart rate, resting heart rate, active
  calories, sleep, and workouts
- Local SQLite storage
- Demo mode with synthetic data

Tracker compatibility depends on the records provided by the tracker’s
companion app through Health Connect. PULSE has not been tested with every
tracker or companion app.

## Requirements

- Flutter SDK compatible with this project
- Android SDK
- Android Health Connect on an Android device for real tracker data
- A JDK compatible with the configured Android toolchain

## Setup

```bash
flutter pub get
flutter run
```

For development checks:

```bash
dart format lib test
flutter analyze
flutter test
```

On first use, grant PULSE access to the Health Connect data types you want to
sync. Without Health Connect data, use the app's demo mode or enter supported
manual information.

## Downloading the APK

Download the latest Android APK from the **Releases** section of the
[PULSE-Fitness GitHub repository](https://github.com/avishekpandit14/PULSE-Fitness)
when a release is available. APK files are release artifacts and are not kept
in the source repository.

## Release signing

Release signing credentials must remain outside the repository. The Android
build configuration expects these environment variables:

```text
PULSE_KEYSTORE_PATH
PULSE_KEYSTORE_PASSWORD
PULSE_KEY_ALIAS
PULSE_KEY_PASSWORD
```

Never commit real credentials, keystores, or passwords.

## License

PULSE is proposed for release under the MIT License. See [LICENSE](LICENSE).
