# Ubundi Meet Agent Guide

## Product identity

This repository builds **Ubundi Meet**, a privacy-first, local-first AI meeting assistant. Use `Ubundi Meet` in prose and user-facing labels. Use `ubundi-meet` for repository, package, and artifact names.

The supported application is the Tauri desktop app in `frontend/`, with a Rust core and a Next.js interface. The `backend/` directory is an archived Python/FastAPI implementation. Do not use it for new development, installation, deployment, or supported-app issue triage.

## Attribution and licensing

Keep [LICENSE.md](LICENSE.md) and [NOTICE.md](NOTICE.md) with distributed source and substantial copies. Do not add old product branding to documentation, user interfaces, paths, package names, or endpoints.

## Development

Run desktop-app commands from `frontend/`:

```bash
pnpm install
pnpm run tauri:dev
```

Use the existing Rust, TypeScript, and documentation style. Verify the smallest relevant check after a change.
