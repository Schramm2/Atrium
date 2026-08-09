# CLAUDE.md

Use [AGENTS.md](AGENTS.md) for the shared repository contract. This file gives Claude Code a compact map of the current application.

## Supported application

Notive is the macOS Tauri desktop app in `frontend/`:

- Next.js and TypeScript provide the interface.
- Rust in `frontend/src-tauri/src/` provides audio capture, local transcription, SQLite storage, summaries, Ask retrieval, notifications, and Local Dictation.
- The Python/FastAPI, Docker, and standalone whisper-server material in `backend/` is archived. Do not use it for new implementation, setup, deployment, or supported-app triage.

## Develop and verify

Run desktop commands from `frontend/`:

```bash
pnpm install --frozen-lockfile
pnpm run tauri:dev
pnpm run tauri:build
pnpm run test:ask
```

The development server listens on `http://localhost:3118`. Tests outside `tests/ask/` use Bun; run the smallest relevant file with `bun test <path>` when Bun is installed.

## Architecture

The interface calls Rust through Tauri commands and receives updates through Tauri events. Keep interface contracts close to their Rust command or event owner.

- `audio/` owns recording, devices, import, re-transcription, transcription providers, and speaker labels.
- `database/` owns local SQLite storage, FTS retrieval, meetings, transcripts, summaries, settings, and speaker aliases.
- `ask/` performs bounded local evidence retrieval and validates cited response claims.
- `dictation/` owns the macOS global shortcut, local capture and transcription, accessibility checks, and text insertion.
- `summary/` owns local and configured-provider summary generation.
- `notifications/` owns local notification settings and delivery.

The current macOS Whisper dependency enables Metal and Core ML. The public package scripts expose optional targeted Metal and Core ML checks; CUDA, Vulkan, ROCm, and Linux GPU build instructions are not maintained.

## Data boundary

Meeting recording, transcription, SQLite storage, search, citations, speaker aliases, and Local Dictation run locally. Built-in AI and loopback Ollama stay local. External summary providers receive the content required for the summary you request. The first external Ask request in an app session requires confirmation before it receives the question and selected evidence.

The app retains `com.ubundi.meet` where required for existing data and release compatibility. Use `Notive` for prose and new user-facing labels.

## Useful files

- [Application entry and command registration](frontend/src-tauri/src/lib.rs)
- [Tauri configuration](frontend/src-tauri/tauri.conf.json)
- [Main meeting view](frontend/src/app/page.tsx)
- [Local Dictation view](frontend/src/app/dictation/page.tsx)
- [Settings view](frontend/src/app/settings/page.tsx)
- [Architecture documentation](docs/architecture.md)
