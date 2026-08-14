---
version: alpha
name: Atrium
description: Visual and interaction contract for the Atrium macOS workspace, in Atrium, Ubundi, and First Motive themes. Atrium is the default dark-only theme.
colors:
  primary: "#663AF3"
  ubundi-accent: "#2F3498"
  ubundi-on-accent: "#FFFFFF"
  ubundi-secondary-accent: "#7188BE"
  ubundi-ai: "#C183E6"
  ubundi-warning: "#D77A85"
  ubundi-success: "#4F8F75"
  ubundi-light-canvas: "#F8F9FC"
  ubundi-light-surface: "#FFFFFF"
  ubundi-light-raised: "#F4F5F9"
  ubundi-light-border: "#E3E3E3"
  ubundi-light-text: "#121214"
  ubundi-light-text-secondary: "#616161"
  ubundi-dark-canvas: "#0E101F"
  ubundi-dark-surface: "#161829"
  ubundi-dark-raised: "#1D2033"
  ubundi-dark-border: "#343645"
  ubundi-dark-text: "#F3F3F4"
  ubundi-dark-text-secondary: "#B4B5BB"
  fm-accent: "#9CB89E"
  fm-on-accent: "#2A3A2C"
  fm-secondary-accent: "#7FA9B8"
  fm-ai: "#9B8FB8"
  fm-warning: "#D89B9F"
  fm-success: "#9CB89E"
  fm-canvas: "#433B47"
  fm-surface: "#4B444F"
  fm-raised: "#514A55"
  fm-border: "#5A525B"
  fm-text: "#E8E2D7"
  fm-text-secondary: "#BCB6B1"
  fm-status-tint: "#52515D"
  atrium-accent: "#663AF3"
  atrium-on-accent: "#FFFFFF"
  atrium-secondary-accent: "#B6D9FC"
  atrium-ai: "#A78BFA"
  atrium-warning: "#E46D4C"
  atrium-success: "#269684"
  atrium-canvas: "#05060F"
  atrium-surface: "#0E101B"
  atrium-raised-surface: "#151924"
  atrium-border: "#1B1F2B"
  atrium-text: "#D1E4FA"
  atrium-text-secondary: "#9DA7BA"
typography:
  page-title:
    fontFamily: "system-ui"
    fontSize: "26px"
    fontWeight: 600
    letterSpacing: "-0.5px"
  section-title:
    fontFamily: "system-ui"
    fontSize: "13px"
    fontWeight: 600
  body:
    fontFamily: "system-ui"
    fontSize: "13px"
    fontWeight: 400
  support:
    fontFamily: "system-ui"
    fontSize: "12px"
    fontWeight: 400
  label:
    fontFamily: "system-ui"
    fontSize: "11px"
    fontWeight: 400
  status:
    fontFamily: "system-ui"
    fontSize: "10px"
    fontWeight: 600
rounded:
  control: "8px"
  panel: "12px"
  capsule: "999px"
spacing:
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  xxl: "24px"
  xxxl: "32px"
  xxxxl: "48px"
