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

The release workflow creates a draft GitHub Release from that tag. It signs and notarizes the Apple Silicon macOS bundle, uploads the DMG and Tauri updater files, validates the bundle and updater manifest, then publishes the release. The application checks the `latest.json` asset from the latest published GitHub Release.

The release job runs in the protected `release` GitHub Actions environment. Apple and Tauri signing keys are environment secrets and are not stored in this repository.

## Alternatives considered

### Manual GitHub Releases

Manual releases can omit an updater asset or a matching signature. They do not provide a repeatable record of the build inputs.

### A dynamic update service

A dynamic service can provide staged rollouts and rollback rules. It adds operational infrastructure that Notive does not currently need. GitHub Releases provide the required public installer and static update manifest without another service.

### Publish before validation

Publishing before bundle validation could make a defective artifact the latest application update. Draft releases keep the release private until verification completes.

## Consequences

- A release requires a matching version change and a new immutable tag.
- The first production release requires Apple Developer and Tauri signing secrets in GitHub.
- The current release channel supports Apple Silicon macOS only.
- A faulty published version is corrected with a later patch release, not by moving a tag or editing its updater manifest.
