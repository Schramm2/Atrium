# Native Swift migration ledger

## Purpose

This ledger tracks the behavior of the existing Tauri application and its native macOS replacement. The Tauri source remains in `frontend/` until every release-blocking row is verified. Both applications use the same bundle identifier and database path, so do not run them at the same time.

## Compatibility contract

- Keep the bundle identifier `com.ubundi.meet` and the existing SQLite path in `~/Library/Application Support/com.ubundi.meet/`.
- Do not move, rewrite, or delete existing user data during the migration.
- Keep Notive, Ubundi, and First Motive product identities.
- Keep recording, transcription, evidence retrieval, and default answer generation on the Mac.
- Use Apple system frameworks before adding a production dependency.
- Keep the Tauri application buildable until the native release path is accepted.

## Legacy inventory snapshot

The supported Tauri application exposes six primary Next.js routes and 189 registered Rust commands. This inventory uses `frontend/src/app/`, `frontend/src/components/`, and the `tauri::generate_handler!` registry in `frontend/src-tauri/src/lib.rs` as the authoritative baseline. Old or backup Rust files that are not registered are not part of the supported command surface.

### User interface

| Legacy surface | Main source | Native disposition | Status |
|---|---|---|---|
| Home, recording controls, live transcript, status overlays, and import drop target | `src/app/page.tsx`, `src/app/_components/` | `HomeView`, `SidebarView`, `ContentView`, and `AppStore` | Verified |
| Ask, scope controls, cited answers, cancellation, and citation navigation | `src/app/ask/page.tsx`, `src/components/AskNotive/` | `AskView`, local FTS retrieval, and evidence-bound answers | Verified |
| Local Dictation and result display | `src/app/dictation/page.tsx`, `src/components/Dictation/` | `DictationView`, `GlobalDictationShortcut`, and on-device speech | Implemented; final Computer Use interaction is tool-bound |
| Meeting transcript, playback, summary, notes, title, aliases, retranscription, and deletion | `src/app/meeting-details/`, `src/components/MeetingDetails/` | `MeetingDetailView` and `AppStore` | Verified |
| Direct meeting notes editor | `src/app/notes/[id]/page.tsx` | `MeetingNotesView` and the Notes tab in `MeetingDetailView` | Verified |
| Settings, model configuration, appearance, permissions, recording, notifications, updates, and About | `src/app/settings/page.tsx`, settings components | Native `Settings` scene and `SettingsView` tabs | Verified |
| Onboarding | `src/components/onboarding/` | Native three-step `OnboardingView` | Verified |
| Import picker, drag import, validation, progress, cancellation, and rollback | `src/components/ImportAudio/`, `src/hooks/useImportAudio.ts` | Native file importer and drop destination with transactional rollback | Verified |
| Tray, application menu, single instance, and updater prompts | Rust tray and Tauri plugins | `MenuBarExtra`, SwiftUI commands, one native process, and Sparkle | Verified |

### Registered Rust command surface

