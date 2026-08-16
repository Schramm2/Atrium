# Changelog

All notable changes to Notive are recorded in this file.

This project uses stable semantic versions in the form `X.Y.Z`.

## 0.9.1

### Fixed

- Status labels now meet WCAG AA. The state tint stays on the icon, the capsule fill, and the border, and the title uses the theme text color.

### Changed

- Layout spacing follows one scale of 8, 12, 16, 20, 24, 32, and 48 points. Values of 1 to 6 points are optical adjustments inside a component.
- Corner radii use two steps: 8 points for controls, chips, avatars, and compact rows, and 12 points for panels, sections, and overlays.
- `DESIGN.md` records the palette, typography, spacing, shapes, and components as machine-readable tokens read from `BrandStyle.swift`.

### Added

- `FRONTEND.md` describes interface topology, layer boundaries, state ownership, the recipe for a new screen, and interface verification.
- `CONTEXT.md` is tracked, so the domain language and repository map reach every clone.
- `docs/architecture.md` gains a codemap, the important runtime flows, and architectural invariants with the test that proves each one.

## Unreleased

### Changed

- Rebranded the application, Swift targets, bundles, release assets, and user-facing copy to Atrium. Ubundi and First Motive remain the two interface themes.
- Renamed the GitHub repository to `Schramm2/Atrium`. Existing local data, preference keys, keychain service, and recordings path remain compatible.

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
