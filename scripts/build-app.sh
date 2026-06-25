#!/bin/bash
#
# Builds DockAnchor and assembles a runnable .app bundle in dist/.
#
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="DockAnchor"
CONFIG="release"

# --disable-sandbox is needed when building inside an already-sandboxed
# environment (SwiftPM otherwise tries to nest its own sandbox-exec and fails).
BUILD_FLAGS="-c $CONFIG --disable-sandbox"

echo "==> Building ($CONFIG)..."
swift build $BUILD_FLAGS

BIN_DIR="$(swift build $BUILD_FLAGS --show-bin-path)"
BIN_PATH="$BIN_DIR/$APP_NAME"

if [[ ! -f "$BIN_PATH" ]]; then
	echo "error: built binary not found at $BIN_PATH" >&2
	exit 1
fi

APP_DIR="dist/$APP_NAME.app"
echo "==> Assembling $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$APP_DIR/Contents/Info.plist"

if [[ ! -f Resources/AppIcon.icns ]]; then
	echo "==> AppIcon.icns missing, generating..."
	bash scripts/generate-icon.sh
fi
cp Resources/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"

SIGN_IDENTITY="DockAnchor Self-Signed"
if security find-identity -p codesigning 2>/dev/null | grep -q "$SIGN_IDENTITY"; then
	echo "==> Code signing with '$SIGN_IDENTITY' (stable identity)..."
	codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR"
else
	echo "==> '$SIGN_IDENTITY' not found — ad-hoc signing."
	echo "    Run scripts/setup-signing.sh once for a stable signature that"
	echo "    preserves your Accessibility permission across rebuilds."
	codesign --force --deep --sign - "$APP_DIR"
fi

echo "==> Done: $APP_DIR"
echo "    Run with: open \"$APP_DIR\""
echo "    For Launch-at-Login to work reliably, move it to /Applications or ~/Applications."
