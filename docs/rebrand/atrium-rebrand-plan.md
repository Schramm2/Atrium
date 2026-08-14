# Atrium rebrand implementation plan

Status: implemented.

## Context

The product has outgrown its meeting-assistant identity. Per [product-vision.md](../product-vision.md), it is now a company intelligence workspace for Ubundi and First Motive. The former name and the "conversation ledger" design framing carried the old dictation and transcription identity. The rebrand:

1. Renames the product, application, and codebase to **Atrium** (full rename depth).
2. Adds a third brand theme, **Atrium**, adapted from [AuthKitDesign.md](AuthKitDesign.md) (midnight frosted-glass style), and makes it the default. The Ubundi and First Motive themes stay unchanged.
3. Rebrands `DESIGN.md` as the Atrium Design System with the AuthKit-derived styling as the default theme contract.

Decisions confirmed by Matthew:

- **Full rename**: targets, modules, directories, symbols, app name.
- **Ask Atrium** everywhere.
- **Updater: clean break.** New releases publish only `Atrium-X.Y.Z-arm64.dmg`; existing installs update manually once. The GitHub repo stays `Schramm2/notive`.
- **Style depth: colors + glass borders only.** The AuthKit palette, text ramp, and hairline-border language port into the existing component geometry (8/12 px radii, current spacing scale). No pill buttons, no per-theme geometry forks, no font changes (the system family stays, consistent with the earlier Manrope decision).

## Invariants — must NOT change

Per `AGENTS.md` boundaries and install-base compatibility. Every one of these keeps its current value; the rebrand must leave them byte-identical:

| Identifier | Where |
| --- | --- |
| Bundle ID `com.ubundi.meet` | `script/build_and_run.sh:6` |
| Logging subsystem `com.ubundi.meet` | `macos/Sources/AtriumCore/Support/DiagnosticLogger.swift:6` |
| Keychain service `com.ubundi.meet.ai` | `.../Models/AIConfiguration.swift:96` |
| DB dir `applicationSupportDirectory = "Notive"` + legacy `com.ubundi.meet` import dir + `meeting_minutes.sqlite` | `.../Services/SQLiteDatabase.swift:41-43`; also `SUPPORT_DIR` in `scripts/update-local-macos.sh` |
| All 31 `notive.*` UserDefaults keys and `ubundi-meet-brand-theme` | `NotificationService`, `RecordingPreferenceStore`, `MeetingSummaryPreferenceStore`, `UpdaterService.swift:30`, `ContentView.swift:8`, `SettingsView.swift:12,302`, `OnboardingView.swift:11`, `SidebarProfileView.swift:8` |
| Recordings default `~/Movies/notive-recordings/` | `.../Services/RecordingPreferenceStore.swift:9` |
| GitHub repo `Schramm2/notive` | `GitHubReleaseUpdater.swift:43,48`, `scripts/release.sh:51,110` |
| ADRs `docs/decisions/001–006` | immutable historical records |
| Existing CHANGELOG entries | history retains the former product name |

A final grep audit (see Verification) proves the remaining `Notive`/`notive` occurrences are exactly this list.

## Phase 1 — Mechanical rename (code, scripts, CI)

The rename landed before the theme work so the theme code and assets use the final names.

**Package and directories** (`git mv` preserved history):

- `macos/Sources/Atrium`, `macos/Sources/AtriumCore`, `macos/Tests/AtriumTests`, and `macos/Tests/AtriumCoreTests` are the application and test roots.
- `macos/Package.swift` names the package `Atrium`, executable `Atrium`, library `AtriumCore`, and all targets and paths accordingly.
- Imports use `AtriumCore`; the application test target uses `@testable import Atrium`.
- Symbols are `AtriumApp` and `AtriumPageHeader`; the application file is `App/AtriumApp.swift`.
- `.gitignore` negates `macos/Sources/AtriumCore/Models/` so model sources are not ignored.

**Build and release machinery:**

- `script/build_and_run.sh` uses `APP_NAME="Atrium"`, Atrium permission strings, `CFBundleIconFile` `Atrium`, `Atrium.icns`, Atrium module-cache and temporary-directory names, and `ATRIUM_BUILD_VERSION`. The bundle ID is untouched.
- `scripts/release.sh` builds `Atrium-$VERSION-arm64.dmg` and `Atrium.dmg`, verifies `.Atrium.app`, uses `ATRIUM_BUILD_VERSION`, and keeps `--repo Schramm2/notive`.
- `scripts/update-local-macos.sh` uses `/Applications/Atrium.app`, Atrium staging and backup names, `pgrep -x Atrium`, and `INSTALLED_NAME == "Atrium"`; `SUPPORT_DIR` remains the compatibility directory.
- `GitHubReleaseUpdater.swift` targets `Atrium.app`, `/Applications/Atrium.app`, `Atrium-$version-arm64.dmg`, and Atrium temporary prefixes; the repository default stays unchanged. Its tests cover the Atrium bundle target.
- CI verifies `dist/.Atrium.app`, the versioned Atrium DMG, and `Atrium.dmg`.
- `script/dmg_background.swift` and `.codex/environments/environment.toml` use Atrium names.
- `scripts/generate-communication-audit.py` uses the renamed source paths and copy, then `communication-audit.csv` is regenerated.