components:
  panel:
    backgroundColor: "{colors.atrium-surface}"
    textColor: "{colors.atrium-text}"
    rounded: "{rounded.panel}"
    padding: "20px"
  button-primary:
    backgroundColor: "{colors.atrium-accent}"
    textColor: "{colors.atrium-on-accent}"
    typography: "{typography.section-title}"
    rounded: "{rounded.control}"
    height: "32px"
  button-primary-disabled:
    backgroundColor: "{colors.atrium-surface}"
    textColor: "{colors.atrium-text-secondary}"
    rounded: "{rounded.control}"
    height: "32px"
  button-secondary:
    backgroundColor: "{colors.atrium-surface}"
    textColor: "{colors.atrium-text}"
    typography: "{typography.section-title}"
    rounded: "{rounded.control}"
    height: "28px"
  status-label:
    backgroundColor: "{colors.atrium-raised-surface}"
    textColor: "{colors.atrium-text}"
    typography: "{typography.status}"
    rounded: "{rounded.capsule}"
    padding: "8px 12px"
  status-label-ubundi:
    backgroundColor: "{colors.ubundi-light-raised}"
    textColor: "{colors.ubundi-light-text}"
    typography: "{typography.status}"
    rounded: "{rounded.capsule}"
    padding: "8px 12px"
  screen:
    backgroundColor: "{colors.atrium-canvas}"
    textColor: "{colors.atrium-text}"
  toolbar:
    backgroundColor: "{colors.atrium-raised-surface}"
    textColor: "{colors.atrium-text}"
  panel-ubundi-light:
    backgroundColor: "{colors.ubundi-light-surface}"
    textColor: "{colors.ubundi-light-text}"
    rounded: "{rounded.panel}"
    padding: "20px"
  panel-ubundi-dark:
    backgroundColor: "{colors.ubundi-dark-surface}"
    textColor: "{colors.ubundi-dark-text}"
    rounded: "{rounded.panel}"
    padding: "20px"
  screen-ubundi-light:
    backgroundColor: "{colors.ubundi-light-canvas}"
    textColor: "{colors.ubundi-light-text}"
  screen-ubundi-dark:
    backgroundColor: "{colors.ubundi-dark-canvas}"
    textColor: "{colors.ubundi-dark-text}"
  toolbar-ubundi-light:
    backgroundColor: "{colors.ubundi-light-raised}"
    textColor: "{colors.ubundi-light-text-secondary}"
  toolbar-ubundi-dark:
    backgroundColor: "{colors.ubundi-dark-raised}"
    textColor: "{colors.ubundi-dark-text-secondary}"
  button-primary-ubundi:
    backgroundColor: "{colors.ubundi-accent}"
    textColor: "{colors.ubundi-on-accent}"
    typography: "{typography.section-title}"
    rounded: "{rounded.control}"
    height: "32px"
  divider:
    backgroundColor: "{colors.atrium-border}"
    height: "1px"
  divider-ubundi-light:
    backgroundColor: "{colors.ubundi-light-border}"
    height: "1px"
  divider-ubundi-dark:
    backgroundColor: "{colors.ubundi-dark-border}"
    height: "1px"
  sidebar-row:
    textColor: "{colors.atrium-text}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    height: "28px"
  sidebar-row-selected:
    backgroundColor: "{colors.atrium-accent}"
    textColor: "{colors.atrium-on-accent}"
    rounded: "{rounded.control}"
    height: "28px"
  empty-state:
    backgroundColor: "{colors.atrium-surface}"
    textColor: "{colors.atrium-text-secondary}"
    rounded: "{rounded.panel}"
    height: "240px"
---

# Atrium Design System

<!-- impeccable:design-schema 1 -->

## Overview

Atrium is a **company intelligence workspace**: a calm native place where company context, agent work, approved shared knowledge, and private local capture stay connected. The atrium metaphor is a shared center with clear thresholds: Company Hub shows approved company work, while My Workspace keeps meetings, notes, Dictation, and Ask on this Mac until the owner chooses otherwise. The interface uses a stable macOS sidebar and a wide work canvas. It avoids marketing-style hero panels, stacked cards, and large unused fields. Brand identity appears through exact color roles, type hierarchy, small line details, and canonical marks.

The interface mode is **Operate**. Fast scanning, reliable state, keyboard access, and transcript readability take priority over decoration.

The workspace has two scopes, and the interface must always make clear which one the user looks at:

- **Workspace** is private and local. Home, Ask Atrium, Dictation, Meeting Notes, and the meeting workspace read only this Mac.
- **Company Hub** is shared across Ubundi and First Motive. Company, Agents, Shared Context, People, Search, and Activity show only what an owner chose to share.

Nothing crosses from Workspace to Company Hub without an explicit per-item action by its owner.

### Evidence Sources

The tokens above are read from the implementation, not from an external brand file:

