# Building Notive from Source

The supported development target is macOS. The application is a Tauri desktop app in `frontend/`; the Python code in `backend/` is archived and is not part of the build.

## Requirements

- macOS with Xcode Command Line Tools
- Rust 1.77 or later
- Node.js 20 or later
- pnpm 8

Install project dependencies from the frontend directory:

```bash
cd frontend
pnpm install --frozen-lockfile
```

## Run in development

```bash
pnpm run tauri:dev
```

This starts Next.js at `http://localhost:3118` and opens the Tauri app.

## Build a local bundle

```bash
pnpm run tauri:build
```

The workspace writes the macOS bundle beneath `target/release/bundle/`. The repository's local installed-app updater is currently unavailable; see [Local macOS Updates](LOCAL_MACOS_UPDATES.md).

## Tests

Run the focused frontend check suite from `frontend/`:

```bash
pnpm run test:ask
```

Other tests in `frontend/tests/` use Bun. Run a relevant file with `bun test <path>` when Bun is installed.

## Acceleration

The current macOS build enables Metal and Core ML in the macOS dependency configuration. See [GPU Acceleration](GPU_ACCELERATION.md).
