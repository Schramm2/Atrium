# Build Atrium

Atrium is a native macOS application. Swift Package Manager builds the application in `macos/`.

## Requirements

- macOS 14 or later
- Xcode with the macOS SDK and Swift 6.1 or later
- SQLite supplied by macOS
- GitHub CLI for private release checks and installation

## Run in development

```bash
./script/build_and_run.sh run
```

The script builds `macos/`, stages the application as the hidden bundle `dist/.Atrium.app`, applies an ad-hoc signature, and opens that exact bundle. Hiding the development bundle prevents Launchpad from presenting it as a second installed copy of Atrium.

The internal build has no Apple Developer ID signature and is not notarized. On the first launch of a downloaded build, try to open Atrium once, then open **System Settings → Privacy & Security** and select **Open Anyway**. Only override this warning for an Atrium artifact that came from the repository's trusted release process. See [Apple's warning-flow guidance](https://support.apple.com/guide/mac-help/mh40616/mac).

An ad-hoc signature identifies one exact build. A rebuilt or updated Atrium bundle can therefore ask for Microphone, Speech Recognition, Screen Recording, Notifications, and Accessibility again. Open **Atrium → Settings → Permissions**, approve the required access, and restart Atrium after Screen Recording or Accessibility changes.

## Inspect a running build

The same script starts Atrium with an inspection mode attached:

```bash
./script/build_and_run.sh --logs       # start Atrium and stream its process log
./script/build_and_run.sh --telemetry  # start Atrium and stream the com.ubundi.meet subsystem
./script/build_and_run.sh --debug      # start the application binary under lldb
```

`--telemetry` shows the records that `DiagnosticLogger` writes, which is the shortest route to a failed store, service, or permission operation. `--debug` runs the binary directly, so it has no bundle resources.

## Build release artifacts

```bash
./script/build_and_run.sh --package
```

This creates:

- `dist/.Atrium.app`, the hidden staging bundle
- `dist/Atrium-<version>-arm64.dmg`, for first installation
- `dist/Atrium.dmg`, as the stable latest-release asset

The version is read from `macos/version.json`.

### Installer window

Both disk images mount as the volume `Atrium <version>` and open an icon-view window that shows the Atrium bundle beside an Applications shortcut. `script/dmg_background.swift` draws the window background from `macos/BrandAssets/` at 1x and 2x. Packaging then mounts a writable image, lets Finder record the window size, icon places, and background, and converts the result to the compressed disk image.

Finder scripting must be available for the layout step. When it is not, packaging reports the plain disk image and the release still completes.

## Test

```bash
cd macos
swift test -Xswiftc -warnings-as-errors
```

Run `./script/build_and_run.sh --verify` when a change affects bundle resources, signing, permissions, or startup.
