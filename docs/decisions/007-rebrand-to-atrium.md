# ADR-007: Rebrand the application to Atrium

## Status

Accepted

## Date

2026-08-14

## Context

The product has grown from a meeting assistant into a company intelligence workspace for Ubundi and First Motive. The former name and its conversation-led visual framing no longer describe the product direction. The application also needs a third visual identity for the Atrium workspace while keeping the existing Ubundi and First Motive themes available.

The rename crosses Swift package targets, source directories, symbols, application bundles, release assets, documentation, and user-facing copy. Existing installations also have durable local data, preference keys, keychain entries, and an authenticated GitHub release path. Those compatibility boundaries must not move with the visible product name.

## Decision

Rename the product, application, Swift package targets, source directories, test targets, symbols, scripts, and user-facing labels to **Atrium**. The application target is `Atrium`, the core library target is `AtriumCore`, and the application bundle is `Atrium.app`.

Add `BrandTheme.atrium` as the first and default theme. Atrium is dark-only and uses the approved AuthKit adaptation: the midnight palette, luminous text ramp, frosted tonal washes, and low-opacity hairline borders. The existing 8/12-point geometry, system typeface, spacing scale, information architecture, and component contracts remain shared by all three themes. Ubundi and First Motive keep their existing theme behavior.

Use a clean-break updater transition. New releases publish only `Atrium-X.Y.Z-arm64.dmg` and `Atrium.dmg`. Existing installations update manually once; after that they use the Atrium updater. The GitHub repository remains `Schramm2/notive` for release history and access compatibility. The release itself is not run as part of this change.

Generate the Atrium marks, wordmark, icon, and `Atrium.icns` programmatically as replaceable first-pass assets. The source generator is not committed; the generated assets are committed in `macos/BrandAssets/` and can be replaced by approved final artwork without changing the runtime contract.

## Compatibility invariants

The following identifiers and records keep their current values byte-for-byte:

- Bundle identifier: `com.ubundi.meet`.
- Logging subsystem: `com.ubundi.meet`.
- Keychain service: `com.ubundi.meet.ai`.
- Active database directory: `~/Library/Application Support/Notive/`, including the legacy import directory `~/Library/Application Support/com.ubundi.meet/` and the `meeting_minutes.sqlite` filename.
- UserDefaults keys: `notive.ai.endpoint`, `notive.ai.model`, `notive.ai.provider`, `notive.app-icon`, `notive.appearance`, `notive.dictation.microphone`, `notive.dictation.shortcut`, `notive.hub.agents-read-shared`, `notive.hub.appear-in-people`, `notive.hub.github-login`, `notive.hub.github-organization`, `notive.hub.profile-name`, `notive.hub.profile-role`, `notive.hub.share-activity`, `notive.notifications.errors`, `notive.notifications.paused`, `notive.notifications.recording`, `notive.notifications.sound`, `notive.notifications.test`, `notive.notifications.transcription`, `notive.onboarding.complete`, `notive.recording.folder`, `notive.recording.microphone`, `notive.recording.save-audio`, `notive.recording.system-audio`, `notive.summary.automatic`, `notive.summary.language`, `notive.summary.language.meeting.<meeting-id>`, `notive.summary.template`, `notive.transcription.language`, `notive.updates.automatic`, and `ubundi-meet-brand-theme`.
- Default recordings directory: `~/Movies/notive-recordings/`.
- GitHub repository: `Schramm2/notive`.
- ADRs `docs/decisions/001` through `docs/decisions/006` remain immutable historical records.
- Existing `CHANGELOG.md` entries remain unchanged history.

## Alternatives considered

### Rename the GitHub repository

This would make the public repository identity match the application, but it would break existing release access, URLs, and the authenticated updater contract. The repository name is therefore retained.

### Migrate data and preference identifiers

A migration would add risk without user value. The visible product name can change while the active database directory, preference keys, keychain service, and recordings path stay compatible.

### Keep the old application bundle as an updater bridge

A bridge would require maintaining a second bundle identity and release path. Existing users can install the first Atrium release manually once, so the clean break is simpler and limits long-lived compatibility code.

### Create separate component geometry for Atrium

Separate geometry would make the themes harder to learn and maintain. Atrium gets its identity from color, tonal washes, text ramp, and hairline borders while the existing component geometry remains shared.

## Consequences

- New source paths and module names describe Atrium directly, which improves navigation for people and agents.
- Existing local meetings, settings, keychain API keys, and recordings remain discoverable without migration.
- The first Atrium marks are functional and replaceable; final brand artwork can be substituted later.
- Existing installations need one manual update because the updater now targets `Atrium.app` and Atrium-named release assets.
- Releases continue to use the private `Schramm2/notive` repository and the existing authenticated GitHub CLI workflow.
- Future changes to any compatibility invariant require a new accepted decision and a migration plan.
