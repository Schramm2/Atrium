# Releasing Atrium

## Release model

Atrium uses private GitHub Releases. A maintainer cuts a release locally with `scripts/release.sh`; there is no release workflow. CI builds and tests pushes to `main`.

To install the current checkout on this Mac without publishing anything, use [Local macOS updates](LOCAL_MACOS_UPDATES.md) instead.

The version lives in `macos/version.json`. The release script keeps it equal to the `vX.Y.Z` tag, the application bundle version, and the version shown in the UI.

The release is Apple Silicon only. It uses ad-hoc macOS signing and is not notarized. macOS can show a Gatekeeper warning on first installation. A rebuilt or updated application can also require users to approve privacy access again in **Atrium → Settings → Permissions**.

## Requirements

The maintainer Mac needs:

- Xcode with Swift 6.1 or later.
- GitHub CLI authenticated with release access to `Schramm2/Atrium`.
- A clean `main` worktree with all intended changes pushed.

Installed Macs also need GitHub CLI authenticated with read access to the repository. Atrium uses that session to check and download private releases.

## Verify before release

Run:

```bash
cd macos
swift test -Xswiftc -warnings-as-errors
cd ..
./script/build_and_run.sh --package
```

Confirm CI is green for the commit that you plan to release. The release script validates and packages the application but does not run the test suite.

## Dry run

Build and verify the intended version without changing Git or GitHub:

```bash
./scripts/release.sh X.Y.Z --dry-run
```

## Cut the release

From a clean `main` worktree, run:

```bash
./scripts/release.sh X.Y.Z
```

The script:

1. Validates the stable semantic version, branch, clean worktree, GitHub authentication, and release collision.
2. Updates `macos/version.json`, commits `chore: release vX.Y.Z`, and pushes `main`.
3. Builds and verifies `Atrium.app`, `Atrium-X.Y.Z-arm64.dmg`, `Atrium.dmg`, and the `Notive-X.Y.Z-arm64.dmg` compatibility asset.
4. Creates the private GitHub Release and `vX.Y.Z` tag with all three DMGs.

After release, check CI on the version commit. Install the DMG on a test Mac. From the prior version, run **Atrium → Check for Updates…** and confirm the download, replacement, relaunch, and displayed version.

Never move or replace a published tag. Correct a faulty release with a later patch version.

## Application update flow

Atrium runs an automatic release check at launch when the preference is enabled. Users can also check from Settings or the application menu.

The updater uses `gh release view` to compare the latest tag with the bundle version. When a user installs an update, it uses `gh release download`, mounts the versioned DMG, stages and verifies the application, replaces the running installation, and relaunches. Atrium installations use `/Applications/Atrium.app` and Atrium-named assets. Installations that predate the rebrand remain at `/Applications/Notive.app` and use the versioned Notive compatibility asset. A failed install restores the prior application.

If a check fails, confirm:

```bash
gh auth status
gh release view --repo Schramm2/Atrium
```

The updater does not use a separate Sparkle signature. Access depends on GitHub authentication, HTTPS, the private release boundary, and verification of the packaged app's ad-hoc code signature.