| Source | What it establishes |
| --- | --- |
| `macos/Sources/Atrium/Views/BrandStyle.swift` | `BrandPalette` for three themes, `BrandScreen`, `AtriumPageHeader`, `BrandPanel`, `BrandStatusLabel`, `BrandMarkView`, `BrandAtmosphere` |
| `macos/Sources/Atrium/Views/ContentView.swift` | Split-view shell, sidebar width, theme and appearance resolution, error banners |
| `macos/Sources/Atrium/Views/CompanyHub/Components/` | `Hub*` components, tint roles, the shared empty state |
| `macos/BrandAssets/` | Marks, wordmarks, application icons, the First Motive atmospheric reference |
| `PRODUCT.md`, `docs/product-vision.md` | Product purpose, the two scopes, the privacy boundary |

`BrandPalette` stores colors as floating-point RGB, and it builds some roles by washing white or ivory over the surface below. The token values above are the exact conversions, composited where the implementation uses a wash, so they can be read and contrast-checked directly. The Elevation and Colors sections give the wash that produces each one. Change `BrandStyle.swift` and this document in the same commit.

Verified with `npx @google/design.md lint --format json DESIGN.md`: 0 errors, 0 contrast findings, 21 accepted warnings.

The 21 warnings read `orphaned-tokens` for semantic state colors and preserved suffixed theme tokens that are not component slots. They are accepted rather than fixed. Those colors reach the interface as icon colors, capsule fills, and borders, while the component schema has slots for a background and a text color only. Giving every state color a component entry would either misstate it as text or invent a token the code does not have.

### Surface Map

Atrium exposes one product surface: an operational macOS desktop workspace. It has no marketing, documentation, or embedded surface, so marketing treatment applies nowhere in this repository. Three regions carry different density inside that one surface:

| Region | Role | Density |
| --- | --- | --- |
| Workspace screens | Capture, recall, and writing on local data | Operational, wide canvas |
| Company Hub screens | Read what the company shared | Operational, table-led |
| Settings and Onboarding | One decision at a time | Native form density |

### Voice & Content

- Use one concise heading and one factual support line for each destination. Supporting copy states something the heading does not.
- Use sentence case for headings, labels, and buttons. Reserve uppercase for short system states such as `SHARED` and `AGENT`.
- Name the product **Atrium**. Use the domain terms in [CONTEXT.md](CONTEXT.md): My Workspace, Company Hub, Meeting, Ask, Local Dictation, voice grouping.
- An error names what failed and what the user can do. A destructive confirmation names the item and the effect.
- An empty state says what will appear in that surface, and why it is empty now.
- Use monospaced digits for timestamps, durations, and counters.

## Colors

Each theme resolves one `BrandPalette` through `BrandPalette.palette(for:colorScheme:)`. Atrium is the default theme. Read colors through the palette rather than repeating raw values in a view.

| Role | Atrium | Ubundi | First Motive |
| --- | --- | --- | --- |
| Accent, primary action, selection | Void Violet `#663AF3` | Navy `#2F3498` | Sage `#9CB89E` |
| Text on accent | White | White | Deep sage `#2A3A2C` |
| Information, links, local-scope status | Blueprint Blue `#B6D9FC` | Blue `#7188BE` | Steel `#7FA9B8` |
| Generated or processing state | Luminous violet `#A78BFA` | Electric `#C183E6` | Lilac `#9B8FB8` |
| Warning or destructive state | Ember Glow `#E46D4C` | Salmon `#D77A85` | Coral `#D89B9F` |
| Success, running agent | Deep Teal `#269684` | Green `#4F8F75` | Sage `#9CB89E` |

Ubundi follows the macOS appearance. Light uses a `#F8F9FC` canvas, white surfaces, `#F4F5F9` raised surfaces, and 11% black borders. Dark uses a `#0E101F` canvas, `#161829` surfaces, `#1D2033` raised surfaces, and 13% white borders. Keep Navy and Blue visible in dark; do not wash the whole canvas purple.

