#!/usr/bin/env bash

# Build the current checkout and replace the local Ubundi Meet app.
# This is intentionally separate from the GitHub release workflow. It does
# not create a tag, publish an artifact, or touch the updater manifest.

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"
INSTALL_APP="/Applications/Ubundi Meet.app"
BUILD_APP="$ROOT_DIR/target/release/bundle/macos/Ubundi Meet.app"
SUPPORT_DIR="${HOME}/Library/Application Support/com.meetily.ai"
RECEIPT_FILE="$SUPPORT_DIR/installed-build.txt"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

fail() {
  echo "Error: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "'$1' is required."
}

[[ "$(uname -s)" == "Darwin" ]] || fail "This updater is for macOS."

for command_name in cargo codesign date ditto git pnpm stat; do
  require_command "$command_name"
done

if /usr/bin/pgrep -x meetily >/dev/null 2>&1; then
  fail "Ubundi Meet is running. Quit it before updating so an active recording is not interrupted."
fi

COMMIT="$(git -C "$ROOT_DIR" rev-parse HEAD)"
SHORT_COMMIT="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
BRANCH="$(git -C "$ROOT_DIR" branch --show-current)"
VERSION="$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' "$FRONTEND_DIR/src-tauri/tauri.conf.json" | head -n 1)"
WORKTREE_STATUS="$(git -C "$ROOT_DIR" status --short)"

echo "Ubundi Meet local updater"
echo "  branch:  ${BRANCH:-detached HEAD}"
echo "  commit:  $COMMIT"
echo "  version: $VERSION"

if [[ -n "$WORKTREE_STATUS" ]]; then
  echo
  echo "Working tree changes will be included in this local build:"
  printf '%s\n' "$WORKTREE_STATUS"
fi

if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
  echo
  echo "Installing frontend dependencies..."
  (cd "$FRONTEND_DIR" && pnpm install --frozen-lockfile)
fi

BUILD_STARTED="$(date +%s)"
BUILD_EXIT=0

echo
echo "Building the current checkout..."
set +e
(cd "$FRONTEND_DIR" && ./build-gpu.sh)
BUILD_EXIT=$?
set -e

[[ -d "$BUILD_APP" ]] || fail "The build did not produce $BUILD_APP."

BUILD_BINARY="$(find "$BUILD_APP/Contents/MacOS" -maxdepth 1 -type f \
  ! -name 'ffmpeg' ! -name 'llama-helper' -print -quit)"
[[ -n "$BUILD_BINARY" ]] || fail "The build did not produce a main executable in $BUILD_APP."

BUILD_MTIME="$(stat -f %m "$BUILD_BINARY")"
(( BUILD_MTIME >= BUILD_STARTED )) || fail "The app artifact is older than this build attempt."

if (( BUILD_EXIT != 0 )); then
  echo
  echo "Warning: the packaging command returned $BUILD_EXIT after creating a fresh app."
  echo "Continuing with the local install. This usually means updater signing keys are not configured."
fi

echo
echo "Installing $BUILD_APP"
ditto --rsrc --extattr --acl "$BUILD_APP" "$INSTALL_APP"

codesign --verify --deep --strict "$INSTALL_APP"

INSTALLED_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$INSTALL_APP/Contents/Info.plist")"
INSTALLED_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INSTALL_APP/Contents/Info.plist")"
[[ "$INSTALLED_NAME" == "Ubundi Meet" ]] || fail "Installed app name is '$INSTALLED_NAME', not 'Ubundi Meet'."
[[ "$INSTALLED_VERSION" == "$VERSION" ]] || fail "Installed version is '$INSTALLED_VERSION', expected '$VERSION'."

mkdir -p "$SUPPORT_DIR"
{
  echo "commit=$COMMIT"
  echo "branch=$BRANCH"
  echo "version=$VERSION"
  echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "source=$ROOT_DIR"
} > "$RECEIPT_FILE"

if [[ -x "$LSREGISTER" ]]; then
  "$LSREGISTER" -f "$INSTALL_APP" >/dev/null 2>&1 || true
fi

echo
echo "Installed Ubundi Meet $VERSION from commit $SHORT_COMMIT."
echo "Receipt: $RECEIPT_FILE"
echo "Open it with: open -n '$INSTALL_APP'"
