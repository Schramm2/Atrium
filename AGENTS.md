# Notive Agent Guide

## Product and application ownership

This repository builds **Notive**, a privacy-first, local-first AI meeting assistant for internal use by Ubundi and First Motive. Use `Notive` in prose and user-facing labels. Ubundi and First Motive are theme identities. Keep `ubundi-meet`, `com.ubundi.meet`, and existing GitHub URLs only where data, release, or repository compatibility requires them.

The supported release target is the native Swift 6.1 and SwiftUI macOS application in `macos/`. `Notive` owns scenes and views; `NotiveCore` owns local data, audio, transcription, retrieval, and language services. The Tauri application in `frontend/` is a buildable migration baseline, not the release target. `backend/` is an archived Python implementation.

## Context routes

- For component ownership, dependency flow, local data, providers, and distribution boundaries, read [docs/architecture.md](docs/architecture.md).
- For setup, running, packaging, tests, permissions, and the retained Tauri baseline, read [docs/BUILDING.md](docs/BUILDING.md).
- Before changing migration parity, compatibility, or the retained Tauri surface, read [docs/SWIFT_MIGRATION.md](docs/SWIFT_MIGRATION.md) and [docs/TAURI_COMMAND_INVENTORY.md](docs/TAURI_COMMAND_INVENTORY.md).
- Before changing packaging, versions, update signing, or GitHub release behavior, read [docs/RELEASING.md](docs/RELEASING.md) and the accepted records in [docs/decisions/](docs/decisions/).
- Use a repo-local skill in `.agents/skills/` when its description matches the task. Harness adapters in `.claude/skills/` route to the same skills.

## Boundaries

- Preserve the bundle identifier `com.ubundi.meet`, the database at `~/Library/Application Support/com.ubundi.meet/`, and compatible meeting data unless Matthew approves a migration.
- Keep recording, transcription, SQLite storage, retrieval, citations, and default answer generation on the Mac. Require the existing confirmation boundary before an external Ask provider receives a question and selected evidence.
- Use Apple system frameworks before proposing a production dependency. Sparkle is the approved exception.
- Treat `dist/`, `target/`, `.next/`, Swift `.build/`, and generated migration inventories as derived output. Change their source or generator.
- Keep [LICENSE.md](LICENSE.md) and [NOTICE.md](NOTICE.md) with distributed source and substantial copies.

## Develop and verify

Run native application commands from the repository root:

```bash
./script/build_and_run.sh run
node scripts/check-swift-migration-inventory.mjs --check
cd macos && swift test -Xswiftc -warnings-as-errors
```

When a change affects `frontend/`, run its narrow check from that directory. Keep the baseline buildable with the commands in `docs/BUILDING.md`.

Verify the smallest relevant behavior first. For native Swift changes, the warnings-as-errors test suite is the default completion check. Also run the migration inventory check when a change affects migration parity or the Tauri command surface. Packaging and release changes require the checks in their routed documents.
