# Notive Agent Guide

## Product and application ownership

This repository builds **Notive**, a privacy-first, local-first AI meeting assistant for internal use by Ubundi and First Motive. Use `Notive` in prose and user-facing labels. Ubundi and First Motive are theme identities. Keep `ubundi-meet`, `com.ubundi.meet`, and existing GitHub URLs only where data, release, or repository compatibility requires them.

The product is the native Swift 6.1 and SwiftUI macOS application in `macos/`. `Notive` owns scenes and views. `NotiveCore` owns local data, audio, transcription, retrieval, and language services. The retired Tauri, Rust, and Python implementations are available only in Git history.

## Context routes

- For component ownership, dependency flow, local data, providers, and distribution boundaries, read [docs/architecture.md](docs/architecture.md).
- For setup, running, packaging, tests, and permissions, read [docs/BUILDING.md](docs/BUILDING.md).
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
cd macos && swift test -Xswiftc -warnings-as-errors
```

Verify the smallest relevant behavior first. For native Swift changes, the warnings-as-errors test suite is the default completion check. Packaging and release changes require the checks in their routed documents.
