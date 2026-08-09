# Dictation verification

This specification defines the minimum evidence for local dictation in Notive. Run commands from `frontend/`. Do not report a contract as verified until an automated test or the manual macOS check passes.

Handy is the primary behavior reference:

- [Shortcut coordinator](https://github.com/cjpais/Handy/blob/main/src-tauri/src/shortcut/handler.rs)
- [Clipboard restoration](https://github.com/cjpais/Handy/blob/main/src-tauri/src/clipboard.rs)
- [Receipt-sequenced macOS paste](https://github.com/cjpais/Handy/blob/main/src-tauri/src/paste_tx/macos.rs)
- [Build instructions](https://github.com/cjpais/Handy/blob/main/BUILD.md)

The verification levels are:

- Unit: a deterministic Rust or TypeScript test with fakes. It must not use the microphone, the global keyboard, or another app.
- Tauri integration: a Rust test of the command handler, event emission, or shared state.
- Manual macOS: a real app check for operating-system behavior that this repository cannot automate.

## D1. Dictation state

Use one state owner for shortcut, tray, command, and UI requests. Test these transitions as a table-driven unit test:

| Initial state | Input | Required result |
| --- | --- | --- |
| Idle | Start | Recording; emit one state update |
| Recording | Stop | Transcribing; emit one state update |
| Transcribing | Complete with text | Pasting, then Idle; emit each state once |
| Transcribing | Complete with empty text | Idle; do not paste |
| Any active state | Cancel | Idle; release audio resources; do not paste |
| Any active state | Start | Reject as busy; do not start a second recorder |
| Any state | Duplicate input | No duplicate transition or side effect |

Also test error recovery from recording, transcription, and paste. Each error must return the coordinator to Idle and release its active resource.

## D2. Tauri command and event contracts

Keep command names and event names in one shared source or in paired constants. After production code selects the names, add contract tests that prove:

1. The Tauri invoke handler registers every dictation command used by the frontend.
2. Start, stop, cancel, and state-query commands use the same argument names and response shapes in Rust and TypeScript.
3. The state event payload has a stable tagged state and an optional error. It must not include audio samples or transcript history.
4. A frontend listener is removed during cleanup and is not registered twice after navigation.
5. A command error is returned to its caller and also produces the required final state event.

Use direct handler or serialization tests. Do not start WebDriver only to test JSON names.

## D3. Clipboard restoration

Follow Handy's safe order: snapshot, publish dictation text, paste, and restore. Add unit tests around a clipboard and paste-key fake for these cases:

| Prior clipboard | Intervening user copy | Required final clipboard |
| --- | --- | --- |
| Text | No | Original text |
| Image | No | Original image |
| Empty | No | Empty |
| Any | Yes | User's newer content |

Restoration must also run after paste failure. On macOS, do not use a fixed delay as proof that the target read the text. Prefer a pasteboard read receipt and guard restoration with the pasteboard change count, as Handy does.

Manual macOS check:

1. Put unique text on the clipboard.
2. Start Notive with `../script/build_and_run.sh --verify`.
3. Focus TextEdit and dictate a unique sentence.
4. Confirm that the sentence appears once.
5. Paste again and confirm that the original clipboard text appears.
6. Repeat with an image copied from Preview.
7. During dictation paste, copy new text in another app. Confirm that Notive does not overwrite it.

## D4. No-persistence default

Dictation must not create a meeting, transcript row, audio file, recovery item, history item, or analytics payload by default.

Use a temporary app-data directory and fake analytics sink in an integration test. Take an inventory before and after one completed dictation. The database rows, app-data files, recovery records, and analytics calls must be unchanged. The only allowed output is the text sent to the paste transaction and transient state events.

If a later opt-in persistence feature is added, keep this test on the default configuration.

## D5. Meeting mutual exclusion

Meeting recording and dictation share audio and transcription resources. Test both directions:

| Active operation | Request | Required result |
| --- | --- | --- |
| Meeting recording | Start dictation | Reject as busy; meeting continues |
| Meeting stopping or processing | Start dictation | Reject until shared resources are free |
| Dictation recording or transcribing | Start meeting | Reject as busy; dictation continues |
| Neither | Start one operation | Start exactly one operation |

The check and state change must be atomic. A concurrent-start test must prove that only one request wins.

Manual macOS check: start a meeting, use the dictation shortcut, and confirm that no second microphone session starts. Then run the inverse check.

## D6. Navigation

Dictation is application-level work. Route changes must not cancel an active dictation, add duplicate event listeners, or create a second coordinator.

Use a frontend test with a fake Tauri event source:

1. Mount the application listener.
2. Navigate through Home, Ask Notive, Settings, and meeting details.
3. Emit each dictation state once during navigation.
4. Confirm that each event updates the UI once.
5. Unmount the application listener and confirm that its unlisten function runs once.

Manual macOS check: start dictation on each route, change route while recording, stop dictation, and confirm that the text goes to the app that had focus before the shortcut.

## Release evidence

Record these items in the change report:

- Exact unit and integration test commands, with pass counts.
- `../script/build_and_run.sh --verify` result.
- macOS version and CPU architecture.
- Clipboard cases checked: text, image, empty, and intervening copy.
- Both meeting mutual-exclusion directions.
- Routes checked during recording and transcription.
- Known gaps. Label all unrun manual checks as unverified.
