# Atrium

Atrium is the internal, privacy-first company intelligence workspace for Ubundi and First Motive. It is a native macOS application built with Swift 6.1 and SwiftUI.

Atrium brings company context, agents, approved shared knowledge, and private local work into one workspace. It records microphone and system audio when needed, transcribes speech on the Mac, stores meetings locally, and supports notes, summaries, playback, Local Dictation, and evidence-backed Ask responses. Meeting evidence leaves the Mac only after the user selects an external summary provider or confirms an external Ask request.

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

The script builds the release package, stages the hidden bundle `dist/.Atrium.app`, applies an ad-hoc signature, and opens the application.

## Test

```bash
cd macos
swift test -Xswiftc -warnings-as-errors
```

## Package

```bash
./script/build_and_run.sh --package
```

This creates the versioned and stable internal DMGs in `dist/`. See [Build Atrium](docs/BUILDING.md), [Release Atrium](docs/RELEASING.md), and [Local macOS updates](docs/LOCAL_MACOS_UPDATES.md).

## Architecture

The `Atrium` target owns native scenes and views. The `AtriumCore` target owns local data, audio, transcription, retrieval, and language services. See [System architecture](docs/architecture.md) and the accepted records in [docs/decisions](docs/decisions/). [Interface](FRONTEND.md) covers how screens and state are built, and [Design](DESIGN.md) covers how they must look.

Atrium is a private company intelligence workspace that connects conversations, shared knowledge, people, and agents while keeping private work local. See [Product vision](docs/product-vision.md) for the product model, privacy boundary, and planned Grounding integration.

The application keeps its compatible bundle identifier, `com.ubundi.meet`, and stores active data under `~/Library/Application Support/Notive/`. It can restore compatible data from the earlier `~/Library/Application Support/com.ubundi.meet/` folder without changing the earlier copy.

## Privacy and notices

Read [Privacy](PRIVACY_POLICY.md), [License](LICENSE.md), and [Notices](NOTICE.md). Local Dictation includes work adapted from [Handy](https://github.com/cjpais/Handy); the scope is in [Handy attribution](docs/handy-attribution.md).
