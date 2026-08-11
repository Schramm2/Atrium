#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Notive"
BUNDLE_ID="com.ubundi.meet"
MIN_SYSTEM_VERSION="14.0"
SPARKLE_PUBLIC_KEY="zNZF6Pmy9ZXc1vZOVRvmL5RBZ8BieC0mHYaele1HAvo="
SPARKLE_FEED_URL="https://github.com/Schramm2/notive/releases/latest/download/appcast.xml"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_DIR="$ROOT_DIR/macos"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_FRAMEWORKS="$APP_CONTENTS/Frameworks"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
VERSION="$(plutil -extract version raw "$SWIFT_DIR/version.json")"
ARCHIVE_PATH="$DIST_DIR/$APP_NAME-$VERSION.zip"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION-arm64.dmg"
CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/notive-swift-module-cache"
export CLANG_MODULE_CACHE_PATH

usage() {
  echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--package]" >&2
}

case "$MODE" in
  run|--debug|debug|--logs|logs|--telemetry|telemetry|--verify|verify|--package|package)
    ;;
  *)
    usage
    exit 2
    ;;
esac

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --package-path "$SWIFT_DIR" -c release
BUILD_DIR="$(swift build --package-path "$SWIFT_DIR" -c release --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$APP_FRAMEWORKS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp -R "$BUILD_DIR/Sparkle.framework" "$APP_FRAMEWORKS/Sparkle.framework"

cp "$ROOT_DIR/frontend/src-tauri/icons/icon.icns" "$APP_RESOURCES/Notive.icns"
cp "$ROOT_DIR/frontend/public/brand/notive-ubundi-icon.png" "$APP_RESOURCES/notive-ubundi-icon.png"
cp "$ROOT_DIR/frontend/public/brand/notive-first-motive-icon.png" "$APP_RESOURCES/notive-first-motive-icon.png"
cp "$SWIFT_DIR/BrandAssets/ubundi-wordmark.png" "$APP_RESOURCES/ubundi-wordmark.png"
cp "$SWIFT_DIR/BrandAssets/ubundi-mark.png" "$APP_RESOURCES/ubundi-mark.png"
cp "$SWIFT_DIR/BrandAssets/first-motive-mark.png" "$APP_RESOURCES/first-motive-mark.png"
cp "$SWIFT_DIR/BrandAssets/first-motive-wordmark.png" "$APP_RESOURCES/first-motive-wordmark.png"
cp "$SWIFT_DIR/BrandAssets/first-motive-atmosphere.png" "$APP_RESOURCES/first-motive-atmosphere.png"
cp "$ROOT_DIR/LICENSE.md" "$APP_RESOURCES/LICENSE.md"
cp "$ROOT_DIR/NOTICE.md" "$APP_RESOURCES/NOTICE.md"
cp "$SWIFT_DIR/.build/checkouts/Sparkle/LICENSE" "$APP_RESOURCES/Sparkle-LICENSE.txt"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>Notive</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>Notive records meeting and dictation audio that you start.</string>
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>Notive transcribes meeting and dictation audio on this Mac.</string>
  <key>NSScreenCaptureUsageDescription</key>
  <string>Notive captures system audio only while you record a meeting.</string>
  <key>SUFeedURL</key>
  <string>$SPARKLE_FEED_URL</string>
  <key>SUPublicEDKey</key>
  <string>$SPARKLE_PUBLIC_KEY</string>
  <key>SUEnableAutomaticChecks</key>
  <true/>
  <key>SUAutomaticallyUpdate</key>
  <false/>
  <key>SUVerifyUpdateBeforeExtraction</key>
  <true/>
  <key>SURequireSignedFeed</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/codesign --force --deep --sign - "$APP_FRAMEWORKS/Sparkle.framework"
/usr/bin/codesign --force --sign - "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    /usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
    open_app
    for _ in {1..100}; do
      if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
        echo "$APP_NAME is running from $APP_BUNDLE."
        exit 0
      fi
      sleep 0.1
    done
    echo "$APP_NAME did not start within 10 seconds." >&2
    exit 1
    ;;
  --package|package)
    package_temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/notive-package.XXXXXX")"
    trap 'rm -rf "$package_temp_dir"' EXIT
    rm -f "$ARCHIVE_PATH" "$DMG_PATH"
    /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ARCHIVE_PATH"
    /usr/bin/ditto "$APP_BUNDLE" "$package_temp_dir/$APP_NAME.app"
    ln -s /Applications "$package_temp_dir/Applications"
    /usr/bin/hdiutil create \
      -volname "$APP_NAME" \
      -srcfolder "$package_temp_dir" \
      -ov \
      -format UDZO \
      "$DMG_PATH" >/dev/null
    test -s "$ARCHIVE_PATH"
    test -s "$DMG_PATH"
    rm -rf "$package_temp_dir"
    trap - EXIT
    echo "Created $ARCHIVE_PATH and $DMG_PATH."
    ;;
esac
