# KNOWN_ISSUES

- **macOS build/test unverified on Linux** — Status: `mitigated`. App targets require macOS/Xcode; CI or developers on Linux cannot run `xcodebuild` for app targets. Verified on macOS with Xcode 26.3 in this session.
- **Event tap and permissions** — Status: `open`. Global key suppression requires Accessibility and Input Monitoring permissions; must be validated manually per machine (`PermissionManager`, System Settings).
- **Watchdog force-terminate** — Status: `mitigated` (by design). `CleanKeysWatchdog` terminates the app if heartbeat is stale; intentional recovery path, not a code defect.
