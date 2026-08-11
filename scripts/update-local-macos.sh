#!/usr/bin/env bash

# Build the current checkout and replace the local Notive app.
# This is intentionally separate from the GitHub release command. It does
# not create a tag or publish an artifact.

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_APP="/Applications/Notive.app"
STAGED_APP="/Applications/.Notive.app.installing.$$"
BACKUP_APP="/Applications/.Notive.app.backup.$$"
BUILD_APP="$ROOT_DIR/dist/Notive.app"
SUPPORT_DIR="${HOME}/Library/Application Support/com.ubundi.meet"
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

for command_name in codesign date ditto git plutil stat swift; do
  require_command "$command_name"
done

if /usr/bin/pgrep -x Notive >/dev/null 2>&1; then
  fail "Notive is running. Quit it before updating so an active recording is not interrupted."
fi

COMMIT="$(git -C "$ROOT_DIR" rev-parse HEAD)"
SHORT_COMMIT="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
BRANCH="$(git -C "$ROOT_DIR" branch --show-current)"
VERSION="$(plutil -extract version raw "$ROOT_DIR/macos/version.json")"
WORKTREE_STATUS="$(git -C "$ROOT_DIR" status --short)"

echo "Notive local updater"
echo "  branch:  ${BRANCH:-detached HEAD}"
echo "  commit:  $COMMIT"
echo "  version: $VERSION"

if [[ -n "$WORKTREE_STATUS" ]]; then
  echo
  echo "Working tree changes will be included in this local build:"
  printf '%s\n' "$WORKTREE_STATUS"
fi

BUILD_STARTED="$(date +%s)"

echo
echo "Building the current checkout..."
"$ROOT_DIR/script/build_and_run.sh" --package

[[ -d "$BUILD_APP" ]] || fail "The build did not produce $BUILD_APP."

BUILD_BINARY="$(find "$BUILD_APP/Contents/MacOS" -maxdepth 1 -type f -print -quit)"
[[ -n "$BUILD_BINARY" ]] || fail "The build did not produce a main executable in $BUILD_APP."

BUILD_MTIME="$(stat -f %m "$BUILD_BINARY")"
(( BUILD_MTIME >= BUILD_STARTED )) || fail "The app artifact is older than this build attempt."

echo
echo "Installing $BUILD_APP"
ditto --rsrc --extattr --acl "$BUILD_APP" "$STAGED_APP"
codesign --verify --deep --strict "$STAGED_APP"

if [[ -e "$INSTALL_APP" ]]; then
  mv "$INSTALL_APP" "$BACKUP_APP"
fi

if ! mv "$STAGED_APP" "$INSTALL_APP"; then
  [[ -e "$BACKUP_APP" ]] && mv "$BACKUP_APP" "$INSTALL_APP"
  fail "Could not move the new app into /Applications."
fi

if ! codesign --verify --deep --strict "$INSTALL_APP"; then
  rm -rf "$INSTALL_APP"
  [[ -e "$BACKUP_APP" ]] && mv "$BACKUP_APP" "$INSTALL_APP"
  fail "The installed app failed code-signature verification. The previous app was restored."
fi

[[ ! -e "$BACKUP_APP" ]] || rm -rf "$BACKUP_APP"

INSTALLED_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$INSTALL_APP/Contents/Info.plist")"
INSTALLED_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INSTALL_APP/Contents/Info.plist")"
[[ "$INSTALLED_NAME" == "Notive" ]] || fail "Installed app name is '$INSTALLED_NAME', not 'Notive'."
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
echo "Installed Notive $VERSION from commit $SHORT_COMMIT."
echo "Receipt: $RECEIPT_FILE"
echo "Open it with: open -n '$INSTALL_APP'"
