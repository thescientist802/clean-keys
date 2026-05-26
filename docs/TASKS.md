# TASKS

## Active
- Validate bug fixes on macOS with `xcodebuild` (Linux environment cannot run macOS targets).

## Next Immediate Steps
1. Run full macOS build.
2. Run macOS tests.
3. Verify fail-safe timeout edge cases manually in app.

## Completed
- Added persistent project-memory docs in `/docs`.
- Fixed fail-safe countdown edge-case behavior for zero/negative timeout and inactive extension calls.

## Blockers
- Current environment lacks `xcodebuild` and macOS frameworks.