| Command group in the 189-command registry | Native disposition | Status |
|---|---|---|
| App icon, recording lifecycle, recording state, device selection, metering, transcript history, and playback-device diagnostics | Native SwiftUI state, `LiveMeetingCaptureService`, `AudioDeviceService`, and `AppStore` | Verified; Bluetooth-specific controls intentionally removed |
| Dictation start, stop, cancel, status, and preferences | `GlobalDictationShortcut`, `DictationView`, and `AppStore` | Implemented; Computer Use disconnects when the Dictation view is selected |
| Whisper, Parakeet, downloaded transcription models, and parallel worker/resource commands | Apple on-device Speech; no model download or worker-pool surface | Intentionally changed |
| Audio checkpoints and transcript recovery commands | Incremental native audio files and meeting recovery through Retranscribe | Intentionally changed |
| Ollama, OpenAI, Anthropic, Groq, OpenRouter, and OpenAI-compatible model/configuration commands | `AIConfiguration`, `LanguageProviderService`, `ProviderModelService`, and Keychain secrets | Implemented; live calls are configuration-bound |
| Meeting CRUD, transcript search, Ask retrieval/generation/cancellation, transcript configuration, summaries, templates, notes, and speaker aliases | `SQLiteDatabase`, `LocalIntelligenceService`, summary preferences, and `AppStore` | Verified |
| Recording preferences and selectable legacy audio backends | Native recording folder, audio retention, CoreAudio input, and ScreenCaptureKit system audio | Verified; backend selector intentionally removed |
| Notification settings, permission, delivery, DND, consent, readiness, and statistics | Native notification preferences, foreground presentation, test delivery, and `NotificationService`; native pause replaces manual DND/statistics controls | Verified; statistics intentionally changed |
| System-audio capture, monitoring, and Screen Recording permission commands | `SystemAudioCaptureService` and native permission links | Verified on hardware |
| Legacy/Homebrew database detection and import, fresh initialization, database folder, and model folder | Existing `com.ubundi.meet` SQLite data opens in place; database folder remains accessible | Intentionally changed or verified |
| Onboarding state and System Settings navigation | `@AppStorage`, `OnboardingView`, and native settings URLs | Verified |
| Retranscription and audio import lifecycle commands | `AppStore`, `SpeechTranscriptionService`, file importer, and cancellation | Verified |
| Developer console, backend debug/profile helpers, resource diagnostics, and generic external-URL commands | No native product workflow | Intentionally changed |

The grouped table is the concise disposition summary. [TAURI_COMMAND_INVENTORY.md](TAURI_COMMAND_INVENTORY.md) lists all 189 active command names with an explicit native disposition and status. `node scripts/check-swift-migration-inventory.mjs --check` extracts the authoritative registry and fails if a command is added, removed, duplicated, left unmatched, matched by more than one disposition, or not regenerated.

## Capability ledger

