#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
cd "$PROJECT_DIR"

SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ ! -d "$SDK_PATH" ]]; then
  SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
fi

export SDKROOT="$SDK_PATH"
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PROJECT_DIR/.build/swiftpm-module-cache"

swift build --disable-sandbox -c release

APP_DIR="$PROJECT_DIR/dist/CowHorseClock.app"
BIN_DIR="$APP_DIR/Contents/MacOS"
RESOURCE_DIR="$APP_DIR/Contents/Resources"
if [[ -d "$APP_DIR" ]]; then
  rm -rf "$APP_DIR"
fi
mkdir -p "$BIN_DIR" "$RESOURCE_DIR"
cp "$PROJECT_DIR/.build/release/CowHorseClock" "$BIN_DIR/CowHorseClock"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCE_DIR/AppIcon.icns"

PLIST_PATH="$APP_DIR/Contents/Info.plist"
plutil -create xml1 "$PLIST_PATH"
plutil -insert CFBundleName -string "牛马时钟" "$PLIST_PATH"
plutil -insert CFBundleDisplayName -string "牛马时钟" "$PLIST_PATH"
plutil -insert CFBundleIdentifier -string "com.local.CowHorseClock" "$PLIST_PATH"
plutil -insert CFBundleExecutable -string "CowHorseClock" "$PLIST_PATH"
plutil -insert CFBundlePackageType -string "APPL" "$PLIST_PATH"
plutil -insert CFBundleShortVersionString -string "1.0.0" "$PLIST_PATH"
plutil -insert CFBundleVersion -string "1" "$PLIST_PATH"
plutil -insert LSMinimumSystemVersion -string "14.0" "$PLIST_PATH"
plutil -insert LSUIElement -bool true "$PLIST_PATH"
plutil -insert CFBundleIconFile -string "AppIcon" "$PLIST_PATH"

codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
