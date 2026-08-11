# Building Notive from Source

The native Swift application in `macos/` is the release candidate. The Tauri application in `frontend/` remains available as the migration baseline until the native cutover is accepted. The Python code in `backend/` is archived.

## Requirements

- macOS 14 or later
- Xcode with the macOS SDK and Swift 6.1 or later
- SQLite supplied by macOS

Swift Package Manager resolves Sparkle 2.9.2 from its official GitHub release. No JavaScript, Rust, model-runtime, or Python dependency is required for the native application.

## Run in development

```bash
./script/build_and_run.sh run
```

The script builds `macos/`, creates `dist/Notive.app`, embeds Sparkle, applies an ad-hoc signature, and opens the exact bundle.

The internal build has no Apple Developer ID signature and is not notarized. On the first launch of a downloaded build, try to open Notive once, then open **System Settings → Privacy & Security** and select **Open Anyway**. Only override this warning for a Notive artifact that came from the repository's trusted release process. See [Apple's warning-flow guidance](https://support.apple.com/guide/mac-help/mh40616/mac).

An ad-hoc signature identifies one exact build. A rebuilt or updated Notive bundle can therefore ask for Microphone, Speech Recognition, Screen Recording, Notifications, and Accessibility again. Open **Notive → Settings → Permissions**, approve the required access, and restart Notive after Screen Recording or Accessibility changes.

## Build release artifacts

```bash
./script/build_and_run.sh --package
```

This creates:

- `dist/Notive.app`
- `dist/Notive-<version>.zip`, for signed Sparkle updates
- `dist/Notive-<version>-arm64.dmg`, for first installation

The version is read from `macos/version.json`.

## Tests

```bash
node scripts/check-swift-migration-inventory.mjs --check
cd macos
swift test -Xswiftc -warnings-as-errors
```

The inventory check extracts the active Tauri command registry and requires an explicit native disposition for all 189 registered commands.

The migration baseline remains available while `frontend/` is retained:

```bash
cd frontend
pnpm install --frozen-lockfile
pnpm run test:ask
pnpm run build
```
