#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
SOURCE_ICON="$PROJECT_DIR/Resources/AppIcon.png"
OUTPUT_ICON="$PROJECT_DIR/Resources/AppIcon.icns"

[[ -f "$SOURCE_ICON" ]] || {
  echo "Missing Resources/AppIcon.png"
  exit 1
}

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
ICONSET_DIR="$TEMP_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

make_icon() {
  local size="$1"
  local filename="$2"
  sips -z "$size" "$size" "$SOURCE_ICON" \
    --out "$ICONSET_DIR/$filename" >/dev/null
}

make_icon 16 icon_16x16.png
make_icon 32 icon_16x16@2x.png
make_icon 32 icon_32x32.png
make_icon 64 icon_32x32@2x.png
make_icon 128 icon_128x128.png
make_icon 256 icon_128x128@2x.png
make_icon 256 icon_256x256.png
make_icon 512 icon_256x256@2x.png
make_icon 512 icon_512x512.png
make_icon 1024 icon_512x512@2x.png

python3 "$SCRIPT_DIR/build-icns.py" "$ICONSET_DIR" "$OUTPUT_ICON"

VALIDATION_ICONSET="$TEMP_DIR/Validated.iconset"
iconutil -c iconset "$OUTPUT_ICON" -o "$VALIDATION_ICONSET"
echo "$OUTPUT_ICON"
