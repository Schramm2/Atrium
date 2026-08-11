# ADR-005: Use private GitHub Releases for application updates

## Status

Accepted

## Date

2026-08-11

## Context

Notive is an internal application for Ubundi and First Motive. Its repository and release artifacts will be private. The Sparkle configuration in ADR-003 used unauthenticated GitHub Release URLs, which stop working when the repository becomes private.

The companies already use the GitHub CLI for private engineering tools. First Motive Desktop uses an authenticated GitHub CLI session to resolve and download its private releases.

## Decision

Remove Sparkle and its signing secret, appcast, ZIP, framework, and release workflow.

Use `macos/version.json` as the application version. A maintainer runs `scripts/release.sh X.Y.Z` from `main`. The script updates the version, commits and pushes it, builds a versioned DMG and stable DMG, and uses `gh release create` to create the private GitHub Release and `vX.Y.Z` tag.

The application checks the newest release with authenticated `gh release view`. On user approval, it downloads the versioned DMG with `gh release download`, mounts it, stages and verifies `Notive.app`, replaces `/Applications/Notive.app`, and relaunches. Installation uses a backup and restores the previous application when replacement or verification fails.

## Alternatives considered

### Keep Sparkle with private hosting

This keeps independent Ed25519 update signatures but needs a separate authenticated artifact host or custom authentication integration. The internal team does not need that additional service.

### Managed device deployment

An MDM system can install updates without an in-app updater. The companies do not currently use one release channel for every Notive Mac.

### Manual DMG installation

This has the smallest implementation but makes users monitor releases and replace the application themselves.

## Consequences

- Each Mac needs GitHub CLI and an authenticated account with repository access.
- Release access is private and follows GitHub organization membership.
- The application keeps automatic checks, manual checks, version display, install progress, and relaunch behavior.
- The release has `Notive-<version>-arm64.dmg` and `Notive.dmg`; it has no appcast or update ZIP.
- GitHub authentication and HTTPS protect artifact access in transit, but there is no independent Sparkle update signature.
- The existing ad-hoc signing and Gatekeeper constraints remain.
- CI continues to build, test, and verify packages. A maintainer publishes releases locally.

## Supersedes

This decision supersedes ADR-003 and the updater-artifact parts of ADR-001 and ADR-004.
