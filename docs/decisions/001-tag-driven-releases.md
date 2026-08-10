# ADR-001: Use tag-driven GitHub Releases

## Status

Accepted

## Date

2026-08-10

## Context

Notive is a public repository and an internal macOS application. Users need a repeatable source for installers and a safe in-app update path. Earlier release workflows could create version variants that did not match the built application, and they did not reliably publish the updater manifest.

The application already uses the Tauri updater plugin. It needs a signed updater archive, its signature, and a `latest.json` manifest that matches the application version.

## Decision

Use a stable semantic version in all application manifests. A release is an annotated `vX.Y.Z` tag on a commit that is reachable from `main`.

The release workflow creates a draft GitHub Release from that tag. It ad-hoc signs the Apple Silicon macOS bundle, uploads the DMG and Tauri updater files, validates the bundle and updater manifest, then publishes the release. The application checks the `latest.json` asset from the latest published GitHub Release.

The release job uses the `release` GitHub Actions environment for deployment tracking and runs without an approval gate. The Tauri updater signing key is a GitHub secret and is not stored in this repository. The application does not use Apple code-signing or notarization credentials.

## Alternatives considered

### Manual GitHub Releases

Manual releases can omit an updater asset or a matching signature. They do not provide a repeatable record of the build inputs.

### A dynamic update service

A dynamic service can provide staged rollouts and rollback rules. It adds operational infrastructure that Notive does not currently need. GitHub Releases provide the required public installer and static update manifest without another service.

### Publish before validation

Publishing before bundle validation could make a defective artifact the latest application update. Draft releases keep the release private until verification completes.

### Apple Developer signing and notarization

Apple Developer signing would avoid the initial Gatekeeper warning. It requires credentials and an ongoing Apple Developer membership that the internal distribution model does not use. The application uses ad-hoc signing for macOS and a separate Tauri signature for updater integrity.

## Consequences

- A release requires a matching version change and a new immutable tag.
- Users can see a macOS Gatekeeper warning because releases are not notarized.
- The first production release requires the Tauri updater signing secrets in GitHub.
- The current release channel supports Apple Silicon macOS only.
- A faulty published version is corrected with a later patch release, not by moving a tag or editing its updater manifest.