First Motive is a dark brand theme. Its aubergine `#433B47` canvas stays dark in every macOS appearance, and `preferredColorScheme` is forced to dark. Surfaces come from white washes over that canvas — 4.5% for `fm-surface` `#4B444F` and 7.5% for `fm-raised` `#514A55` — with a 14% ivory border, `#5A525B`.

Atrium is also dark-only. Its Midnight Canvas is `#05060F`, its frost wash uses `#BAD6F7` at 5% for the `atrium-surface` composited value `#0E101B` and 9% for the `atrium-raised-surface` composited value `#151924`, and its Glass Edge uses `#BAD7F7` at 12% for `#1B1F2B`. Atrium has no atmosphere layer. Its violet primary action is `#663AF3`, while `#A78BFA` is a separate functional AI color so generated or processing content does not look like a primary action.

An accent color carries meaning. Electric, Lilac, and Atrium's luminous violet mark generated or processing content only. Use no ambient accent without a workflow state behind it.

### Colors outside the brand palette

The Ubundi brand guideline names six core colors: Navy, Blue, Grey, Electric, Salmon, and Amber. It has no green, so Ubundi success green `#4F8F75` is a **functional color**: it carries the success and running states, which must read apart from the primary action (Navy), information (Blue), generated content (Electric), and warning (Salmon). First Motive needs no equivalent, because its Sage accent already serves both roles. Atrium's Deep Teal and luminous AI violet are functional colors: they carry success and processing states without changing the primary action. These roles are defined by product function, not by an additional brand palette family.

Ubundi Amber `#F3C57A` and deep navy `#1B1F44` are brand colors with no role in this interface. Atrium's semantic roles are all assigned, and neither First Motive nor Atrium has an amber role, so an attention role cannot exist in all three themes without inventing a color. They stay in the Ubundi brand guideline for marketing surfaces and out of `BrandPalette`.

The Ubundi light surfaces are navy-tinted neutrals — canvas `#F8F9FC` and raised `#F4F5F9` — rather than the brand's flat `#F5F5F5`. The tint keeps the theme coherent under a navy accent. The First Motive surfaces land within one step of the brand elevation ramp, `#4b434e` and `#504954`, which confirms the wash values.

## Typography

Atrium uses the macOS system family through the SwiftUI text styles. The sizes in the front matter are the macOS defaults at the standard text size, not fixed values.

The Ubundi and First Motive brand guidelines both specify Manrope for brand surfaces, and both write it with a system fallback. Atrium uses the fallback deliberately. The system family is the native choice for an operational macOS workspace, it follows the user's accessibility text-size setting without extra work, and the product ships no font file today. Marketing and web surfaces keep Manrope; this product does not. Revisit only with a licensed font in `macos/BrandAssets/`, applied through `Font.custom(_:relativeTo:)` so text scaling survives.

| Role | Text style | Use |
| --- | --- | --- |
| Page title | `.largeTitle.weight(.semibold)` with `-0.5` tracking | The one title in `AtriumPageHeader` |
| Section title | `.headline` | Panel and section headings |
| Body | `.body` | Transcript text, notes, answers |
| Support | `.callout` | The page-header support line, secondary detail |
| Label | `.subheadline` | Row labels and metadata |
| Status | `.caption.weight(.semibold)` | Status labels, counters, timestamps |

Give transcript text generous line spacing and keep timestamps compact and monospaced. Keep display typography out of repeated rows, the sidebar, settings rows, and transcript controls.

## Layout

