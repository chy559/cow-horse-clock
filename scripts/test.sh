#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
cd "$PROJECT_DIR"

SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ ! -d "$SDK_PATH" ]]; then
  SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
fi

TEST_BINARY="$PROJECT_DIR/.build/cow-horse-clock-tests"
mkdir -p "$PROJECT_DIR/.build"

swiftc \
  -sdk "$SDK_PATH" \
  -target arm64-apple-macosx14.0 \
  -module-cache-path "$PROJECT_DIR/.build/test-module-cache" \
  -parse-as-library \
  "$PROJECT_DIR/Sources/CowHorseClock/Domain/WorkSettings.swift" \
  "$PROJECT_DIR/Sources/CowHorseClock/Domain/EarningsSnapshot.swift" \
  "$PROJECT_DIR/Sources/CowHorseClock/Domain/EarningsEngine.swift" \
  "$PROJECT_DIR/Sources/CowHorseClock/Persistence/Models.swift" \
  "$PROJECT_DIR/Sources/CowHorseClock/Persistence/SettingsStore.swift" \
  "$PROJECT_DIR/Sources/CowHorseClock/Persistence/LedgerStore.swift" \
  "$PROJECT_DIR/Sources/CowHorseClock/Services/LaunchAtLoginService.swift" \
  "$PROJECT_DIR/Sources/CowHorseClock/AppModel.swift" \
  "$PROJECT_DIR/Sources/CowHorseClock/Shared/MoneyFormatter.swift" \
  "$PROJECT_DIR/Sources/CowHorseClock/Shared/PunchCardTheme.swift" \
  "$PROJECT_DIR/Tests/CowHorseClockTests/TestSupport.swift" \
  "$PROJECT_DIR/Tests/CowHorseClockTests/WorkSettingsTests.swift" \
  "$PROJECT_DIR/Tests/CowHorseClockTests/EarningsEngineTests.swift" \
  "$PROJECT_DIR/Tests/CowHorseClockTests/LedgerStoreTests.swift" \
  "$PROJECT_DIR/Tests/CowHorseClockTests/AppModelTests.swift" \
  "$PROJECT_DIR/Tests/CowHorseClockTests/MoneyFormatterTests.swift" \
  "$PROJECT_DIR/Tests/CowHorseClockTests/HoverLiftStyleTests.swift" \
  "$PROJECT_DIR/Tests/CowHorseClockTests/DashboardSourceTests.swift" \
  "$PROJECT_DIR/Tests/CowHorseClockTests/SecondaryViewSourceTests.swift" \
  "$PROJECT_DIR/Tests/CowHorseClockTests/AllTests.swift" \
  -o "$TEST_BINARY"

"$TEST_BINARY"
bash "$PROJECT_DIR/scripts/test-app-icon.sh"
