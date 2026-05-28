# TASKS

## Active
- Manual smoke on macOS: activate cleaning, verify overlay countdown + pin, exit via menu / Ctrl+Shift+Escape / timeout, confirm re-activation works.
- Confirm Input Monitoring and Accessibility permissions in System Settings when testing event tap.

## Next Immediate Steps
1. Run the app from Xcode or `open` on the built `CleanKeys.app` and walk through the manual smoke checklist above.
2. Install or verify the watchdog launch agent if production deployment needs it (`scripts/install-watchdog.sh`).

## Completed
- Added persistent project-memory docs in `/docs`.
- Fixed fail-safe countdown edge-case behavior for zero/negative timeout and inactive extension calls.
- Fixed Xcode 26 API drift (`EventTapService`, `PermissionManager`).
- Fixed stuck `.exiting` state; overlay countdown and pin wiring.
- Added shared `CleanKeys` Xcode scheme with test action; all unit tests passing via `xcodebuild test`.

## Blockers
- None for build/test automation on macOS with Xcode installed.