- Keep one `NavigationSplitView` shell for all three themes.
- The sidebar column is 240 points minimum, 268 ideal, 320 maximum. Keep native list selection and keyboard behavior.
- The window is at least 960 by 640 points and opens at 1,100 by 700.
- Put global search in the toolbar. Search does not repeat inside page content.
- Give each destination a compact page header: title, one factual sentence, and the relevant actions.
- Use the full detail width. Reading surfaces hold a 900–1,080 point measure. Operational lists, transcripts, and two-column screens extend to 1,280–1,360 points.
- Screen content uses 32 points of padding.
- Use the `{spacing}` steps for layout: 8, 12, 16, 20, 24, 32, and 48 points. `BrandPanel` pads by 20.
- Values of 1 to 6 points are optical adjustments inside one component, such as an icon-to-label gap or a two-line label. They are not layout steps, and they never set the distance between sections.
- Use `ViewThatFits` to fold a two-column screen into one column before content compresses.

## Elevation & Depth

Depth comes from borders and tonal fills, not from shadows.

| Level | Treatment |
| --- | --- |
| Canvas | `BrandScreen` paints the theme canvas behind every screen |
| Panel | `BrandPanel`: surface fill, one-point border, 12-point radius |
| Raised | Toolbar and sidebar use the raised surface |
| Floating | Shadows are reserved for popovers, menus, and overlays |

Do not nest a panel inside a panel. Prefer one flat section with a border and a tonal fill.

## Shapes

The shape language has two radii and one capsule. A third step reads as noise at this scale.

- 8-point radius for controls, chips, avatars, and compact rows.
- 12-point radius for panels, large sections, and overlays.
- Capsules for status labels and short primary actions only.
- The brand mark clips to a 22% corner radius, which scales with the mark.

## Components

Compose screens from `BrandScreen`, `AtriumPageHeader`, `BrandPanel`, and `BrandStatusLabel`. Company Hub screens add the `Hub*` components. Use them rather than repeating raw colors and metrics.

### Sidebar

- Show the Atrium mark and active company identity at the top.
- Keep four primary workspace destinations equal in weight: Home, Ask Atrium, Dictation, and Meeting Notes.
- Put the Company Hub destinations in a second section, labelled `Company Hub` with a `SHARED` marker. The marker states the scope change; it is not repeated on every row.
- Order the Company Hub destinations Company, Agents, Shared Context, People, Search, and Activity.
- Use native list badges for counts that need action, such as running agents and unread activity. Show no badge at zero.
- Separate saved meetings with a clear section label and compact title and date rows.
- Keep capture and import actions in a bottom action area, with one theme menu and the appearance control beside it.

### Page Header

- One concise heading and one support line.
- Align page actions to the trailing edge when space permits. Move them into an overflow menu before the title compresses.
- Use a short privacy status label where an external-data boundary matters.

### Sections and Lists

- Prefer one flat section over cards inside cards.
- Use dividers and aligned columns for repeated data.
- Keep empty states concise and actionable, with one next action.
- Where a capability is not connected, disable the actions that need it and explain the reason in help text. Keep the action visible, and never let it appear to succeed.
- Use accent edges, icons, or labels only when they encode a real workflow state.

### Controls

- One prominent action per region.
- Pair a destructive color with a destructive label or system icon.
- Buttons are at least 28 points high. Primary workspace actions use 32–38 points.

### Screen Contracts

**Home.** A balanced command center. Four equal workflow tiles — Capture, Ask, Dictate, Review Notes — then recent meetings and a compact local-privacy status row. No oversized recording hero.

**Ask Atrium.** Question composer at the top, scope and date limits beside or below it, and the remaining space for a clear empty state or a readable answer with source citations. The local or external evidence boundary is visible before submission.

**Dictation.** Listening state, shortcut, microphone, and on-device processing read as one status surface. The latest result sits in a dedicated reading area with Copy as the clear secondary action.

**Meeting Notes.** A searchable, date-aware meeting list with title, date, transcript and notes status, and one clear open action.

**Meeting Workspace.** Protect the meeting title from action overflow. Keep Play and Save visible; put Retranscribe, Open Recording, and Delete in an overflow menu. Use a stable content switcher for Transcript, Summary, and Notes. Transcript rows get a narrow timestamp column, an optional speaker label, a readable measure, and calm separators.

