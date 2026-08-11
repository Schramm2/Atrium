# Notive

Notive is the internal, privacy-first meeting and dictation application for Ubundi and First Motive. It is a native macOS application built with Swift 6.1 and SwiftUI.

Notive records microphone and system audio, transcribes speech on the Mac, stores meetings locally, and supports notes, summaries, playback, Local Dictation, and evidence-backed Ask responses. Meeting evidence leaves the Mac only after the user selects an external summary provider or confirms an external Ask request.

## Requirements

- macOS 14 or later
- Xcode with the macOS SDK
- Swift 6.1 or later
- GitHub CLI, authenticated with access to `Schramm2/notive`, for release updates

## Run

From the repository root:

```bash
./script/build_and_run.sh run
```

The script builds the release package, creates `dist/Notive.app`, applies an ad-hoc signature, and opens the application.

## Test

```bash
cd macos
swift test -Xswiftc -warnings-as-errors
```

## Package

```bash
./script/build_and_run.sh --package
```

This creates the versioned and stable internal DMGs in `dist/`. See [Build Notive](docs/BUILDING.md), [Release Notive](docs/RELEASING.md), and [Local macOS updates](docs/LOCAL_MACOS_UPDATES.md).

## Architecture

The `Notive` target owns native scenes and views. The `NotiveCore` target owns local data, audio, transcription, retrieval, and language services. See [System architecture](docs/architecture.md) and the accepted records in [docs/decisions](docs/decisions/).

The application keeps its compatible bundle identifier, `com.ubundi.meet`, and reads the existing database under `~/Library/Application Support/com.ubundi.meet/`.

## Privacy and notices

Read [Privacy](PRIVACY_POLICY.md), [License](LICENSE.md), and [Notices](NOTICE.md). Local Dictation includes work adapted from [Handy](https://github.com/cjpais/Handy); the scope is in [Handy attribution](docs/handy-attribution.md).
