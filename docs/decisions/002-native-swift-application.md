# ADR-002: Replace the Tauri desktop application with native Swift

## Status

Accepted; the temporary migration-baseline clause is superseded by ADR-004

## Date

2026-08-10

## Context

Notive is a macOS-only, privacy-first meeting assistant. Its current application combines a Next.js interface, a Tauri bridge, a large Rust core, bundled sidecars, and several local or external model integrations. Audio capture, permissions, global shortcuts, menu-bar behavior, updates, and application windows are all macOS platform concerns. The current repository also has stale build artifacts that retain absolute paths from an earlier checkout.

The replacement must preserve the current SQLite data, application identity, local data boundary, meeting workflows, and permission behavior. A new production dependency or a change to existing user data requires approval.

## Decision

Build the replacement as a Swift 6.1 package with a SwiftUI application target and a separate `NotiveCore` target. Use Apple frameworks for application UI, microphone capture, system audio capture, audio mixing and playback, speech recognition, notifications, and on-device language generation. Use the SQLite C API directly and keep the existing bundle identifier and database location.

Keep the former application buildable as the migration baseline until the native migration ledger has no release blockers. Use Sparkle only for signed native update installation, as accepted in ADR-003. ADR-004 records the completed cutover and removal of that baseline.

## Alternatives considered

### Continue with Tauri

This retains every model integration and the current signed updater. It also retains the JavaScript-to-Rust command surface and duplicates macOS lifecycle and permission concepts across three layers. It does not meet the requested Swift conversion.

### Use a hybrid Swift shell with the Rust core

This reduces UI migration work and keeps existing model engines. It does not convert the application core to Swift, and it preserves a large foreign-function and sidecar boundary.

### Add several third-party Swift packages

Model runtimes and database wrappers could shorten some work, but they would recreate large dependency surfaces. The replacement uses Apple frameworks and the SQLite library supplied by macOS. Sparkle is the approved exception for secure update installation.

## Consequences

- Native window, menu-bar, permission, audio, and Accessibility behavior has one platform owner.
- Existing meeting data opens without an import or schema rewrite.
- Apple on-device speech and language frameworks replace the current default built-in models where the operating system supports them.
- macOS 14 remains the minimum system version. Apple Intelligence is optional and has a deterministic local fallback.
- Native acoustic feature clustering replaces the ONNX speaker runtime without retaining voice profiles.
- Sparkle replaces the Tauri updater for native releases.
- ADR-004 retires the temporary Tauri migration baseline after the native cutover.
