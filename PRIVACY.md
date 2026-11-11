# PULSE Privacy Notice

_Last updated: 2026-11-02_

## Scope

PULSE is a local-first wellness application. It is not a medical device and does not provide medical advice.

## Data read from Health Connect

With user authorization, PULSE may read:

- Steps
- Heart rate
- Resting heart rate
- Active calories
- Sleep sessions and available sleep stages
- Exercise and workout sessions

The exact data available depends on the connected tracker and its companion application. PULSE does not claim that every tracker supports every metric.

## How data is used

Health Connect data is used on the device to display summaries, calculate heuristic recovery and training-load estimates, populate charts, and support local history.

Missing records are treated as unavailable. PULSE does not intentionally convert missing health signals into measured zero values or fabricate sleep stages.

## Local storage

PULSE may store user profile settings, check-ins, manual workouts, synced workout summaries, resting-heart-rate history, daily recovery and strain summaries, and data-quality metadata in local SQLite storage.

The local-data reset feature removes application-owned local records. It does not necessarily remove records already stored by Health Connect or the tracker companion application.

## Data sharing

PULSE does not require a PULSE account and does not operate an application-owned cloud backend for the local app experience. PULSE does not intentionally sell health data or use an advertising SDK.

Users should separately review the privacy policies of their tracker manufacturer, companion application, Android, Health Connect, device manufacturer, and any enabled backup or diagnostic service.

## Permissions

PULSE requests Health Connect permissions needed by its implemented foreground synchronization flow. Users can grant or revoke access through Android Health Connect settings.

## Security limitations

Local storage and platform behavior may be affected by device backups, operating-system diagnostics, rooted or compromised devices, debug builds, screenshots, exports, or other applications with device access.

## Data retention

Application-owned local records remain until the user resets or uninstalls the application, subject to Android device and backup behavior. Health Connect records are controlled separately through Health Connect and the source application.

## Contact

Before publication, replace this section with the maintainer's approved privacy or security contact channel. Do not publish a personal email address without explicit maintainer approval.
