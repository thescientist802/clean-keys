#!/bin/bash
# Install CleanKeys watchdog agent

WATCHDOG_PLIST_PATH="${HOME}/Library/LaunchAgents/com.scientist.CleanKeys.watchdog.plist"
PLIST_SOURCE="$(dirname "$0")/../CleanKeysWatchdog/com.scientist.CleanKeys.watchdog.plist"

cp "$PLIST_SOURCE" "$WATCHDOG_PLIST_PATH"
chmod 644 "$WATCHDOG_PLIST_PATH"
launchctl load "$WATCHDOG_PLIST_PATH"

echo "CleanKeys watchdog installed at $WATCHDOG_PLIST_PATH"