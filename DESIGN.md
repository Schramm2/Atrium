# Notive Design System

<!-- impeccable:design-schema 1 -->

## Direction

Notive is a **conversation ledger**: a calm native workspace where capture, review, recall, and writing stay visible as equal parts of one local workflow. The interface uses a stable macOS sidebar and a wide work canvas. It avoids marketing-style hero panels, stacked cards, and large unused fields. Brand identity appears through exact color roles, type hierarchy, small line details, and canonical marks.

The interface mode is **Operate**. Fast scanning, reliable state, keyboard access, and transcript readability take priority over decoration.

## Shared Structure

- Keep one `NavigationSplitView` shell for both themes.
- Use a 252–300 point source-list sidebar. Keep native list selection and keyboard behavior.
- Put global search in the toolbar. Do not repeat search inside page content.
- Give each destination a compact page header with a title, one factual sentence, and relevant actions.
- Use the full detail width. Reading surfaces use a 900–1,080 point measure; operational lists and transcripts can extend to 1,280 points.
- Use 4, 8, 12, 16, 24, 32, and 48 point spacing steps.
- Use 8 point radii for controls and compact surfaces, 12 points for large sections, and capsules only for status and short primary actions.
- Use borders and tonal fills before shadows. Shadows are reserved for floating popovers and overlays.

## Typography

Use Manrope when it is installed. Fall back to the macOS system family. Use system rounded or monospaced digits only for timing, status codes, and technical metadata.

- Page title: 30–34 points, semibold, tight leading.
- Section title: 18–22 points, semibold.
- Body: 14–16 points, regular.
- UI label: 12–13 points, semibold.
- Status label: 11–12 points, semibold. Use uppercase only for short system states.
- Transcript text: 14–15 points with generous line spacing. Timestamps remain compact and monospaced.

Do not use display typography in repeated cards, the sidebar, settings rows, or transcript controls.

## Ubundi Theme

Ubundi is open, precise, human, and quietly confident.

- Navy `#2F3498`: primary actions, selection identity, focus, and key navigation state.
- Deep navy `#1B1F44`: dark-mode anchor and high-contrast text.
- Blue `#7188BE`: informational state and secondary emphasis.
- Electric `#C183E6`: AI or generated-content state only.
- Salmon `#D77A85`: destructive or error state with a text or icon label.
- Amber `#F3C57A`: pending or attention state.
- Light surfaces: white and `#F5F5F5`, with `#DADCE0` borders.
- Dark surfaces: deep navy-black neutral surfaces. Keep Navy and Blue visible; do not wash the whole canvas purple.

Use the canonical Ubundi navy wordmark in identity areas. Do not recolor or distort it.

## First Motive Theme

First Motive is grounded, technical, warm, and exact.

- Aubergine `#433B47`: canonical main surface.
- Warm ivory `#E8E2D7`: primary text.
- Steel `#7FA9B8`: information, navigation markers, and links.
- Sage `#9CB89E`: the one constructive primary action.
- Lilac `#9B8FB8`: generated or processing state, never a broad fill.
- Coral `#D89B9F`: warning or destructive state.
- Raised surfaces: 4%, 7%, and 10% ivory washes over aubergine.
- Borders: 10% or 20% ivory.

First Motive is a dark brand theme. Its canonical aubergine surface remains dark in all macOS appearances. Use the canonical mark and wordmark without recoloring.

## Component Rules

### Sidebar

- Show the Notive mark and active company identity at the top.
- Keep four primary workspace destinations equal in weight: Home, Ask Notive, Dictation, and Meeting Notes.
- Separate saved meetings with a clear section label and compact title/date rows.
- Keep capture and import actions in a bottom action area. Do not repeat a second theme selector in page content.
- Replace the crowded segmented theme control with a compact theme menu. Keep appearance control adjacent.

### Page Header

- Use one concise heading and one support line.
- Align page actions to the trailing edge when space permits; wrap them into an overflow menu before the title becomes compressed.
- Use a short privacy status label where external-data boundaries matter.

### Sections and Lists

- Prefer one flat section with a border and tonal fill over cards nested inside cards.
- Use dividers and aligned columns for repeated data.
- Keep empty states actionable and concise. Include one next action.
- Use accent edges, icons, or labels only when they encode a real workflow state.

### Controls

- Use one prominent action per region.
- Always pair destructive color with a destructive label or system icon.
- Keep buttons at least 28 points high. Primary workspace actions use 32–36 points.
- Provide hover, pressed, focus, disabled, loading, selected, warning, and error states.

## Screen Contracts

### Home

Home is a balanced command center. Show four equal workflow tiles: Capture, Ask, Dictate, and Review Notes. Follow them with recent meetings and a compact local-privacy status row. Do not use one oversized recording hero.

### Ask Notive

Keep the question composer at the top. Put scope and date limits beside or directly below it. Use the remaining space for a clear empty state or a readable answer with source citations. Make the local or external evidence boundary visible before submission.

### Dictation

Show listening state, shortcut, microphone, and on-device processing as one coherent status surface. Keep the latest result in a dedicated reading area with Copy as the clear secondary action.

### Meeting Notes

Use a searchable, date-aware meeting list with title, date, transcript/notes status, and one clear open action. Do not render it as an almost empty raw `List`.

### Meeting Workspace

Protect the meeting title from action overflow. Keep Play and Save visible; place Retranscribe, Open Recording, and Delete in an overflow menu. Use a stable content switcher for Transcript, Summary, and Notes. Give transcript rows a narrow timestamp column, optional speaker label, readable text measure, and calm separators.

### Settings

Keep the native Settings scene and toolbar. Use consistent section surfaces, row alignment, labels, helper text, and brand-aware tint across all eight tabs. Appearance must preview both company themes and explain First Motive's fixed dark brand surface.

### Onboarding

Use the selected brand mark, a short three-step progress indicator, and one focused permission or workspace decision per step. Keep permission reasons factual. Never make optional access look required.

## Motion and Accessibility

- Use 120–220 ms state transitions only to explain selection, disclosure, progress, or insertion.
- Respect Reduce Motion and avoid entrance choreography.
- Preserve VoiceOver names, values, and actions.
- Use visible keyboard focus and native tab order.
- Meet WCAG AA contrast for normal text. Do not use First Motive Steel, Lilac, or faint ivory as small body text on aubergine.
- Do not rely on color alone for recording, warning, selection, provider boundary, or completion state.

## Canonical Assets

The implementation may copy these source assets into the app bundle without modifying the originals:

- Ubundi wordmark: `Ubundi/01_Brand/GitHub-Profile/ubundi-logo-navy.png`
- Ubundi mark: `Ubundi/01_Brand/Community/ubundi-logo.png`
- First Motive mark: `First Motive/01_Brand/first-motive-mark-dark-on-white.png`
- First Motive light and dark wordmarks: `First Motive/01_Brand/firstmotive-wordmark-light.svg` and `firstmotive-wordmark-dark.svg`
- First Motive atmospheric reference: `First Motive/01_Brand/first-motive-mac-mini-desktop-and-login-3440x1440.png`

Use the atmospheric reference only as a restrained onboarding or empty-state texture. It must not reduce operational contrast or become a full-screen decoration.

## Anti-Patterns

- No large decorative hero card on Home.
- No card grids for simple settings or transcript rows.
- No nested cards.
- No ambient accent color without semantic meaning.
- No fixed narrow content column that leaves most of a large window unused.
- No title compression caused by many inline actions.
- No custom replacement for native macOS selection, menus, toolbars, or Settings-window behavior when SwiftUI already provides it.
