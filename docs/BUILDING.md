# Build Notive

Notive is a native macOS application. Swift Package Manager builds the application in `macos/`.

## Requirements

- macOS 14 or later
- Xcode with the macOS SDK and Swift 6.1 or later
- SQLite supplied by macOS

Swift Package Manager resolves Sparkle 2.9.2 from its official GitHub release. No JavaScript, Rust, model-runtime, or Python toolchain is required.

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

## Test

```bash
cd macos
swift test -Xswiftc -warnings-as-errors
```

Run `./script/build_and_run.sh --verify` when a change affects bundle resources, signing, permissions, or startup.
