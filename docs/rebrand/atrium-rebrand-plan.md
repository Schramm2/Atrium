# Rebrand Notive → Atrium

Status: approved plan, not yet implemented.

## Context

The product has outgrown its meeting-assistant identity. Per [product-vision.md](../product-vision.md), it is now a company intelligence workspace for Ubundi and First Motive. The name "Notive" (note + motive) and the "conversation ledger" design framing carry the old dictation and transcription identity. The rebrand:

1. Renames the product, application, and codebase to **Atrium** (full rename depth).
2. Adds a third brand theme, **Atrium**, adapted from [AuthKitDesign.md](AuthKitDesign.md) (midnight frosted-glass style), and makes it the default. The Ubundi and First Motive themes stay unchanged.
3. Rebrands `DESIGN.md` from Notive to Atrium with the AuthKit-derived styling as the default theme contract.

Decisions confirmed by Matthew:

- **Full rename**: targets, modules, directories, symbols, app name.
- **"Ask Notive" → "Ask Atrium"** everywhere.
- **Updater: clean break.** New releases publish only `Atrium-X.Y.Z-arm64.dmg`; existing installs update manually once. The GitHub repo stays `Schramm2/notive`.
- **Style depth: colors + glass borders only.** The AuthKit palette, text ramp, and hairline-border language port into the existing component geometry (8/12 px radii, current spacing scale). No pill buttons, no per-theme geometry forks, no font changes (the system family stays, consistent with the earlier Manrope decision).

## Invariants — must NOT change

Per `AGENTS.md` boundaries and install-base compatibility. Every one of these keeps its current value; the rebrand must leave them byte-identical:

| Identifier | Where |
| --- | --- |
| Bundle ID `com.ubundi.meet` | `script/build_and_run.sh:6` |
| Logging subsystem `com.ubundi.meet` | `macos/Sources/NotiveCore/Support/DiagnosticLogger.swift:6` |
| Keychain service `com.ubundi.meet.ai` | `.../Models/AIConfiguration.swift:96` |
| DB dir `applicationSupportDirectory = "Notive"` + legacy `com.ubundi.meet` import dir + `meeting_minutes.sqlite` | `.../Services/SQLiteDatabase.swift:41-43`; also `SUPPORT_DIR` in `scripts/update-local-macos.sh` |
| All 31 `notive.*` UserDefaults keys and `ubundi-meet-brand-theme` | `NotificationService`, `RecordingPreferenceStore`, `MeetingSummaryPreferenceStore`, `UpdaterService.swift:30`, `ContentView.swift:8`, `SettingsView.swift:12,302`, `OnboardingView.swift:11`, `SidebarProfileView.swift:8` |
| Recordings default `~/Movies/notive-recordings/` | `.../Services/RecordingPreferenceStore.swift:9` |
| GitHub repo `Schramm2/notive` | `GitHubReleaseUpdater.swift:43,48`, `scripts/release.sh:51,110` |
| ADRs `docs/decisions/001–006` | immutable historical records |
| Existing CHANGELOG entries | history keeps the old name |

A final grep audit (see Verification) proves the remaining `Notive`/`notive` occurrences are exactly this list.

## Phase 1 — Mechanical rename (code, scripts, CI)

Do the rename first so the theme work lands in renamed files.

**Package and directories** (`git mv` to preserve history):

- `macos/Sources/Notive` → `macos/Sources/Atrium`; `macos/Sources/NotiveCore` → `macos/Sources/AtriumCore`; `macos/Tests/NotiveTests` → `macos/Tests/AtriumTests`; `macos/Tests/NotiveCoreTests` → `macos/Tests/AtriumCoreTests`.
- `macos/Package.swift`: package `Atrium`, executable `Atrium`, library `AtriumCore`, all target names and paths.
- 62 import lines: `import NotiveCore` → `import AtriumCore` (+ `@testable` variants, incl. `@testable import Notive` → `Atrium` in `UpdaterServiceTests.swift`).
- Symbols: `NotiveApp` → `AtriumApp` (file `App/NotiveApp.swift` → `AtriumApp.swift`), `NotivePageHeader` → `AtriumPageHeader` (decl + extension + ~9 call sites, all in views).
- `.gitignore:14-15`: update the `NotiveCore/Models/` path negations to `AtriumCore/Models/` — **required or the model sources become ignored**.

**Build and release machinery:**

