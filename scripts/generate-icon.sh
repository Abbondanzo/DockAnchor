#!/bin/bash
#
# Regenerates Resources/AppIcon.icns from scripts/generate-icon.swift.
#
set -euo pipefail

cd "$(dirname "$0")/.."

WORK="$(mktemp -d)"
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"

echo "==> Rendering icon PNGs..."
swift scripts/generate-icon.swift "$ICONSET"

echo "==> Building AppIcon.icns..."
mkdir -p Resources
iconutil -c icns -o Resources/AppIcon.icns "$ICONSET"

rm -rf "$WORK"
echo "==> Wrote Resources/AppIcon.icns"