**Company.** The Company Hub landing screen. A stat strip of headline numbers, then two columns: what the team shared today, and an agent summary with the newest activity. Each column links to its full screen. Close with the sharing boundary statement, and show the connection state in the page header.

**Agents.** A roster of agent cards beside one thread. A card carries the agent name, role, status, one sentence of purpose, and run counts. The thread is company-visible by default and says so beside the agent name. The composer stays at the bottom with one send action.

**Shared Context.** A filter row of All, Meetings, Notes, and Agent output above one table. Each row gives the item, who shared it, its source kind, and when. `Share from my workspace` is the single header action. State that sharing is a per-item choice by its owner and can be withdrawn.

**People.** One table of everyone in the shared workspace: name, role, company, focus this week, and status. Mark agents with a short `AGENT` label so people and agents stay distinguishable without color.

**Search.** One large search field, then results grouped by source — meetings, shared context, people, and agent runs. The closing line states that search covers the local workspace plus shared items, and that nothing local is exposed to others.

**Activity.** One reverse-chronological feed. Each entry has an actor, an action, an optional detail block, and a relative time. Mark unread entries. `Mark all read` is the single header action, disabled when nothing is unread.

**Settings.** The native Settings scene and toolbar, with consistent section surfaces, row alignment, labels, helper text, and brand-aware tint across all tabs. Appearance previews Atrium, Ubundi, and First Motive and explains the fixed dark surfaces.

**Onboarding.** The selected brand mark, a short three-step progress indicator, and one permission or workspace decision per step. Permission reasons stay factual, and optional access never looks required.

### Motion & Interaction

- Use 120–220 ms transitions, and only to explain selection, disclosure, progress, or insertion.
- Respect Reduce Motion. A reduced-motion state change stays as legible as the animated one: the end state, not the transition, carries the meaning.
- Avoid entrance choreography.

### Accessibility & States

Every data screen covers initial, loading, loaded, empty, and error. A disconnected capability adds a disabled state with a stated reason. Interactive controls cover hover, pressed, focus, selected, and disabled.

- Preserve VoiceOver names, values, and actions. Give an icon-only control an accessibility label and hide decoration.
- Keep visible keyboard focus and native tab order.
- Meet WCAG AA contrast for normal text. Warm ivory on aubergine and the Ubundi text roles meet it. Atrium `#D1E4FA` on `#05060F` measures about 15.6:1, and `#9DA7BA` on the same canvas measures about 8.3:1. On Atrium's composited surface and raised surface, the primary text measures about 14.6:1 and 13.5:1. Steel, Lilac, Sage, Electric, and faint ivory carry too little contrast for small text: use them for icons, borders, and tint fills, and keep the text beside them in a text color.
- `BrandStatusLabel` follows this rule: the tint stays on the icon, the capsule fill, and the border, and the title uses the theme text color.
- Never rely on color alone for recording, warning, selection, provider boundary, or completion state. Pair the color with a label or a system icon. This is what keeps the status labels legible today, and it stays required after the contrast fix.
- Company Hub screens use `HubEmptyState.notConnected(...)` so no surface is blank without an explanation.

## Do's and Don'ts

**Do**

- Read colors and metrics through `BrandPalette` and the shared `Brand*` components.
- Give every accent a workflow meaning.
- Explain an empty surface and a disabled action.
- Keep native macOS selection, menus, toolbars, and Settings behavior.
- Check a change in all three themes, in both macOS appearances where the theme permits it, at the minimum window size, and with the keyboard alone.

**Don't**

- No large decorative hero card on Home.
- No card grids for simple settings or transcript rows, and no nested cards.
- No fixed narrow content column that leaves most of a large window unused.
- No title compression caused by many inline actions.
- No sample, seeded, or demonstration content in a shipped screen. An unimplemented capability shows an empty state, not invented data.
- No control that appears to publish, send, or share while the capability behind it does not exist.

## Canonical Assets

