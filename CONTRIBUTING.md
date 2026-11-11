# Contributing to PULSE

Thank you for helping improve PULSE.

## Before contributing

Please read `README.md`, `PRIVACY.md`, and `CODE_OF_CONDUCT.md`.

Do not include real Health Connect exports, personal health records, database files, keystores, passwords, API keys, or other private information in issues or pull requests.

## Development checks

Before submitting a change, run:

```bash
dart format lib test
flutter analyze
flutter test
```

Keep changes focused. Avoid unrelated dependency upgrades or generated-file changes.

## Health Connect changes

When changing Health Connect integration:

- Document the record types read.
- Preserve missing-data semantics.
- Do not convert absent data into zero.
- Do not include real user data in fixtures.
- Add synthetic tests where possible.
- Explain permission changes and compatibility impact.

## Pull requests

Pull requests should explain the problem, intended behavior, tests, and any device-only behavior that was not tested locally. Do not claim compatibility with a tracker that was not tested.

## Privacy and security

Report suspected credential exposure privately to the maintainers. Never commit keystores, signing passwords, real `.env` files, local databases, health-data exports, or device-specific configuration.
