# Releasing Notive

## Release model

Notive uses stable semantic versions in `macos/version.json`. The release tag must be the same version with a `v` prefix, such as `v0.5.0`.

The native release is Apple Silicon only. It uses the repository's internal ad-hoc macOS signing model and Sparkle Ed25519 signatures for update integrity. It is not Developer ID signed or notarized, so macOS shows a Gatekeeper warning on first installation. Users approve the trusted internal artifact with **System Settings → Privacy & Security → Open Anyway**.

Each ad-hoc build has a new code identity. After an install or update, users can need to approve Notive's privacy access again in **Notive → Settings → Permissions** and restart the app. This is an accepted constraint of the internal release model; the project does not require an Apple Developer account or certificate.

## One-time GitHub setup

Create a GitHub Actions environment named `release`. Add this repository or environment secret:

| Secret | Purpose |
| --- | --- |
| `SPARKLE_PRIVATE_KEY` | Base64 private seed used to sign the update ZIP, appcast, and release notes. It must match `SUPublicEDKey` in `script/build_and_run.sh`. |

Export the approved Notive key from the macOS Keychain to a secure temporary file:

```bash
macos/.build/artifacts/sparkle/Sparkle/bin/generate_keys \
  --account com.ubundi.meet \
  -x /secure/temporary/path/notive-sparkle-private-key
```

Copy the file contents into `SPARKLE_PRIVATE_KEY`, then remove the temporary file. Never commit or log the private key.

The repository must allow GitHub Actions read and write workflow permissions. The workflow uses the supplied `GITHUB_TOKEN` to create and publish the release.

## Release a version

1. Update `macos/version.json` and `CHANGELOG.md`.
2. Run the release checks:

   ```bash
   node scripts/check-release-version.mjs
   node scripts/check-swift-migration-inventory.mjs --check
   cd macos
   swift test -Xswiftc -warnings-as-errors
   cd ..
   ./script/build_and_run.sh --package
   ```

3. Commit the release preparation and push it to `main`.
4. Confirm that the release commit is on `main` and the intended worktree is clean.
5. Create and push an annotated tag:

   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```

6. Wait for the **Release** workflow. It builds the native Swift application, embeds Sparkle, creates the ZIP and DMG, generates a signed `appcast.xml`, validates all artifacts, creates a draft GitHub Release, and publishes it only after validation passes.
7. Install the DMG on a test Mac. Complete the **Open Anyway** flow, approve the required Notive permissions, and restart Notive. From the prior native version, select **Check for Updates…** and confirm download, Sparkle signature validation, replacement, relaunch, and permission reapproval where macOS requires it.

Never move or replace a published tag. Publish a later patch version for a correction.

## Published artifacts

Each release includes:

- `Notive-<version>-arm64.dmg` for first installation.
- `Notive-<version>.zip` as the Sparkle update archive.
- `appcast.xml` with signed update metadata and a signed-feed block.

Sparkle checks the HTTPS appcast once per day by default. Users can turn automatic checks off in Settings and can run a manual check from Settings or the application menu.

## Failure handling

If validation fails, the workflow does not publish a release. Fix the cause in a new commit, increase the patch version, and use a new tag. Do not edit a published appcast or archive because either change invalidates its signature.