The marks, wordmarks, application icons, and the First Motive atmospheric reference are in `macos/BrandAssets/`. `BrandAssets.image(named:)` loads them from the application bundle. Copy new source assets in without modifying the originals. Use the canonical marks without recoloring or distortion.

`BrandAtmosphere` draws the First Motive reference at 34% opacity. Use it only as a restrained onboarding or empty-state texture. Atrium does not use an atmosphere layer. Neither treatment may reduce operational contrast or become a full-screen decoration.

## Implementation State

The interface is built in SwiftUI in `macos/Sources/Atrium/Views/`. [FRONTEND.md](FRONTEND.md) covers how screens, state, and verification work.

**Workspace** — Home, Ask Atrium, Dictation, Meeting Notes, the meeting workspace, Settings, and Onboarding are implemented and read local data through `AppStore`.

**Company Hub** — the screens in `Views/CompanyHub/` are complete and meet the contracts above. No shared workspace exists behind them. `CompanyHubStore` holds their state and reads through `CompanyHubProviding`; the default `DisconnectedCompanyHubService` returns nothing and reports `CompanyHubUnavailableError` for writes. Every Company Hub screen therefore shows its empty state, and `Share to hub`, agent messaging, and `Mark all read` stay disabled. To implement it, provide a `CompanyHubProviding` conformance and pass it to `CompanyHubStore`. No screen needs to change.

## Decisions

These were the open questions in the previous revision. Each is answered, and the answer is applied in this document and in the code.

1. **Typeface — system family, not Manrope.** Both brand guidelines specify Manrope, and both write it with a system fallback. No Manrope file exists in `macos/BrandAssets/`, in the Company Media brand folders, or on a build machine, so the earlier rule could never take effect. The system family is also the correct native choice here and scales with the accessibility text size for free. See Typography.
2. **Spacing — a single scale of 8, 12, 16, 20, 24, 32, and 48 points.** 20 joins the scale because `BrandPanel` pads by it. Values of 1 to 6 points are optical adjustments inside a component and are not layout steps. The off-scale layout gaps were corrected: 10 to 12, 11 to 12, 13 to 12, 14 to 16, 18 to 16, 22 to 24, and 28 and 30 to 32, across 27 view files.
3. **Radius — two steps, 8 and 12 points, plus the capsule.** The stray 5, 7, 9, and 10-point radii fold into 8; 14 and 18 fold into 12. Seven view files changed.
4. **Amber and deep navy stay out of the product palette.** Both are real Ubundi brand colors, and neither has a role here. Every semantic role is assigned, and First Motive has no amber, so a theme-symmetric attention role would need an invented color. They remain brand colors for Ubundi marketing surfaces.
5. **Ubundi success green stays, as a functional color.** The Ubundi brand names six colors and none is green, while success and running must stay distinct from the primary action, information, generated content, and warning. It is recorded under Colors as the product's one functional color. This is the single item that still wants brand sign-off.
6. **Status label contrast — fixed in `BrandStatusLabel`.** The tint now carries the state on the icon, the capsule fill, and the border, and the title uses the theme text color. Ivory on the First Motive tint now measures 6.05:1, and Ubundi text on its raised surface 17.17:1 in light and 14.49:1 in dark, against 2.52:1 to 3.62:1 before. The capsule padding moved to 12 by 8 points to match the spacing scale.
7. **Atrium adaptation — colors and borders only.** Atrium adapts the AuthKit midnight palette, text ramp, and hairline glass-border language into the existing 8/12-point geometry, system typeface, and spacing scale. It stays dark-only, uses no gradients, shadows, new fonts, pill geometry, or per-theme component fork, and keeps the existing product surface. The `#A78BFA` AI violet and the `#151924` status tint are functional choices, not new `BrandPalette` roles. See [AuthKitDesign.md](docs/rebrand/AuthKitDesign.md).

## Open Questions

None. Raise a new one here rather than leaving a durable design decision in a commit message.