- `script/build_and_run.sh`: `APP_NAME="Atrium"`, the three permission usage-description strings, `CFBundleIconFile` → `Atrium`, copy `Atrium.icns`, module-cache and temp-dir names, `NOTIVE_BUILD_VERSION` → `ATRIUM_BUILD_VERSION`. The bundle ID line is untouched.
- `scripts/release.sh`: DMG names `Atrium-$VERSION-arm64.dmg` / `Atrium.dmg`, `.Atrium.app` codesign path, release title `Atrium $TAG`, `ATRIUM_BUILD_VERSION` env; `--repo Schramm2/notive` stays.
- `scripts/update-local-macos.sh`: `/Applications/Atrium.app`, staging and backup names, `pgrep -x Atrium`, `INSTALLED_NAME == "Atrium"`; `SUPPORT_DIR` (Application Support/Notive) stays.
- `GitHubReleaseUpdater.swift`: `appName = "Atrium.app"`, `appTarget = "/Applications/Atrium.app"`, asset name `Atrium-\(version)-arm64.dmg`, temp prefixes; the repo default stays. Update `GitHubReleaseUpdaterTests.swift` assertions.
- `.github/workflows/ci.yml`: `dist/.Atrium.app`, DMG names (3 lines).
- `script/dmg_background.swift`: 3 copy strings.
- `.codex/environments/environment.toml`: `name = "atrium"`.
- `scripts/generate-communication-audit.py`: update its 30 name references, then regenerate `communication-audit.csv`.

**User-facing string literals (~86):** replace "Notive" with "Atrium" in UI copy — largest files: `AppStore.swift` (22), `UpdaterService.swift` (10), `OnboardingView.swift` (8), `SQLiteDatabase.swift` error copy (7), `AskView.swift` (6, becomes "Ask Atrium"), `AtriumApp.swift` (window title, menu-bar extra, "Open/Ask/Quit Atrium"), `UpdateBanner.swift` incl. accessibility labels, `SettingsView.swift`, `SidebarView.swift`, remaining single occurrences. Ephemeral queue labels and temp-dir prefixes (`notive-update-`, `Notive.system-audio`, test fixture dirs) rename too — they persist nothing.

## Phase 2 — Atrium theme (new default)

**Enum and palette** — the compiler-enforced core:

- `macos/Sources/AtriumCore/Models/WorkspaceSelection.swift`: add `case atrium = "atrium"`, title `"Atrium"`, ordered first in `allCases`.
- `BrandStyle.swift` `palette(for:colorScheme:)`: add the `.atrium` case, dark-only (ignores `colorScheme`, like First Motive). Mapping from `AuthKitDesign.md`:

| BrandPalette role | Value | AuthKit source |
| --- | --- | --- |
| accent / onAccent | `#663AF3` / white | Void Violet CTA (white on violet ≈ 5.9:1) |
| secondaryAccent (info, links, local scope) | `#B6D9FC` | Blueprint Blue |
| ai (generated/processing) | `#A78BFA`-class lightened violet | functional derivation — AuthKit reserves violet for the sole CTA; the ai role needs a distinct luminous violet. Record as a functional color like Ubundi's green |
| warning | `#E46D4C` | Ember Glow |
| success | `#269684` | Deep Teal |
| detailBackground (canvas) | `#05060F` | Midnight Canvas |
| surface / raisedSurface | frost `#BAD6F7` at 0.05 / 0.09 opacity washes | frosted-glass card pattern (follows the First Motive wash idiom; document composited hexes in DESIGN.md) |
| border | `#BAD7F7` at 0.12 | Glass Edge hairline |
| text / secondaryText | `#D1E4FA` / `#9DA7BA` | Frost Glow / Fog Veil |

No new `BrandPalette` roles, no shadows or inset glows — depth stays borders + tonal fills per the existing contract. The hairline low-opacity border IS the glass language at this scale.

**Fix the 7 non-exhaustive theme branches** (they silently mis-render a third case). Replace ternaries with `BrandTheme` computed properties or exhaustive switches:

- New UI-facing properties in a `BrandTheme` extension in the app target (in `BrandStyle.swift`, since `AtriumCore` has no SwiftUI): `isDarkOnly` (true for `.firstMotive`, `.atrium`), `markAssetName`, `appearanceDetailLabel`.
- `ContentView.swift:59-63` and `SettingsView.swift:41-45`: use `isDarkOnly`.
- `BrandStyle.swift:210` (`BrandMarkView`): switch via `markAssetName` → `"atrium-mark"`.
- `BrandStyle.swift:231` (`BrandAtmosphere`): stays First Motive-only; Atrium gets no atmosphere layer.
- `SettingsView.swift:366`: per-theme label — Atrium: `"Dark · Midnight"`.
- `SidebarProfileView.swift:82-84`: cycle through `BrandTheme.allCases` instead of the two-way flip.
- `OnboardingView.swift:148-165`: add the third `IdentityCard` (markName `"atrium-mark"`) or convert to `ForEach(BrandTheme.allCases)`.
- `AppIconService.swift:7-10`: add `.atrium` → `"atrium-icon"` (exhaustive switch already).
- Settings explanation string `SettingsView.swift:327-331`: per-theme copy including "Atrium and First Motive always use their dark surface".

