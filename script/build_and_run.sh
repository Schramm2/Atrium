#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Ubundi Meet"
PROCESS_NAME="ubundi-meet"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"
APP_BUNDLE="$ROOT_DIR/target/release/bundle/macos/$APP_NAME.app"
APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/$PROCESS_NAME"
TARGET_TRIPLE="$(rustc -vV | sed -n 's/^host: //p')"
SIDECAR_SOURCE="$ROOT_DIR/target/release/llama-helper"
SIDECAR_DESTINATION="$FRONTEND_DIR/src-tauri/binaries/llama-helper-$TARGET_TRIPLE"

usage() {
  echo "usage: $0 [run|--verify|--logs|--debug]" >&2
}

case "$MODE" in
  run|--verify|verify|--logs|logs|--debug|debug)
    ;;
  *)
    usage
    exit 2
    ;;
esac

stop_running_app() {
  pkill -x "$PROCESS_NAME" >/dev/null 2>&1 || true

  for _ in {1..50}; do
    if ! pgrep -x "$PROCESS_NAME" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done

  echo "$APP_NAME did not stop within 5 seconds." >&2
  return 1
}

build_app() {
  (
    cd "$FRONTEND_DIR"
    cargo build --release -p llama-helper --features metal
  )

  mkdir -p "$(dirname "$SIDECAR_DESTINATION")"
  cp "$SIDECAR_SOURCE" "$SIDECAR_DESTINATION"

  (
    cd "$FRONTEND_DIR"
    pnpm exec tauri build --bundles app \
      --config '{"bundle":{"createUpdaterArtifacts":false}}'
  )

  if [[ ! -d "$APP_BUNDLE" || ! -x "$APP_EXECUTABLE" ]]; then
    echo "The Tauri build did not create $APP_BUNDLE." >&2
    return 1
  fi
}

launch_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

verify_launch() {
  launch_app

  for _ in {1..100}; do
    if pgrep -x "$PROCESS_NAME" >/dev/null 2>&1; then
      echo "$APP_NAME is running from $APP_BUNDLE."
      return 0
    fi
    sleep 0.1
  done

  echo "$APP_NAME did not start within 10 seconds." >&2
  return 1
}

stop_running_app
build_app

case "$MODE" in
  run)
    launch_app
    ;;
  --verify|verify)
    verify_launch
    ;;
  --logs|logs)
    launch_app
    exec /usr/bin/log stream --info --style compact \
      --predicate "process == \"$PROCESS_NAME\""
    ;;
  --debug|debug)
    cd "$(dirname "$APP_EXECUTABLE")"
    exec lldb -- "$APP_EXECUTABLE"
    ;;
esac
