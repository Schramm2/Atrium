# ADR-003: Use Sparkle for native application updates

## Status

Accepted

## Date

2026-08-10

## Context

ADR-001 selected Tauri updater archives and a Tauri `latest.json` manifest. The native Swift application cannot install that archive format safely. Notive still needs signed, repeatable updates through GitHub Releases while it uses internal ad-hoc macOS code signing.

## Decision

Use Sparkle 2.9.2 through Swift Package Manager. Embed its framework in the native application, use the standard Sparkle user interface, and keep the existing daily automatic-check preference. Serve an HTTPS `appcast.xml` and ZIP archive from each GitHub Release.

Sign update archives and the appcast with a Notive-specific Ed25519 key. Store the private seed only in the local Keychain and the GitHub `SPARKLE_PRIVATE_KEY` secret. Store the public key in the built application. Require feed signatures and update verification before extraction.

Continue ad-hoc signing for the internal distribution model. Do not claim Developer ID signing or notarization when no valid identity or credentials exist.

## Consequences

- Sparkle replaces the Tauri updater and its Minisign key for native releases.
- Release artifacts become a DMG, a signed ZIP, and a signed `appcast.xml`.
- The release workflow no longer needs Node, pnpm, Rust, the Tauri action, or the llama-helper sidecar.
- Losing both private-key copies would block ordinary key rotation because the application is not Developer ID signed.
- Gatekeeper can still warn on first installation.

## Supersedes

This decision supersedes the updater-format and release-artifact parts of ADR-001. A temporary 0.4.9 native bundle installed the production-key-signed 0.5.0 archive and relaunched successfully.
