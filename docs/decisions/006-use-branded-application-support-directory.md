# ADR-006: Use the branded application-support directory

## Status

Accepted

## Date

2026-08-12

## Context

Notive kept meeting data under `~/Library/Application Support/com.ubundi.meet/` for compatibility with the retired implementation. The bundle identifier must remain `com.ubundi.meet`, but the visible application-support folder still uses the retired Ubundi Meet name.

A normal application deletion leaves Application Support data on the Mac. A new installation therefore needs to find both the current Notive folder and data left in the earlier bundle-identifier folder without deleting or rewriting the source.

## Decision

Use `~/Library/Application Support/Notive/` for the active database and application metadata. Keep the bundle identifier `com.ubundi.meet` unchanged.

When `~/Library/Application Support/com.ubundi.meet/meeting_minutes.sqlite` contains meetings, offer to restore them during onboarding. Existing users who already completed onboarding receive the same offer in the workspace and can restore later in Settings.

Restoration copies meetings that do not already exist, together with their transcripts, notes, summaries, speaker aliases, and available recording folders. A meeting is a duplicate when its identifier matches or when its title and creation time both match. Existing data wins. The earlier database and recording folders remain unchanged.

## Alternatives considered

### Keep the bundle-identifier directory as the active location

This avoids migration logic but keeps retired product branding in a user-visible data path.

### Move the complete directory automatically

This gives the new path immediately but makes startup destructive and makes partial failures harder to recover from. It also removes the earlier copy before the user confirms the migration.

### Open the earlier database in place

This preserves one database but does not establish the branded path and cannot merge data when both locations contain meetings.

## Consequences

- New and reinstalled versions use `~/Library/Application Support/Notive/` automatically.
- Earlier data remains recoverable from `~/Library/Application Support/com.ubundi.meet/`.
- Restoration is additive and keeps duplicates in the active database unchanged.
- Recording folders outside the selected recordings folder are copied into it when available.
- The legacy folder can remain on disk after a successful restore.
- Release and support tools must write new application metadata under the branded directory.

## Supersedes

This decision supersedes ADR-004 only where that record keeps the application-support database path unchanged. The native-only application decision and the compatible `com.ubundi.meet` bundle identifier remain in force.