| Capability | Native implementation | Verification | Status |
|---|---|---|---|
| macOS application shell | SwiftUI `WindowGroup`, Settings scene, menu-bar controls, commands, and `NavigationSplitView` | Release bundle starts | Verified |
| First-run setup | Native three-step onboarding with optional microphone, speech, and screen-recording access | Completed with Computer Use without accepting permission prompts | Verified |
| Existing meetings | Reads the existing database without migration | Existing meetings and transcripts opened in the native bundle | Verified |
| Meeting storage | SQLite C API with compatible meetings, transcripts, notes, summaries, aliases, and FTS5 tables | Round-trip, retrieval, replacement, and cascade tests | Verified |
| Meeting recording | `AVAudioEngine` microphone capture with pause, resume, metering, and a live transcript preview | Real microphone recording, meter, timer, pause, resume, stop, transcript, and saved files passed in the native bundle | Verified |
| System audio | `ScreenCaptureKit` capture with pause and resume | A disposable recording captured a 48-second system track with real signal and created a mixed playback file | Verified |
| Playback file | `AVFoundation` combines microphone and system tracks into `audio.m4a` | Native recording created the mixed file and interactive playback passed | Verified |
| Final transcription | Apple on-device Speech recognition creates timed local transcript rows | Timing and persistence tests | Verified |
| Live transcription | Apple on-device Speech recognition updates the meeting while recording | Build verification; hardware test pending | Implemented |
| Audio import | Native file importer and window drop target copy audio to a meeting folder and transcribe it locally. Cancellation removes partial local data and keeps the source | Successful import and cancellation store tests; native file selection exercised | Verified |
| Retranscription | Replaces transcript rows from the saved primary audio file | Replacement test | Verified |
| Transcript playback | Native `AVAudioPlayer` controls and seeking | Interactive recording playback passed | Verified |
| Speaker aliases | Meeting-scoped alias editing uses the compatible alias table | Persistence and cascade tests | Verified |
| Automatic voice grouping | Native per-recording acoustic feature clustering assigns anonymous `Speaker N` labels without retaining voice profiles | Clustering tests; permission-bound recorded-voice test pending | Implemented |
| Meeting notes | Native editor reads and writes compatible Markdown note rows | Round-trip test | Verified |
| Summaries | Apple Intelligence runs on device when available; a deterministic local extractive summary is the fallback. Native templates, all legacy output languages, per-meeting metadata, custom instructions, and automatic generation are supported | Fallback, instruction, and metadata compatibility tests | Verified |
| Ask retrieval | Bounded local FTS5 retrieval, meeting scope, neighboring context, and local citation navigation | Scoped retrieval test | Verified |
| Ask answers | Apple Intelligence runs on device when available; every claim is bound to retrieved evidence. A local extractive answer is the fallback | Citation fallback test and cited on-device native UI answer | Verified |
| Remote Ask confirmation | The first remote Ask for each provider requires evidence-sharing confirmation; later requests to that provider in the same app session do not ask again | Provider-session boundary tests and legacy Ask tests | Verified |
| Optional AI providers | Native Ollama, OpenAI, Anthropic, Groq, OpenRouter, and OpenAI-compatible clients use Keychain-backed secrets. Remote Ask evidence requires confirmation | Local or remote boundary tests; live provider calls are configuration-bound | Implemented |
| Local Dictation | The selected Option-Space or Command-Shift-D shortcut starts on-device transcription. Notive copies the result and uses Accessibility for automatic paste | All permissions are allowed, but Computer Use disconnects when this view is selected, so final speech-and-paste interaction needs a manual check | Blocked |
| Notifications | Native local notifications cover recording start, pause, resume, stop, transcript completion, import completion, errors, and an explicit test. Sound and manual pause settings are honored. Foreground presentation uses the notification-center delegate | Final bundle queued the test notification and reported successful delivery; focused preference tests pass | Verified |
| Appearance | Native light/dark system behavior and Ubundi or First Motive theme and icon selection | Exact native bundle inspected with Computer Use | Verified |
| Settings | Native General, Permissions, Appearance, Recording, Dictation, Transcription, Summary, and About tabs. Recording location, saved-audio cleanup, notification pause, and legal notices are included | Exact native settings inspected with Computer Use; preference migration and cleanup tests pass | Verified |
| Update checks | Sparkle provides automatic and manual checks against the signed GitHub Release appcast | Framework integration, settings, bundle keys, signed appcast, and update installation pass | Verified |
| Signed in-app installation | Sparkle verifies the signed feed and ZIP archive with the Notive Ed25519 public key | A temporary 0.4.9 bundle installed and relaunched the production-key-signed 0.5.0 archive | Verified |
| Packaging | SwiftPM creates the executable; `script/build_and_run.sh` creates the `.app`, signed ZIP, and arm64 DMG | Release build, launch, nested code-signature, ZIP extraction, and DMG verification | Verified |
| Legal notices | The application bundle includes the project license, notices, and complete Sparkle license | Release build and workflow assert all three resources | Verified |
| Non-blocking errors | A dismissible banner reports errors without blocking the main window | Warnings-as-errors build and responsive Home inspection | Verified |
| Permission callback safety | Speech permission completion resumes outside the SwiftUI main actor and returns to the main actor before state changes | Crash report root cause removed; warnings-as-errors build passes | Verified |

## Detailed legacy disposition

