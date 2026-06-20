#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="SoundSight"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_DIR="$PROJECT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$PROJECT_DIR"

echo "Building SoundSight..."
swift build -c release

echo "Creating application bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>SoundSight</string>

    <key>CFBundleDisplayName</key>
    <string>SoundSight</string>

    <key>CFBundleIdentifier</key>
    <string>music.xiaopinpin.soundsight</string>

    <key>CFBundleExecutable</key>
    <string>SoundSight</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>

    <key>CFBundleVersion</key>
    <string>1</string>

    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>

    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

chmod +x "$MACOS_DIR/$APP_NAME"
codesign --force --deep --sign - "$APP_DIR"

echo "SoundSight.app created at:"
echo "$APP_DIR"
