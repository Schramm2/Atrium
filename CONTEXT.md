# Atrium

Atrium is a privacy-first, local-first macOS company intelligence workspace for Ubundi and First Motive. This file gives the domain language and the map of the repository. It does not repeat behavior rules or architecture detail.

## Read first

- [AGENTS.md](AGENTS.md) for the agent contract, ownership, and boundaries.
- [docs/architecture.md](docs/architecture.md) for components, dependency flow, and the repository boundary.
- [docs/product-vision.md](docs/product-vision.md) for scopes, the privacy invariant, and unbuilt functionality.
- [FRONTEND.md](FRONTEND.md) for screens, stores, interface states, and interface verification.
- [DESIGN.md](DESIGN.md) before changing an interface, a theme, or user-facing copy.
- [docs/decisions/](docs/decisions/) before changing data location, packaging, or updates.

## Domain language

Use these terms in code, prose, and labels. The two scopes are the most important distinction in the product.

**My Workspace**: The private, local scope on one person's Mac. It holds meeting capture, transcripts, notes, summaries, Dictation, Ask, and local search. Modeled by `WorkspaceSelection` and `MeetingWorkspace` in `macos/Sources/AtriumCore/Models/`.
_Avoid_: personal workspace, private mode

**Company Hub**: The shared company scope for agents, approved knowledge, people, search, and activity. Content enters only through an explicit owner share action. Modeled by the `Hub*` types in `Models/CompanyHub.swift`.
_Avoid_: company workspace, team space, shared workspace

**Meeting**: One capture session and its evidence. A `Meeting` owns `TranscriptSegment`, `MeetingNote`, `MeetingSummary`, and `SpeakerAlias` records.

**Ask**: Evidence-backed question answering over saved meetings. An `AskAnswer` holds `AskClaim` values, and each claim cites `AskEvidence` retrieved from local FTS5 search.

**Local Dictation**: On-device speech-to-text that writes into the current application. It is a workspace feature, not part of a meeting.

**Voice grouping**: Per-recording acoustic grouping that produces anonymous labels such as `Speaker 1`. It keeps no identity profile and does not compare people across meetings.
_Avoid_: speaker identification, diarization, voice recognition

**Workstream**: The intended unit of persistent company work in Company Hub. It is a vision term. No implementation exists yet.

**Brand theme**: `Atrium`, `Ubundi`, or `First Motive`, selected through `BrandTheme`. Atrium is the default theme. These are theme identities, not separate products or tenants.

**Grounding**: The installation-owned company knowledge system that Atrium plans to reach through MCP. It is external and unbuilt.

## Architecture and boundaries

- `macos/Sources/Atrium/` owns scenes and views. `macos/Sources/AtriumCore/` owns data, audio, transcription, retrieval, language services, and updates. The dependency runs one way, from `Atrium` to `AtriumCore`.
- `AppStore` is the main-actor store for My Workspace. `CompanyHubStore` holds Company Hub state and reads through `CompanyHubProviding`. The default `DisconnectedCompanyHubService` returns nothing and throws `CompanyHubUnavailableError`, so every Company Hub screen shows an empty state.
- Company Hub screens never touch the local database. The local SQLite store is the private workspace store and must not become the shared database.
- The external Ask confirmation lives in `AppStore`: `AskPhase.confirming` blocks the request until `confirmExternalAsk()` approves that `ExternalAskDestination` for the session.
- The package declares no production Swift package dependencies. `CSQLite` is a system library.

## Runtime and data

- `~/Library/Application Support/Notive/meeting_minutes.sqlite` is the active database. Constants are in `Services/SQLiteDatabase.swift`.
- Recordings default to `~/Movies/notive-recordings/`.
- The bundle identifier stays `com.ubundi.meet`. Import from `~/Library/Application Support/com.ubundi.meet/` is additive and needs user confirmation.

## Workflows and verification

- `./script/build_and_run.sh run` builds and starts the application. See [docs/BUILDING.md](docs/BUILDING.md).
- `cd macos && swift test -Xswiftc -warnings-as-errors` is the default completion check for native changes. CI runs the same command, then `./script/build_and_run.sh --package` to verify the application bundle.
- `scripts/release.sh` is the only supported release path. See [docs/RELEASING.md](docs/RELEASING.md).

## Open questions

- `backend/`, `frontend/`, `dist/`, and `target/` can be present in a working copy but are untracked leftovers from the retired implementations. Treat them as derived output and do not restore them.
- Company Hub, workstreams, and the Grounding connection need accepted architecture decisions for backend, identity, authorization, sharing, and retention before implementation, because they cross the local-first boundary.

## Freshness

Last verified: 2026-08-14. Recheck after target moves, new stores or services, a Company Hub provider implementation, or a change to the database location.