| Legacy area | Native disposition | Status |
|---|---|---|
| Window, tray, app menu, Settings, About, theme, and icon | Rebuilt with SwiftUI scenes, `MenuBarExtra`, commands, and native preferences | Verified |
| Meeting CRUD, FTS search, notes, summaries, aliases, and existing SQLite data | The native app opens the supported database in place and keeps its compatible tables | Verified |
| Microphone recording, input selection, levels, timer, pause, resume, and stop | Rebuilt with `AVAudioEngine`, CoreAudio device selection, and observable recording state | Verified |
| System audio recording | Rebuilt with ScreenCaptureKit and mixed with the microphone recording | Verified with a disposable hardware recording and non-silent system track |
| Bluetooth reconnect commands and selectable recording backends | Replaced by CoreAudio and ScreenCaptureKit routing. The old extra backend controls are not required in the native stack | Intentionally changed |
| IndexedDB transcript recovery and audio checkpoint commands | Native capture writes the meeting row and audio file during recording. An interrupted meeting remains visible and offers Retranscribe from saved audio | Intentionally changed |
| Whisper, Parakeet, model downloads, resource sizing, and parallel worker controls | Replaced by Apple on-device Speech. Notive no longer distributes transcription models or manages worker pools | Intentionally changed |
| Transcription languages | The native picker keeps the legacy language choices that Apple Speech can resolve. System language replaces legacy Auto Detect | Implemented |
| Auto Detect and Translate to English | Apple Speech does not provide the old Whisper translation mode. The native app transcribes in the selected or system language | Intentionally changed |
| Summary templates, automatic generation, custom prompt, and output language | Rebuilt with native templates, custom instructions, all legacy output language codes, and per-meeting `metadata.json` compatibility | Verified |
| Detected summary-language cache | Auto asks the selected model to use the transcript's main language. The old second detected-language cache is not required | Intentionally changed |
| Downloaded built-in summary models | Replaced by Apple Intelligence when available and a deterministic on-device fallback | Intentionally changed |
| Ollama, OpenAI, Anthropic, Groq, OpenRouter, and custom OpenAI providers | Rebuilt with native model listing, connection checks, Ollama pull/delete, Keychain secrets, and a remote-evidence confirmation boundary | Implemented; live checks require local provider configuration |
| Ask retrieval, answer generation, scope, cancellation, citations, and navigation | Rebuilt with bounded FTS5 evidence, local generation by default, operation cancellation, and source navigation | Verified |
| File-picker import, drag import, progress, and cancellation | Rebuilt with native file import and window drop handling. Cancellation rolls back the meeting, copied file, and folder | Verified |
| Transcript copy, timed playback, seeking, speaker labels, retranscription, and cancellation | Rebuilt with AppKit pasteboard, AVFoundation playback, compatible aliases, and Apple Speech | Verified |
| Recording recovery | The meeting detail view identifies saved audio with no transcript and offers Retranscribe | Implemented |
| Notifications, sound, pause, and system permission | Rebuilt with UserNotifications. Native pause replaces the old manual DND state | Verified, including foreground test delivery |
| Onboarding and microphone, speech, screen-recording, notification, and Accessibility controls | Rebuilt with native permission APIs and direct System Settings links | All five permissions report Allowed on the final ad-hoc bundle |
| Dictation preferences, global shortcuts, local transcription, clipboard, and paste | Rebuilt with event monitors, an Accessibility event tap, Apple Speech, and the macOS pasteboard | Implemented; final Computer Use speech-and-paste interaction is tool-blocked |
| Sparkle checks, signed appcast, update install, release ZIP, and DMG | Rebuilt and exercised with a signed 0.4.9 to 0.5.0 installation | Verified |
| Homebrew and archived Python database import | Not part of the supported Tauri-to-Swift data path. The current SQLite database opens in place | Intentionally changed |
| Developer console, backend debug, profile, and resource diagnostic commands | These internal or unused commands are not user workflows in the native app | Intentionally changed |
| File export | The supported interface provided transcript and summary copy actions, not a separate file export workflow. Native copy actions remain available | Verified |

## Baseline receipt

The retained Tauri baseline passed four Ask tests, 224 application Rust tests with three ignored tests, two helper tests, two documentation tests, and the Next.js production build. The original application walkthrough covered Home, Ask, Dictation, meeting details, transcript timing, summaries, notes, settings, import, and recording controls.

The native suite passes 29 tests across six suites with warnings treated as errors. It covers SQLite compatibility, FTS5 Ask retrieval, citation binding, deterministic summaries, summary instructions, per-meeting language metadata, transcript replacement, timing conversion, deletion cascades, audio-file selection, recording preference migration, safe audio cleanup, successful import, cancelled-import rollback, concurrent capture state, provider model parsing, per-provider remote Ask confirmation, notification pause, critical-delivery rules, authorization variants, and local or remote provider boundaries. Computer Use verified onboarding, Home, saved meetings, transcripts, summaries, Ask, appearance, Settings, recording controls, notification test delivery, and all permission controls in the exact native bundle. Microphone recording, final on-device transcription, saved audio, playback, system-audio capture, and mixed output passed on hardware. Dictation remains the only tool-bound interactive check because selecting its view closes the Computer Use native pipe while Notive stays running.

