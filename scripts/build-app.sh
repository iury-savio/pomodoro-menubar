#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Pomodoro.app"
CONTENTS="$APP/Contents"

cd "$ROOT"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
swiftc -O -target "$(uname -m)-apple-macosx14.0" \
    -framework SwiftUI -framework AppKit -framework UserNotifications \
    "$ROOT"/Sources/PomodoroMenuBar/*.swift \
    -o "$CONTENTS/MacOS/PomodoroMenuBar"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"

echo "Built $APP"
