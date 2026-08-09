# Notive desktop application

`frontend/` contains the supported Notive desktop application: a Next.js interface packaged with a Rust Tauri core. The archived Python backend is not required.

## Requirements

- macOS with Xcode Command Line Tools
- Rust 1.77 or later
- Node.js 20 or later
- pnpm 8

## Develop

```bash
pnpm install --frozen-lockfile
pnpm run tauri:dev
```

The development server uses `http://localhost:3118`. Tauri starts the native application after the server is ready.

## Build

```bash
pnpm run tauri:build
```

The workspace writes a macOS bundle under `../target/release/bundle/`.

## Tests

```bash
pnpm run test:ask
```

The remaining focused tests under `tests/` use Bun. Run a relevant test with `bun test <path>` when Bun is installed.

## Application areas

- Meeting capture, transcription, local SQLite storage, summaries, Ask retrieval, and cited transcript navigation.
- Local Dictation with a global shortcut, the configured microphone, local transcription, and macOS Accessibility-based insertion.
- Settings for transcription, recording, summaries, notifications, Local Dictation, appearance, and local-data locations.

See the [source-build guide](../docs/BUILDING.md), [architecture](../docs/architecture.md), and [design contract](DESIGN.md).
