# Releasing Notive

## Release model

Notive uses stable semantic versions: `X.Y.Z`.

- Increase `X` for an incompatible change.
- Increase `Y` for a compatible feature.
- Increase `Z` for a compatible fix.

The version must be identical in these files:

- `frontend/package.json`
- `frontend/src-tauri/Cargo.toml`
- `frontend/src-tauri/tauri.conf.json`

`frontend/src-tauri/tauri.conf.json` is the Tauri application version. The release tag must be `vX.Y.Z`, for example `v0.5.0`.

## One-time GitHub setup

Create a GitHub Actions environment named `release`. Require a maintainer approval for this environment. The release job needs these repository or environment secrets:

| Secret | Scope | Purpose |
| --- | --- | --- |
| `TAURI_SIGNING_PRIVATE_KEY` | Repository or `release` environment | Signs Tauri updater bundles. It must match the public updater key in `tauri.conf.json`. |
| `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` | Repository or `release` environment | Unlocks the updater signing key. |

Notive uses the configured ad-hoc macOS signing identity (`-`). No Apple certificate or notarization credentials are needed.

## macOS trust warning

The release workflow verifies the ad-hoc signature and the Tauri updater signature. It does not notarize the application. macOS Gatekeeper can show a warning when users install the DMG or open Notive for the first time. This is expected for this internal distribution model. Users must approve the application through macOS Privacy & Security when required.

The Tauri updater still verifies downloaded updates with `TAURI_SIGNING_PRIVATE_KEY`; do not remove or replace that key without updating the public key in `tauri.conf.json`.

The repository must allow GitHub Actions read and write workflow permissions. The release workflow uses the supplied `GITHUB_TOKEN` to create a release and upload its assets.

## Release a version

1. Update the three version files and add release notes to `CHANGELOG.md`.
2. Run the checks:

   ```bash
   cd frontend
   pnpm run version:check
   pnpm run test:ask
   ```

3. Commit the release preparation and push it to `main`.
4. Confirm that `main` is clean and the commit is the intended release commit.
5. Create and push an annotated tag:

   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```

6. Approve the `release` environment when GitHub asks.
7. Wait for the **Release** workflow to finish. It creates a draft release, builds the ad-hoc signed Apple Silicon macOS application, creates the updater archive and signature, verifies the bundle and updater manifest, then publishes the release.
8. Download the DMG from the published release and install it on a test Mac. In Notive, select **Check for Updates** from the About page. Confirm that the prior release detects, downloads, installs, and restarts into this version.

Never move, replace, or delete a published version tag. Release a later patch version instead.

## What users receive

Each published release includes:

- An ad-hoc signed DMG for first-time installation. macOS can show a Gatekeeper warning.
- A signed `.app.tar.gz` archive and `.sig` file for the Tauri updater.
- `latest.json`, the signed-update manifest that Notive checks at startup and once per day while open.

Notive asks for confirmation before it downloads and installs an update. Users can turn off automatic checks in Preferences and can check manually from the About page.

The current release channel supports Apple Silicon Macs (`darwin-aarch64`). Do not publish a release for another architecture until its signed updater artifact is also included in `latest.json`.

## Failure handling

If the workflow fails before publication, the GitHub Release stays a draft and no installed Notive application receives it. Fix the cause in a new commit, increase the patch version, and push a new tag. Do not reuse the failed tag.

If a published release has a defect, publish a new patch release. Do not edit `latest.json` by hand: the Tauri action creates it from the signed archive and its signature.
