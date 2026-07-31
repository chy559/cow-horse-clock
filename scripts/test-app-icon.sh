#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
PNG="$PROJECT_DIR/Resources/AppIcon.png"
ICNS="$PROJECT_DIR/Resources/AppIcon.icns"

[[ -f "$PNG" ]] || {
  echo "Missing Resources/AppIcon.png"
  exit 1
}
[[ -f "$ICNS" ]] || {
  echo "Missing Resources/AppIcon.icns"
  exit 1
}

WIDTH="$(sips -g pixelWidth "$PNG" | awk '/pixelWidth/ {print $2}')"
HEIGHT="$(sips -g pixelHeight "$PNG" | awk '/pixelHeight/ {print $2}')"
[[ "$WIDTH" == "1024" ]] || {
  echo "AppIcon.png width must be 1024, got $WIDTH"
  exit 1
}
[[ "$HEIGHT" == "1024" ]] || {
  echo "AppIcon.png height must be 1024, got $HEIGHT"
  exit 1
}

grep -q 'CFBundleIconFile' "$PROJECT_DIR/scripts/build-app.sh"
grep -q 'Resources/AppIcon.icns' "$PROJECT_DIR/scripts/build-app.sh"

VALIDATION_DIR="$(mktemp -d)"
trap 'rm -rf "$VALIDATION_DIR"' EXIT
iconutil -c iconset "$ICNS" -o "$VALIDATION_DIR/AppIcon.iconset"
[[ -f "$VALIDATION_DIR/AppIcon.iconset/icon_16x16@2x.png" ]]
[[ -f "$VALIDATION_DIR/AppIcon.iconset/icon_512x512@2x.png" ]]

echo "PASS custom app icon assets and build integration"