All user-facing application strings now use Atrium, including window and menu titles, error copy, updater status, onboarding, Settings, Sidebar, Ask, accessibility labels, queue labels, and temporary test fixtures.

## Phase 2 — Atrium theme (new default)

**Enum and palette** — the compiler-enforced core:

- `BrandTheme.atrium = "atrium"` is ordered first in `allCases` and has title `Atrium`.
- `BrandStyle.swift` adds a dark-only `.atrium` palette. It uses `#663AF3` accent, white on accent, `#B6D9FC` secondary accent, `#A78BFA` AI violet, `#E46D4C` warning, `#269684` success, `#05060F` canvas, frost `#BAD6F7` at 0.05/0.09 washes for surfaces, `#BAD7F7` at 0.12 for the border, and `#D1E4FA`/`#9DA7BA` for text.
- No new `BrandPalette` roles, shadows, inset glows, gradients, or atmosphere layer were added. Depth remains borders and tonal fills.

The seven theme branches now use `BrandTheme` computed properties or exhaustive switches:

- The app target's `BrandTheme` extension provides `isDarkOnly`, `markAssetName`, and `appearanceDetailLabel`.
- `ContentView` and `SettingsView` use `isDarkOnly`.
- `BrandMarkView` uses `markAssetName`; `BrandAtmosphere` remains First Motive-only.
- Appearance labels include `Dark · Midnight` for Atrium.
- The Sidebar theme control cycles through `BrandTheme.allCases`.
- Onboarding shows three identity cards, including `atrium-mark`.
- `AppIconService` maps `.atrium` to `atrium-icon`.
- Settings explains the dark-only Atrium and First Motive surfaces.

Atrium is the default through `BrandThemeKey`, the theme `@AppStorage` defaults, and all theme fallbacks. Existing users who already wrote `ubundi-meet-brand-theme` keep their choice; no migration is needed.

**Assets** in `macos/BrandAssets/`:

- `atrium-mark.png`, `atrium-wordmark.png`, `atrium-icon.png`, and `Atrium.icns` are geometric aperture marks with a rounded-square frost-hairline frame, open center, midnight canvas, and violet accent.
- A small Swift/CoreGraphics generator was used but is not committed. The generated marks are replaceable first-pass assets.
- `build_and_run.sh` copies the Atrium assets and the renamed `ubundi-icon.png` and `first-motive-icon.png` assets. Existing Ubundi and First Motive marks and wordmarks remain unchanged.

## Phase 3 — DESIGN.md rebrand and docs

`DESIGN.md` is the Atrium Design System:

- Front matter names Atrium, adds the `atrium-*` tokens, and points the unsuffixed default component tokens to Atrium's composited surface, raised-surface, border, text, and accent values. The `ubundi-*` and `fm-*` token sets and suffixed components remain.
- The overview uses the atrium metaphor and company-intelligence-workspace direction.
- Colors has a three-theme table, the Ubundi functional green note, Atrium's AI-violet note, composited frost values, and the dark-only rule.
- Typography, layout, elevation, shapes, and component contracts keep the existing geometry, system typeface, spacing, and native macOS behavior.
- Accessibility records the Atrium contrast measurements and the status-label tint rule.
- Decisions records the AuthKit adaptation: colors and borders only, no fonts, no gradients or shadows, no geometry fork, dark-only.
- The design document was linted with `npx @google/design.md lint --format json DESIGN.md`; the result is recorded in the document.

The product, repository, interface, architecture, build, release, privacy, contribution, issue-template, AuthKit reference, and update documents use Atrium terminology. `CHANGELOG.md` adds an Unreleased rebrand entry while retaining existing history. ADRs 001–006 remain untouched, and ADR-007 records this decision.

## Phase 4 — Verification

1. `cd macos && swift test -Xswiftc -warnings-as-errors` — proves the rename compiled and tests pass, including the updater and theme tests.
2. `./script/build_and_run.sh run` — manually verify three onboarding identity cards, three sidebar theme states, three Settings previews, dark-only Atrium behavior in both macOS appearances, marks, app icon, Ask Atrium, and window/menu titles.
3. `./script/build_and_run.sh --package` — verify `Atrium.app`, Atrium DMG names, resources, and icon.
4. `npx @google/design.md lint --format json DESIGN.md` — 0 errors.
5. `grep -ri notive --exclude-dir={.git,.build,dist,node_modules}` — remaining matches are only the compatibility identifiers, immutable ADRs 001–006, and existing changelog history.
6. Run the packaged app and confirm that it opens the existing `~/Library/Application Support/Notive/meeting_minutes.sqlite` with prior meetings intact.

## Out of scope

Renaming the GitHub repository, database or preference-key migration, new fonts, per-theme component geometry, marketing surfaces, and running the release command.
