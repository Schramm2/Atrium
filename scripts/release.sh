#!/usr/bin/env bash

# Cut a Notive release from a maintainer Mac. This is the only supported release
# path: it updates the application version, commits and pushes that change, builds
# the disk images, and creates the private GitHub Release and tag.

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=""
DRY_RUN=0
FORCE=0

usage() {
  echo "usage: $0 <version> [--dry-run] [--force]" >&2
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

for argument in "$@"; do
  case "$argument" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*) fail "Unknown option '$argument'." ;;
    *)
      [[ -z "$VERSION" ]] || fail "Pass one version only."
      VERSION="$argument"
      ;;
  esac
done

[[ -n "$VERSION" ]] || fail "Pass a version such as 0.6.0."
[[ "$VERSION" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] \
  || fail "Version must use stable semantic versioning without a leading v."

TAG="v$VERSION"
VERSION_FILE="$ROOT_DIR/macos/version.json"
VERSIONED_DMG="$ROOT_DIR/dist/Notive-$VERSION-arm64.dmg"
STABLE_DMG="$ROOT_DIR/dist/Notive.dmg"

command -v gh >/dev/null 2>&1 || fail "GitHub CLI is required."
gh auth status >/dev/null 2>&1 || fail "Sign in first with 'gh auth login'."

if gh release view "$TAG" --repo Schramm2/notive >/dev/null 2>&1; then
  fail "GitHub Release $TAG already exists."
fi

if git -C "$ROOT_DIR" rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
  fail "Local tag $TAG already exists."
fi

if git -C "$ROOT_DIR" ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
  fail "Remote tag $TAG already exists."
else
  remote_tag_status=$?
  [[ "$remote_tag_status" -eq 2 ]] || fail "Could not check remote tags."
fi

CURRENT_BRANCH="$(git -C "$ROOT_DIR" branch --show-current)"
WORKTREE_STATUS="$(git -C "$ROOT_DIR" status --short)"

if [[ -n "$WORKTREE_STATUS" && "$FORCE" -ne 1 ]]; then
  fail "The worktree is not clean. Commit or stash changes first."
fi

if [[ "$CURRENT_BRANCH" != "main" && "$FORCE" -ne 1 ]]; then
  fail "Releases must be cut from main."
fi

CURRENT_VERSION="$(plutil -extract version raw "$VERSION_FILE")"
echo "Preparing Notive $TAG from ${CURRENT_BRANCH:-detached HEAD}."

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run: the version file, Git history, tag, and release will not change."
else
  if [[ "$CURRENT_VERSION" != "$VERSION" ]]; then
    plutil -replace version -string "$VERSION" "$VERSION_FILE"
    [[ "$(plutil -extract version raw "$VERSION_FILE")" == "$VERSION" ]] \
      || fail "Could not update $VERSION_FILE."
    git -C "$ROOT_DIR" add "$VERSION_FILE"
    git -C "$ROOT_DIR" commit -m "chore: release $TAG"
    git -C "$ROOT_DIR" push origin "$CURRENT_BRANCH"
  fi
fi

echo "Building the release disk images."
NOTIVE_BUILD_VERSION="$VERSION" "$ROOT_DIR/script/build_and_run.sh" --package

[[ -s "$VERSIONED_DMG" ]] || fail "Expected $VERSIONED_DMG."
[[ -s "$STABLE_DMG" ]] || fail "Expected $STABLE_DMG."
codesign --verify --deep --strict "$ROOT_DIR/dist/.Notive.app"
hdiutil verify "$VERSIONED_DMG" >/dev/null

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run complete. Would create $TAG with $VERSIONED_DMG and $STABLE_DMG."
  exit 0
fi

echo "Creating GitHub Release $TAG."
gh release create "$TAG" \
  "$VERSIONED_DMG" \
  "$STABLE_DMG" \
  --repo Schramm2/notive \
  --target "$CURRENT_BRANCH" \
  --title "Notive $TAG" \
  --generate-notes

echo "Released Notive $TAG."