**Make Atrium the default:** change `BrandThemeKey.defaultValue` (`BrandStyle.swift:64`), the 5 `@AppStorage` defaults, and the 5 `?? .firstMotive` fallbacks to `.atrium` (`ContentView.swift:8,19`, `SettingsView.swift:12,17,302,343`, `OnboardingView.swift:11,43`, `SidebarProfileView.swift:8,79`). Existing users who already wrote `ubundi-meet-brand-theme` keep their choice — no migration needed.

**Assets** (`macos/BrandAssets/`, loose PNGs, copied by name in `build_and_run.sh` ~L95-102):

- Generate: `atrium-mark.png`, `atrium-wordmark.png`, `atrium-icon.png` (runtime app icon), `Atrium.icns` (via `iconutil`). Design: geometric aperture — a rounded-square frost-hairline frame with an open luminous center on midnight, violet accent. Generate programmatically (small Swift/CoreGraphics script, not committed); flag in the commit message that these are replaceable first-pass marks.
- Add the new `cp` lines to `build_and_run.sh`; replace the `Notive.icns` copy with `Atrium.icns`. Keep all Ubundi and First Motive assets. Rename `notive-ubundi-icon.png` / `notive-first-motive-icon.png` to `ubundi-icon.png` / `first-motive-icon.png` and update `AppIconService` + the build script — their filenames carry the old product name and nothing persisted references them.

## Phase 3 — DESIGN.md rebrand and docs

**`DESIGN.md` → Atrium Design System** (full rewrite of identity, surgical on surviving content):

- Front matter: `name: Atrium`, add the `atrium-*` color tokens; the unsuffixed default component tokens (panel, button-primary, screen, toolbar, divider, sidebar-row, empty-state) re-point from `fm-*` to `atrium-*` values (composited hexes for the washes); keep the `ubundi-*` and `fm-*` token sets and their suffixed components.
- Body: overview reframed from "conversation ledger" to the atrium metaphor and the company-intelligence-workspace direction; Colors gains the three-theme table with the functional-color notes (Ubundi green, Atrium ai-violet); typography, layout, elevation, shapes, and component contracts unchanged except theme references; accessibility gains contrast measurements for the new palette (`#D1E4FA` on `#05060F` ≈ 15:1; verify status-label tints); Decisions records the AuthKit adaptation choices (colors + borders only, no fonts, dark-only).
- Re-run `npx @google/design.md lint --format json DESIGN.md` and record the result, matching the doc's existing convention.

**Other docs** — rename Notive → Atrium throughout: `README.md`, `PRODUCT.md` (L36 name declaration), `CONTEXT.md` (title, domain terms: "Ask Atrium"), `AGENTS.md` (product name; keep the `com.ubundi.meet` and data-compat boundary sentences, which now also justify the kept `Notive` support dir), `FRONTEND.md` (also fix L87 — themes do not all follow system appearance; the verification sentence becomes three themes), `docs/architecture.md`, `docs/product-vision.md`, `docs/BUILDING.md`, `docs/RELEASING.md`, `docs/LOCAL_MACOS_UPDATES.md`, `PRIVACY_POLICY.md`, `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/bug_report.md`. `CHANGELOG.md`: add an Unreleased entry describing the rebrand; leave history.

**New ADR** — `docs/decisions/007-rebrand-to-atrium.md`: records the rename, the new default theme, the clean-break updater decision (existing installs update manually once; repo name kept), and the full kept-identifier list from Invariants above. ADRs 001–006 untouched.

## Phase 4 — Verification

1. `cd macos && swift test -Xswiftc -warnings-as-errors` — the default completion check; proves the rename compiled and tests (incl. updated updater tests) pass.
2. `./script/build_and_run.sh run` — manual pass: onboarding shows three identity cards; the sidebar theme control cycles all three; Settings → Appearance previews three themes with correct labels and explanation; Atrium renders dark-only in both macOS appearances; marks and app icon correct per theme; "Ask Atrium" in the sidebar and menu bar; window and menu titles.
3. `./script/build_and_run.sh --package` — bundle name `Atrium.app`, DMG names, icon.
4. `npx @google/design.md lint --format json DESIGN.md` — 0 errors.
5. Grep audit: `grep -ri notive --exclude-dir={.git,.build,dist,node_modules}` returns only the Invariants list (SQLiteDatabase constants, preference keys, recordings default, repo references, ADRs 001–006, CHANGELOG history, `scripts/update-local-macos.sh` SUPPORT_DIR).
6. Data compatibility: run the packaged app and confirm it opens the existing `~/Library/Application Support/Notive/meeting_minutes.sqlite` with prior meetings intact.

## Out of scope

Renaming the GitHub repository, any database or preference-key migration, new fonts, per-theme component geometry, marketing surfaces. The release itself (`scripts/release.sh`) is not run as part of this change.