### Verification run: 2026-08-11

- `swift test --package-path macos -Xswiftc -warnings-as-errors`: 29 tests in six suites passed.
- `pnpm run test:ask`: four tests passed.
- `pnpm run build`: the 13-route Next.js production build passed.
- `cargo test --manifest-path src-tauri/Cargo.toml --lib`: 224 tests passed and three hardware tests were ignored.
- `cargo test -p llama-helper`: two tests passed.
- `cargo test --workspace --doc`: two documentation tests passed.
- `./script/build_and_run.sh --verify`: the release bundle built, received its local ad-hoc signature, launched, and passed process verification.
- `./script/build_and_run.sh --package`: the final release build created `Notive-0.5.0.zip` and `Notive-0.5.0-arm64.dmg`. Deep code-signature verification, ZIP integrity, DMG checksum, and bundled legal-resource checks passed.
- `node scripts/check-release-version.mjs`: release metadata passed for `v0.5.0`.
- `node scripts/check-swift-migration-inventory.mjs --check`: all 189 active Rust commands have one exact disposition: 86 verified, 14 implemented, 83 intentionally changed, and six blocked Dictation commands awaiting the spoken check.
- `git diff --check`, shell syntax checks, and Node syntax checks passed.
- Computer Use on the exact `dist/Notive.app` bundle passed Home, Ask, Meeting Notes, an existing meeting, transcript, summary, notes, and every Settings tab. It confirmed the existing database path and Notive 0.5.0 identity. Opening Dictation again closed the Computer Use accessibility pipe.
- A focused parity slice changed remote Ask confirmation from every request to once per provider per app session, matching the legacy contract. Native provider tests and the four legacy Ask tests passed after the change.
- The complete legacy baseline was rerun after that slice: four Ask tests, 224 Rust tests with three ignored, two helper tests, two documentation tests, and the Next.js production build passed again.
- Microphone, Speech Recognition, Screen Recording, Notifications, and Accessibility all report Allowed on the final local bundle after the accepted ad-hoc reapproval and restart flow.
- A disposable hardware recording created `microphone.wav`, a 48.06-second `system-audio.m4a`, and mixed `audio.m4a`. The system track measured -27.9 dB mean and -6.3 dB peak. The disposable meeting and its exact recording folder were deleted after verification.
- The notification slice added foreground banner, list, and sound presentation plus a Settings test control. The final bundle reported `Test notification sent`; four new tests cover disabled categories, pause behavior, critical/test bypass, and macOS authorization variants.
- The complete retained baseline passed again after the notification slice: four Ask tests, 224 Rust tests with three ignored, two helper tests, two documentation tests, and the 13-route Next.js production build.
- `security find-identity -v -p codesigning` reports zero valid identities. This is an accepted product decision: releases remain ad-hoc signed and users reapprove macOS privacy access after builds whose CDHash changes.
- The final global Dictation speech-and-paste check was prepared in a blank unsaved TextEdit document. It was deferred because no spoken test was possible in the user's current environment; the blank document was closed without saving.

## Ad-hoc operating decision

Notive intentionally ships without an Apple Developer ID certificate or notarization. Sparkle's Ed25519 signature protects update integrity, while macOS presents the first-open warning for the ad-hoc application. Users approve a trusted internal artifact with **Privacy & Security → Open Anyway** and reapprove Notive permissions after an update when macOS treats the new CDHash as a new code identity. An identifier-only ad-hoc designated requirement was rejected because another application could copy it and inherit privacy grants.

## Cutover rule

Do not change the root development guide, release workflow, or supported-application statement until all release blockers are resolved and the final native Computer Use walkthrough passes.
