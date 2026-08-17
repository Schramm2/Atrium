#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Atrium"
BUNDLE_ID="com.ubundi.meet"
MIN_SYSTEM_VERSION="14.0"
LOCAL_SIGNING_IDENTITY="Atrium Local Signing"

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
VERSION="${ATRIUM_BUILD_VERSION:-$(plutil -extract version raw "$SWIFT_DIR/version.json")}"
VOLUME_NAME="$APP_NAME $VERSION"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION-arm64.dmg"
STABLE_DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
LEGACY_DMG_PATH="$DIST_DIR/Notive-$VERSION-arm64.dmg"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/atrium-swift-module-cache"
export CLANG_MODULE_CACHE_PATH

unregister_development_bundle() {
  "$LSREGISTER" -u "$APP_BUNDLE" >/dev/null 2>&1 || true
  "$LSREGISTER" -u "$LEGACY_APP_BUNDLE" >/dev/null 2>&1 || true
}

usage() {
  echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--package]" >&2
}

# Lays out the mounted installer volume: background picture, window size, and icon places.
# The window stays open: Finder writes the icon view options into .DS_Store when the volume ejects.
style_installer_window() {
  /usr/bin/osascript <<APPLESCRIPT >/dev/null 2>&1
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {180, 140, 940, 660}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    set text size of viewOptions to 13
    set label position of viewOptions to bottom
    set background picture of viewOptions to file ".background:background.tiff"
    set position of item "$APP_NAME.app" of container window to {214, 262}
    set position of item "Applications" of container window to {546, 262}
    update without registering applications
    delay 2
  end tell
end tell
APPLESCRIPT
}

detach_installer_volume() {
  for _ in {1..10}; do
    if /usr/bin/hdiutil detach "$mount_point" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  /usr/bin/hdiutil detach "$mount_point" -force >/dev/null
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

cp "$SWIFT_DIR/BrandAssets/ubundi-icon.icns" "$APP_RESOURCES/ubundi-icon.icns"
cp "$SWIFT_DIR/BrandAssets/ubundi-icon.png" "$APP_RESOURCES/ubundi-icon.png"
cp "$SWIFT_DIR/BrandAssets/first-motive-icon.png" "$APP_RESOURCES/first-motive-icon.png"
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
  <string>ubundi-icon</string>
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
  <string>Atrium records meeting and dictation audio that you start.</string>
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>Atrium transcribes meeting and dictation audio on this Mac.</string>
  <key>NSScreenCaptureUsageDescription</key>
  <string>Atrium captures system audio only while you record a meeting.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

# macOS ties Microphone, Speech Recognition, and Screen Recording access to the
# code signature. An ad-hoc signature changes with every build, so each build
# starts without the access the previous one was granted. A stable local identity
# keeps those grants. Released disk images stay ad-hoc signed; see docs/RELEASING.md.
signing_identity() {
  if [[ "$MODE" == "--package" || "$MODE" == "package" ]]; then
    return
  fi
  if [[ -n "${ATRIUM_SIGNING_IDENTITY:-}" ]]; then
    printf '%s' "$ATRIUM_SIGNING_IDENTITY"
    return
  fi
  if /usr/bin/security find-identity -v -p codesigning 2>/dev/null \
    | grep -qF "$LOCAL_SIGNING_IDENTITY"; then
    printf '%s' "$LOCAL_SIGNING_IDENTITY"
  fi
}

IDENTITY="$(signing_identity)"
if [[ -n "$IDENTITY" ]]; then
  /usr/bin/codesign --force --sign "$IDENTITY" "$APP_BUNDLE"
else
  /usr/bin/codesign --force --sign - "$APP_BUNDLE"
  if [[ "$MODE" != "--package" && "$MODE" != "package" ]]; then
    echo "Signed ad hoc: macOS asks for Microphone, Speech Recognition, and Screen Recording access again after every build. Run ./script/create_signing_identity.sh once to keep those grants." >&2
  fi
fi
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
    package_temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/atrium-package.XXXXXX")"
    trap 'rm -rf "$package_temp_dir"' EXIT
    rm -f "$DMG_PATH" "$STABLE_DMG_PATH" "$LEGACY_DMG_PATH"
    staging_dir="$package_temp_dir/volume"
    writable_dmg="$package_temp_dir/$APP_NAME-writable.dmg"
    mkdir -p "$staging_dir/.background"
    /usr/bin/ditto "$APP_BUNDLE" "$staging_dir/$APP_NAME.app"
    ln -s /Applications "$staging_dir/Applications"
    swift "$ROOT_DIR/script/dmg_background.swift" \
      "$SWIFT_DIR/BrandAssets" \
      "$staging_dir/.background/background.tiff"

    # Slack space so Finder can write the window layout into the volume.
    staging_megabytes="$(/usr/bin/du -sm "$staging_dir" | cut -f1)"
    /usr/bin/hdiutil create \
      -volname "$VOLUME_NAME" \
      -srcfolder "$staging_dir" \
      -fs HFS+ \
      -format UDRW \
      -size "$((staging_megabytes + 80))m" \
      -ov \
      "$writable_dmg" >/dev/null

    mount_point="/Volumes/$VOLUME_NAME"
    if [[ -d "$mount_point" ]]; then
      /usr/bin/hdiutil detach "$mount_point" -force >/dev/null 2>&1 || true
    fi
    /usr/bin/hdiutil attach "$writable_dmg" -noverify -noautoopen >/dev/null
    /usr/bin/SetFile -a V "$mount_point/.background" 2>/dev/null || true
    if style_installer_window; then
      echo "Applied the installer window layout."
    else
      echo "Could not apply the installer window layout; shipping the plain disk image." >&2
    fi
    sleep 3
    sync
    detach_installer_volume

    /usr/bin/hdiutil convert "$writable_dmg" \
      -format UDZO \
      -imagekey zlib-level=9 \
      -ov \
      -o "$DMG_PATH" >/dev/null
    test -s "$DMG_PATH"
    cp "$DMG_PATH" "$STABLE_DMG_PATH"
    test -s "$STABLE_DMG_PATH"

    legacy_staging_dir="$package_temp_dir/legacy-volume"
    mkdir -p "$legacy_staging_dir"
    /usr/bin/ditto "$APP_BUNDLE" "$legacy_staging_dir/Notive.app"
    /usr/bin/hdiutil create \
      -volname "Atrium Legacy Update $VERSION" \
      -srcfolder "$legacy_staging_dir" \
      -fs HFS+ \
      -format UDZO \
      -ov \
      "$LEGACY_DMG_PATH" >/dev/null
    test -s "$LEGACY_DMG_PATH"

    rm -rf "$package_temp_dir"
    trap - EXIT
    echo "Created $DMG_PATH, $STABLE_DMG_PATH, and $LEGACY_DMG_PATH."
    ;;
esac
