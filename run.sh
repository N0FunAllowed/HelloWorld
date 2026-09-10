#!/usr/bin/env bash
# Builds TruckRoute and launches it on an iPhone simulator.
# Usage: ./run.sh ["iPhone 17 Pro"]
set -euo pipefail

cd "$(dirname "$0")"

PROJECT="TruckRoute.xcodeproj"
SCHEME="TruckRoute"
BUNDLE_ID="com.example.TruckRoute"
DERIVED_DATA="build"

if [ $# -gt 0 ]; then
    PATTERN="$1"
else
    PATTERN="iPhone"
fi

# simctl prints "    iPhone 17 Pro (UDID) (Shutdown)"; take the first match.
DEVICE_LINE=$(xcrun simctl list devices available \
    | grep -E "^[[:space:]]+${PATTERN}" \
    | head -n 1 || true)

if [ -z "$DEVICE_LINE" ]; then
    echo "No available simulator matching \"${PATTERN}\"." >&2
    echo "Installed simulators:" >&2
    xcrun simctl list devices available >&2
    echo >&2
    echo "In Xcode: Settings > Components, then install an iOS simulator runtime." >&2
    exit 1
fi

DEVICE_ID=$(echo "$DEVICE_LINE" | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')
DEVICE_NAME=$(echo "$DEVICE_LINE" | sed -E 's/^[[:space:]]*(.*) \([0-9A-Fa-f-]{36}\).*/\1/')
echo "==> Using simulator: ${DEVICE_NAME} (${DEVICE_ID})"

echo "==> Building"
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "id=${DEVICE_ID}" \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO

echo "==> Booting simulator"
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_ID" -b
open -a Simulator

APP_PATH="${DERIVED_DATA}/Build/Products/Debug-iphonesimulator/TruckRoute.app"
echo "==> Installing ${APP_PATH}"
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

echo "==> Launching"
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"
