# Changelog

All notable changes to Notive are recorded in this file.

This project uses stable semantic versions in the form `X.Y.Z`.

## Unreleased

### Added

- Onboarding, the workspace, and Settings can restore non-duplicate meetings and available recordings from an earlier Notive installation.

### Changed

- Active application data now uses `~/Library/Application Support/Notive/`; the earlier `com.ubundi.meet` folder remains unchanged during restoration.
- Notive now has one supported implementation: the native Swift and SwiftUI macOS application.
- Native bundle assets now live with the macOS source.
- Private GitHub Releases, tags, and authenticated GitHub CLI now provide application updates.

### Removed

- The retired Tauri, Next.js, Rust, Python, and model-sidecar implementations.
- Legacy cross-platform build workflows and migration-only checks.
- Sparkle, appcasts, signed update ZIPs, and the tag-triggered release workflow.
