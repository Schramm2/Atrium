# Local macOS Updates

Use this workflow when you are developing the Ubundi Meet fork on an Apple Silicon Mac. It builds the current checkout and replaces the local application without creating a tag, publishing a GitHub release, or running the release workflow.

## Update the installed app

Close Ubundi Meet before updating. The updater refuses to replace a running process so an active recording is not interrupted.

```bash
cd /path/to/ubundi-meet
./scripts/update-local-macos.sh
```

The script:

1. Reads the current branch and commit.
2. Builds the frontend, Rust application, and llama-helper sidecar with Metal and CoreML detection.
3. Installs the fresh bundle at `/Applications/Ubundi Meet.app`.
4. Verifies the bundle name, version, and ad-hoc code signature.
5. Registers the application with macOS.
6. Records the installed commit in:

   ```text
   ~/Library/Application Support/com.ubundi.meet/installed-build.txt
   ```

The script includes uncommitted working-tree changes in the local build and prints them before building. Review the list if you expected a clean commit build.

## Verify the installed commit

```bash
cat "$HOME/Library/Application Support/com.ubundi.meet/installed-build.txt"
git rev-parse HEAD
```

The `commit` value in the receipt should match `git rev-parse HEAD`.

## Data directory after the rebrand

The Ubundi Meet bundle identifier is `com.ubundi.meet`. On macOS, the current data directory is:

```text
~/Library/Application Support/com.ubundi.meet/
```

Older Meetily installations used:

```text
~/Library/Application Support/com.meetily.ai/
```

Keep the legacy directory until the current app shows your meetings, transcripts, models, and preferences. Do not copy or replace SQLite files while the app is running. Make a dated backup before a manual migration.

## Expected local-build warning

The Tauri package step can report that `TAURI_SIGNING_PRIVATE_KEY` is missing. This prevents updater signatures and GitHub release artifacts, but it does not prevent the local `.app` from being built and installed. The local updater accepts this warning only when it finds a fresh app bundle.

To distribute updates to other computers or use the in-app updater, configure the signing key and use the GitHub release workflow. That is separate from this local development workflow.

## Build artifacts

The local build creates these files under `target/release/bundle/`:

- `macos/Ubundi Meet.app`
- `macos/Ubundi Meet.app.tar.gz`
- `dmg/Ubundi Meet_*.dmg`

The installed application is always copied from the fresh `.app` bundle, not from a previous DMG.
