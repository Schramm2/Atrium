# Atrium Agent Guide

## Product and application ownership

This repository builds **Atrium**, a privacy-first, local-first company intelligence workspace for internal use by Ubundi and First Motive. Use `Atrium` in prose and user-facing labels. Ubundi and First Motive are theme identities. Keep `ubundi-meet`, `com.ubundi.meet`, and existing GitHub URLs only where data, release, or repository compatibility requires them.

The product is the native Swift 6.1 and SwiftUI macOS application in `macos/`. `Atrium` owns scenes and views. `AtriumCore` owns local data, audio, transcription, retrieval, and language services. The retired Tauri, Rust, and Python implementations are available only in Git history.

## Context routes

- Read [CONTEXT.md](CONTEXT.md) before you name code, artifacts, or user-facing text, or when you need the repository map.
- For component ownership, dependency flow, local data, providers, and distribution boundaries, read [docs/architecture.md](docs/architecture.md).
- For screen placement, state ownership, interface states, and interface verification, read [FRONTEND.md](FRONTEND.md).
- For themes, layout, typography, and user-facing copy, read [DESIGN.md](DESIGN.md).
- For the two scopes, the privacy invariant, and unbuilt functionality, read [docs/product-vision.md](docs/product-vision.md).
- For setup, running, runtime inspection, packaging, tests, and permissions, read [docs/BUILDING.md](docs/BUILDING.md).
- Before changing packaging, versions, application updates, or GitHub release behavior, read [docs/RELEASING.md](docs/RELEASING.md) and the accepted records in [docs/decisions/](docs/decisions/).
- Use a repo-local skill in `.agents/skills/` when its description matches the task. Harness adapters in `.claude/skills/` route to the same skills. Some skill packages are checkout-local and are absent from a fresh clone.

## Boundaries

- Preserve the bundle identifier `com.ubundi.meet`, the active database at `~/Library/Application Support/Notive/`, the additive import from `~/Library/Application Support/com.ubundi.meet/`, and compatible meeting data unless Matthew approves another migration. The `Notive` support directory remains for install-base compatibility.
- Keep recording, transcription, SQLite storage, retrieval, citations, and default answer generation on the Mac. Require the existing confirmation boundary before an external Ask provider receives a question and selected evidence.
- Use Apple system frameworks and the authenticated GitHub CLI update path before proposing a production dependency.
- Treat `dist/`, `target/`, `.next/`, Swift `.build/`, and generated migration inventories as derived output. Change their source or generator.
- Keep [LICENSE.md](LICENSE.md) and [NOTICE.md](NOTICE.md) with distributed source and substantial copies.

## Develop and verify

Run native application commands from the repository root:

```bash
./script/build_and_run.sh run
cd macos && swift test -Xswiftc -warnings-as-errors
```

Verify the smallest relevant behavior first. For native Swift changes, the warnings-as-errors test suite is the default completion check. Packaging and release changes require the checks in their routed documents.
