# PULSE Fitness

PULSE is a Flutter app that turns Android Health Connect data into simple
recovery, sleep, and training-load insights. It is designed to work with
affordable fitness trackers when their companion app writes compatible records
to Health Connect.

PULSE is an experimental wellness app, not a medical device. Its scores are
heuristic estimates and are not intended for diagnosis or treatment.

## Features

- Recovery score with a transparent, per-factor breakdown
- Nighttime sleep scored separately from naps
- Sleep quality from efficiency plus available stage shares
- Nighttime heart-rate analysis (average, lowest, p95 highest, stability, trend)
- Duplicate and overlapping sleep-record handling
- Data-quality and confidence indicators instead of fabricated values
- Training-load and heart-rate-zone views
- Health Connect sync for steps, heart rate, resting heart rate, active
  calories, sleep, and workouts
- Local SQLite storage
- Demo mode with synthetic data

Tracker compatibility depends on the records provided by the tracker’s
companion app through Health Connect. PULSE has not been tested with every
tracker or companion app.

## Sleep analysis

PULSE treats a night and a nap as different things.

**Night classification.** A session belongs to the night when the majority of
its minutes fall inside the night band (18:00 → 12:00 next day). A session
spanning midnight is handled by that same majority rule, not by its start date.

**Primary vs. naps.** The primary sleep of the day is the longest *nighttime*
session; duration breaks ties. It is never chosen by "most recently recorded"
and a nap can never replace it or reduce its score. If no session qualifies as
nighttime, the longest session overall is used and the UI marks it as not
nighttime.

**Naps** are displayed separately with their start/end time and minutes. They
are informational only and are never added to nightly sleep or weighted into
recovery.

**Duplicates.** Sessions whose intervals overlap by 50% or more of the shorter
session are treated as the same sleep and kept once, so multi-source or
partially-merged records are not double counted.

**Quality.** Sleep quality is not duration alone. It combines sleep efficiency
(asleep time against time in bed, scored linearly from 75% up to 95%) with the
share of deep and REM sleep, each scored against a target (15% deep, 22% REM)
with no penalty for exceeding it. Weights are sleep efficiency 0.40, deep 0.30,
REM 0.30, and they are renormalized over the factors actually present:

- A night with full stage data is scored on all three.
- A tracker that reports only asleep/awake time yields an efficiency-only
  quality score flagged as low confidence.
- Missing stages are reported as unavailable, never counted as a zero score.

## Recovery scoring

Recovery is a deterministic heuristic, not a clinical measurement. Default
weights (sum 1.00):

| Factor | Weight |
| --- | --- |
| Sleep duration | 0.25 |
| Sleep quality | 0.20 |
| Nighttime heart rate | 0.18 |
| Recent training load | 0.15 |
| Energy check-in | 0.09 |
| Soreness check-in | 0.08 |
| Fatigue check-in | 0.05 |

Signals that are unavailable are removed and the remaining weights are
renormalized; a score is produced only when at least 35% of the weight is
covered, and confidence falls as coverage shrinks. The recovery details screen
lists every factor with its signed point contribution, computed as
`(component score − 50) × normalized weight`, so the factors add up to the
final score instead of hiding behind an opaque number.

**Nighttime heart rate without HRV.** The supported trackers provide no HRV, so
PULSE analyzes nighttime BPM directly: a nightly average over the sleep window,
plus lowest, p95 highest, stability (band of 8 bpm) and a trend against your own
nightly baseline. Samples deviating more than 35 bpm from the night median are
treated as movement artifacts and excluded, and a night needs at least 5 valid
samples to be reported. Nighttime heart rate is compared against a separate
nightly baseline (a minimum of 3 nights; resting-heart-rate history is used as a
fallback until then). Because nighttime heart rate and resting heart rate are
correlated, nighttime heart rate *replaces* resting heart rate in the recovery
score rather than counting twice.

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
manual information. Partial permissions are handled gracefully: the metrics you
did not grant simply show as unavailable, with a confidence indicator, instead
of reading as zero.

## Downloading the APK

Download the latest Android APK from the **Releases** section of the
[PULSE-Fitness GitHub repository](https://github.com/avishekpandit14/PULSE-Fitness)
when a release is available. APK files are release artifacts and are not kept
in the source repository.

To build an installable APK locally, `flutter build apk --debug` produces an
APK signed with the local debug key. A release APK requires the signing
variables below.

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

## Limitations

- No HRV: heart-rate analysis uses nighttime BPM only and makes no
  HRV-based claims.
- A nightly heart-rate baseline needs 3 nights before trend comparison is
  shown; resting heart rate is used as a fallback until then.
- Stage-less trackers produce an efficiency-only sleep quality with low
  confidence.
- Awake *episode counts* are unavailable from Health Connect; only awake
  minutes are reported.
- Naps that a tracker merges into one long sleep record cannot be separated.
- Nighttime heart-rate coverage is measured in 30-minute buckets, so short
  gaps are not individually flagged.
- Companion-app synchronization may be delayed or incomplete, and some
  trackers provide no resting-heart-rate record.
- Recovery and strain scores are heuristic estimates, not medical advice.

## License

PULSE is proposed for release under the MIT License. See [LICENSE](LICENSE).
