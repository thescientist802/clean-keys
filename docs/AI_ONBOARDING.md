# AI_ONBOARDING

## Project
CleanKeys is a macOS menu-bar utility that enters a "cleaning" mode, blocks keyboard input, and supports a fail-safe key pattern to exit.

## Current Architecture
- `CleanKeys/App`: app entry + lifecycle.
- `CleanKeys/Models`: app state and settings.
- `CleanKeys/Services`: state machine, event tap, fail-safe countdown, permissions, observers.
- `CleanKeys/Views` + `ViewModels`: menu-bar UI and overlays.
- `CleanKeysWatchdog`: watchdog launch agent.

## Run / Build
- Primary build system: Xcode project `CleanKeys.xcodeproj`.
- Build command (macOS/Xcode required): `xcodebuild -project CleanKeys.xcodeproj -scheme CleanKeys build`.
- Tests (macOS/Xcode required): `xcodebuild -project CleanKeys.xcodeproj -scheme CleanKeys -destination 'platform=macOS' test`.

## Key Constraints
- Uses macOS-only frameworks (`AppKit`, `CoreGraphics`, `Carbon`), so Linux cannot build/test app targets.
- Event tap and accessibility/input monitoring permissions are required on macOS.

## Tech Stack
- Swift
- SwiftUI/AppKit
- Xcode project (not SwiftPM)
