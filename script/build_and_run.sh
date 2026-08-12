#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Notive"
BUNDLE_ID="com.ubundi.meet"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_DIR="$ROOT_DIR/macos"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/.$APP_NAME.app"
LEGACY_APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
VERSION="${NOTIVE_BUILD_VERSION:-$(plutil -extract version raw "$SWIFT_DIR/version.json")}"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION-arm64.dmg"
STABLE_DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/notive-swift-module-cache"
export CLANG_MODULE_CACHE_PATH

unregister_development_bundle() {
  "$LSREGISTER" -u "$APP_BUNDLE" >/dev/null 2>&1 || true
  "$LSREGISTER" -u "$LEGACY_APP_BUNDLE" >/dev/null 2>&1 || true
}

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
unregister_development_bundle
rm -rf "$LEGACY_APP_BUNDLE"

swift build --package-path "$SWIFT_DIR" -c release
BUILD_DIR="$(swift build --package-path "$SWIFT_DIR" -c release --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
touch "$DIST_DIR/.metadata_never_index"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cp "$SWIFT_DIR/BrandAssets/Notive.icns" "$APP_RESOURCES/Notive.icns"
cp "$SWIFT_DIR/BrandAssets/notive-ubundi-icon.png" "$APP_RESOURCES/notive-ubundi-icon.png"
cp "$SWIFT_DIR/BrandAssets/notive-first-motive-icon.png" "$APP_RESOURCES/notive-first-motive-icon.png"
cp "$SWIFT_DIR/BrandAssets/ubundi-wordmark.png" "$APP_RESOURCES/ubundi-wordmark.png"
cp "$SWIFT_DIR/BrandAssets/ubundi-mark.png" "$APP_RESOURCES/ubundi-mark.png"
cp "$SWIFT_DIR/BrandAssets/first-motive-mark.png" "$APP_RESOURCES/first-motive-mark.png"
cp "$SWIFT_DIR/BrandAssets/first-motive-wordmark.png" "$APP_RESOURCES/first-motive-wordmark.png"
cp "$SWIFT_DIR/BrandAssets/first-motive-atmosphere.png" "$APP_RESOURCES/first-motive-atmosphere.png"
cp "$ROOT_DIR/LICENSE.md" "$APP_RESOURCES/LICENSE.md"
cp "$ROOT_DIR/NOTICE.md" "$APP_RESOURCES/NOTICE.md"

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
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/codesign --force --sign - "$APP_BUNDLE"
unregister_development_bundle

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
  unregister_development_bundle
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
    rm -f "$DMG_PATH" "$STABLE_DMG_PATH"
    /usr/bin/ditto "$APP_BUNDLE" "$package_temp_dir/$APP_NAME.app"
    ln -s /Applications "$package_temp_dir/Applications"
    /usr/bin/hdiutil create \
      -volname "$APP_NAME" \
      -srcfolder "$package_temp_dir" \
      -ov \
      -format UDZO \
      "$DMG_PATH" >/dev/null
    test -s "$DMG_PATH"
    cp "$DMG_PATH" "$STABLE_DMG_PATH"
    test -s "$STABLE_DMG_PATH"
    rm -rf "$package_temp_dir"
    trap - EXIT
    echo "Created $DMG_PATH and $STABLE_DMG_PATH."
    ;;
esac
