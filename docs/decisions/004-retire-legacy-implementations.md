# ADR-004: Retire the legacy implementations

## Status

Accepted

## Date

2026-08-11

## Context

ADR-002 kept the Tauri application as a temporary migration baseline until the native application had no release blockers. The native Swift application now owns the supported product workflows, compatible local data, internal packaging, and Sparkle updates. Keeping the Next.js, Tauri, Rust, Python, model-sidecar, and cross-platform build surfaces makes the repository larger and leaves obsolete workflows available to run.

Notive is an internal macOS product for Ubundi and First Motive. It does not need Windows, Linux, public contribution, or legacy model-runtime support.

## Decision

Keep one supported implementation: the Swift 6.1 and SwiftUI macOS application in `macos/`.

Remove the retired application trees, their package manifests, migration ledger, generated command inventory, model-sidecar code, legacy update tools, and cross-platform workflows. Move the three bundle assets used by the native packaging script into `macos/BrandAssets/`. Keep the compatible bundle identifier, database path, legal notices, internal release workflow, and Sparkle update path.

Git history remains the source for legacy implementation details. Do not restore a buildable migration baseline unless a new accepted decision requires it.

## Alternatives considered

### Keep the legacy trees as an archive

This preserves direct access to the old code but also preserves stale dependencies, workflows, and maintenance signals. Git already provides the required historical access.

### Move the legacy trees to an archive branch

An archive branch creates another long-lived reference that can drift or appear supported. The existing commit history is sufficient.

### Keep cross-platform build workflows

These workflows cannot build the native Swift product on Windows or Linux. Keeping them would report on an application that Notive no longer supports.

## Consequences

- The repository has one application stack and one default test command.
- Native development needs Xcode, Swift 6.1 or later, and macOS 14 or later.
- Old Tauri, Rust, Python, Windows, and Linux behavior is available only from Git history.
- The `com.ubundi.meet` bundle identifier and application-support database path remain unchanged.
- Internal DMG, ZIP, appcast, and local-install workflows remain supported.

## Supersedes

This decision supersedes the temporary migration-baseline retention in ADR-002.
