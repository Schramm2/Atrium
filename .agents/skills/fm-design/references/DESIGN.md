---
version: alpha
name: First Motive
description: The First Motive design doc — the shared visual design contract for First Motive artifacts, covering colour tokens, typography, layout, elevation, spacing, and component recipes with accessibility notes and do's/don'ts, so anyone designing or aligning an artifact keeps its styling consistent with the First Motive look. Grounded in the docs.firstmotive.ai web/ surface — a dark-aubergine investor/ops site with a static Docs reading surface and a live D1-backed Trackers surface.
colors:
  primary: "#7fa9b8"
  on-primary: "#1f2c33"
  surface: "#433b47"
  on-surface: "#e8e2d7"
  sage: "#9cb89e"
  on-sage: "#2a3a2c"
  lilac: "#9b8fb8"
  coral: "#d89b9f"
  on-coral: "#3d2628"
  surface-elev-1: "#4b434e"
  surface-elev-2: "#504954"
typography:
  body:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: "23px"
  heading-1:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif"
    fontSize: "37.5px"
    fontWeight: 700
    lineHeight: "41px"
  heading-2:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif"
    fontSize: "26.25px"
    fontWeight: 700
    lineHeight: "30px"
  heading-3:
    fontFamily: "Manrope, -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif"
    fontSize: "17.25px"
    fontWeight: 600
    lineHeight: "22px"
  label-mono:
    fontFamily: "'Anonymous Pro', ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: "12px"
    fontWeight: 700
    lineHeight: "16px"
rounded:
  sm: "4px"
  md: "8px"
  lg: "12px"
  pill: "999px"
spacing:
  sm: "8px"
  md: "16px"
  lg: "24px"
components:
  button-primary:
    backgroundColor: "{colors.sage}"
    textColor: "{colors.on-sage}"
    typography: "{typography.label-mono}"
    rounded: "{rounded.pill}"
    padding: "9px 18px"
  button-secondary:
    backgroundColor: "{colors.surface-elev-2}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-mono}"
    rounded: "{rounded.pill}"
    padding: "9px 18px"
  card:
    backgroundColor: "{colors.surface-elev-1}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.md}"
    padding: "1.25rem 1.5rem"
  tile:
    backgroundColor: "{colors.surface-elev-1}"
    textColor: "{colors.on-surface}"
    rounded: "6px"
    padding: "20px 24px"
  tag-warn:
    backgroundColor: "{colors.coral}"
    textColor: "{colors.on-coral}"
    typography: "{typography.label-mono}"
    rounded: "{rounded.pill}"
    padding: "2px 8px"
  tag-lilac:
    textColor: "{colors.lilac}"
    typography: "{typography.label-mono}"
    rounded: "{rounded.sm}"
    padding: "2px 8px"
---

## Overview

`web/` is a single-theme (dark aubergine, no light mode), no-build, no-framework HTML site: every page is hand-authored HTML with a shared `styles.css` plus a self-injecting nav shell (`web/nav.js`). It has two functionally distinct surfaces sharing one visual language — a static reading surface (**Docs**) and a live CRUD surface backed by Cloudflare D1 (**Trackers**). Read `CONTRIBUTING.md` for the writing-style rules that govern all copy on these pages; this file governs the visual layer only.

### Evidence Sources

- `web/styles.css` (1071 lines) — the shared token layer (`:root` custom properties) and the primitives every page inherits: `.fm-page-head`, `.fm-section*`, `.fm-tile*`, `.fm-table*`, `.fm-card*`, `.fm-tier*`, `.fm-pill*`, `.fm-cross`, `.fm-label`, `.fm-eyebrow`, the nav shell (`.fm-shell__*`), and the shared `.ppl-*` people-roster widget.
- `web/nav-manifest.js` + `web/nav.js` — site tree, sidebar/breadcrumb/prev-next generation, mobile drawer, search.
- `web/index.html`, `web/overview.html`, `web/system-design.html`, `web/capture-system.html`, `web/operating-model.html`, `web/why-now.html`, `web/poc*.html`, `web/reference.html`, `web/agent-mode.html`, `web/responsibility.html` — Docs surface pages, each with its own embedded `<style>` block and a local class prefix.
- `web/bom.html` (`hw-*`), `web/tracker.html` (`tr-*`), `web/people.html` + `web/people-view.js` (`ppl-*`) — Trackers surface, read/write against the Worker in `api/`.
- `web/rig/README.md` + `web/rig/*.config.mjs` + `web/rig/lib/` — a small diagram-as-code DSL (Node, no dependencies) that renders the architecture block diagrams embedded in `capture-system.html`.
- Adoption counts for shared classes, grepped directly across `web/*.html` (see Components — not all documented shared primitives are actually used; see below).
- WCAG contrast ratios computed directly from the hex/rgba values in `styles.css` against `--fm-bg` (see Accessibility & States).
- `CONTRIBUTING.md` (writing style, doc taxonomy) and `CLAUDE.md` (repo layout, editing semantics) for voice and structural conventions.

### Surface Map

| Surface | Pages | Character |
|---|---|---|
| **Docs** | `overview`, `why-now`, `system-design`, `capture-system`, `poc*`, `operating-model`, `responsibility`, `agent-mode`, `reference`, `index` | Static, read-only, canonical facts. Long-form prose, tier/constraint listings, rendered diagrams. Full-text searchable. |
| **Trackers** | `bom`, `tracker` (+ People tab), `people` (standalone host) | Live, interactive, D1-backed CRUD: inline edit, save bars, status selects, seed/discard actions. Excluded from search (`fulltext: false`) since their bodies are live data, not static text. |
| **Nav shell** | injected on every page by `nav.js` | Sidebar tree, top bar with breadcrumbs + search, mobile drawer, prev/next footer, persistent Agent Mode affordance. Identical across both surfaces — the one place visual rules are *not* allowed to diverge. |

**Don't flatten these into one style.** A Docs page invents no buttons, forms, or save state; a Trackers page is allowed heavier interactive chrome (switches, inline inputs, sticky save bars) that would be visual noise on a reading page.

## Colors

`--fm-bg: #433b47` (aubergine, sampled from the investor deck) is the one canonical surface — there is no light theme and no plan for one. Everything else is a translucent overlay or accent on top of it.

| Token | Value | Role |
|---|---|---|
| `colors.primary` (`--fm-steel`) | `#7fa9b8` | Primary highlight / "we are here" marker / RLDS references / link color / section numbers. **Not** the primary-action button color — see below. |
| `colors.on-surface` (`--fm-text`) | `#e8e2d7` | Warm-ivory body/heading text. |
| `colors.sage` (`--fm-sage`) | `#9cb89e` | Internal-process accent, T1/T2 cost figures, **and** the fill for primary CTA buttons (`Save`, `Initialize with seed data`). |
| `colors.lilac` (`--fm-lilac`) | `#9b8fb8` | Model/processing-layer accent, T3/future-tier accent. Foreground only — never used as a filled/inverse background anywhere in the codebase (there is no `fm-pill` variant for it, unlike steel/sage/coral). |
| `colors.coral` (`--fm-coral`) | `#d89b9f` | Warnings, decisions-needed, deferrals. |
| `on-primary` / `on-sage` / `on-coral` | `#1f2c33` / `#2a3a2c` / `#3d2628` | Dark text used only when steel/sage/coral are the *background* (filled pills, primary buttons). |

Text is a four-step opacity scale over `--fm-text`, not four separate colors: `--fm-text-muted` (72%), `--fm-text-subtle` (50%), `--fm-text-faint` (32%). Elevation surfaces work the same way — `--fm-bg-elev-1/2/3` are `rgba(255,255,255, 0.04/0.07/0.10)` washes, not fixed fills. `colors.surface-elev-1` (`#4b434e`) and `colors.surface-elev-2` (`#504954`) in the token block are the flattened equivalents (computed against the canonical `--fm-bg`, used so `card`/`tile`/`button-secondary` can reference a token instead of a bare literal) — this is a deliberate exception to "concrete hex in `colors`" above. **Author new CSS against the actual `rgba()` custom properties, not these flattened hex values** — the whole point of the opacity-over-surface approach is that elevation and muted-text tracks stay correct if `--fm-bg` ever changes; a hardcoded hex wouldn't.

**Colour carries semantic meaning — steel/sage/lilac/coral are not decoration.** Don't pre-color a tier chip, status chip, or accent border on data that isn't actually tier/status/warning-typed. `.fm-card-accent-*` / `.fm-tile-*` variants exist for exactly one job each: don't reach for "lilac because it looks nice here."

### Surface exceptions

None — color roles are identical across Docs and Trackers. Trackers add status-specific colors on top (e.g. `.ppl-st-core` = sage-tinted, `.ppl-st-candidate` = lilac-tinted) but they're instances of the same four accents, not a new palette.

## Typography

Two families only: **Manrope** (body/headings — matches the Ubundi parent brand) and **Anonymous Pro** (mono — tags, labels, section numbers, nav, code, anything that reads as "system chrome" rather than prose). `html, body` sets `font-size: 15px` directly (not the browser default 16px), so every `rem` value in `styles.css` is relative to 15px, not 16px — account for this when converting rem to px.

| Role | Family | Size | Weight | Notes |
|---|---|---|---|---|
| Body | Manrope | 15px / 1.55 | 400 | `p`, `.fm-prose`, `.fm-section-sub`. |
| H1 | Manrope | 37.5px (2.5rem) | 700 | letter-spacing -0.02em. Page/doc titles use `.fm-page-doctitle` instead, which is fluid (`clamp(28px, 3.4vw, 50px)`), not a fixed rem. |
| H2 | Manrope | 26.25px (1.75rem) | 700 | |
| H3 / H4 | Manrope | 17.25px / 14.25px | 600 | |
| Mono label/eyebrow | Anonymous Pro | ~10.5–13px | 700 | uppercase, letter-spacing 0.06–0.14em. This is a *recipe*, not one shared class — see Components. |

**Title Case for headings, in-card labels, and milestone text; sentence case for body prose** (`CONTRIBUTING.md` writing style, carried into the visual layer). Numbered doc sections use `## 01 — Section Name`, rendered as `.fm-section-num` (mono, steel) + `.fm-section-title` (sans, bold).

### Surface exceptions

None in font choice. Trackers use the same two families; the only difference is Trackers lean harder on mono (status pills, inline mono IDs, tabular numeric columns) because the content is data, not prose.

## Layout

- Docs pages wrap content in `.fm-container` (max-width 1280px, `padding: 2rem 2.5rem`). Trackers wrap in their own `.tr-page` / `.ppl-page` (max-width **1400px**) — an intentional, evidence-backed exception: operational tools get more horizontal room than reading pages, because tables and calendars need it and prose doesn't.
- Nav shell: fixed 264px sidebar (`--fm-sidebar-w`) + 52px sticky top bar (`--fm-topbar-h`); content column is offset `margin-left: var(--fm-sidebar-w)`. Below **880px** the sidebar becomes an off-canvas drawer (`.fm-drawer-open` toggles `transform: translateX(0)`) and content goes full-width.
- Spacing is **fluid, not a fixed 4/8pt scale.** Nearly every gap/padding value in the codebase is `clamp(min, Nvw, max)` (e.g. `clamp(16px, 1.8vw, 24px)`), so spacing scales with viewport width instead of breakpoint-jumping. The `spacing.sm/md/lg` tokens above are anchor values for tooling/export only — when adding new components, follow the existing `clamp()` pattern rather than a fixed px value.
- Trackers have one further breakpoint at 900px (calendar grid collapses from 5/7 columns to 1, weekday labels move inline into each day cell) — narrower than the nav shell's 880px, so on some widths the sidebar has already gone to drawer mode while the calendar is still in wide-grid mode. Not a bug, just two independently-tuned breakpoints; don't assume they're the same number.

## Elevation & Depth

Depth is expressed as **light added on top of the dark surface**, not shadows cast by surfaces — `--fm-bg-elev-1/2/3` are `rgba(255,255,255, 0.04/0.07/0.10)` washes plus a 1px `--fm-border` (10% ivory) or `--fm-border-strong` (20%). This reads as "how much is this raised" without any drop shadow at all for ordinary cards, tiles, or table wraps.

`--fm-shadow-card` (`0 4px 12px rgba(0,0,0,0.18)`) is reserved for content that floats **above** the page flow — the nav search-results dropdown and the persistent Agent Mode pill — not for everyday cards. Sticky chrome (top bar, save bars) uses `background: var(--fm-bg-overlay)` + `backdrop-filter: blur(8px)` instead of an opaque fill + shadow.

Stacking order is deliberately layered so the mobile drawer always wins and the Agent Mode pill never floats over it: sidebar `z:30` > backdrop `z:25` > top bar / save bar `z:20` > Agent Mode pill `z:15`. Keep new fixed/sticky elements inside this order rather than picking an arbitrary z-index.

## Motion

Transitions are short (0.12–0.22s, `ease`) and exist to clarify a state change — hover lift on tiles (`translateY(-2px)`), sidebar slide, chevron rotation on disclosure, switch-thumb slide, search dropdown, prev/next hover border. There is no entrance animation, scroll-triggered reveal, or decorative loop anywhere in the codebase — keep it that way; motion here answers "what just changed," not "look here."

`prefers-reduced-motion: reduce` is honored in `styles.css` (tile hover, nav shell sidebar/backdrop/chevron/agent pill), but **not** in any per-page embedded `<style>` block — `system-design.html` alone defines 12 of its own `transition:` rules with no reduced-motion guard, and `bom.html`, `capture-system.html`, `poc-sixty60.html`, `reference.html`, `tracker.html`, `why-now.html`, `agent-mode.html`, `poc.html` all define local transitions the same way. New page-local hover/disclosure motion should either stay this subtle (so the gap is low-risk) or add its own reduced-motion guard — don't assume the shared stylesheet's query covers it.

## Shapes

Radius scale: `sm` 4px (chips, small badges), `md`/default 8px (cards, table wraps, inputs), `lg` 12px (unused directly by any current component but defined for larger surfaces), and an unscaled **999px pill** for tags, status chips, and every button. `.fm-tile` uses a one-off 6px radius, slightly tighter than the `md` default — intentional per its own comment ("the unification target"), not an inconsistency to "fix" in isolation.

Borders do double duty as depth *and* as the tier/accent signal: `.fm-tile`/`.fm-card-accent-*`/`.tr-lane-*` all key their identity off a 3px left border in one of the four accent colors, with the rest of the border staying neutral. Diagrams (the rig block diagrams on `capture-system.html`) are the one place shape comes from code, not CSS — see `web/rig/README.md`: blocks are laid out with CSS Grid, arrows are SVG paths computed at runtime from `getBoundingClientRect()`, and the diagram degrades gracefully to blocks-with-no-connectors if JS is off.

## Components

### The shared layer is thinner than it looks

`styles.css` defines a full primitive set, but adoption across the 14 shipped pages is uneven — grepped directly:

| Class | Files using it | Status |
|---|---|---|
| `.fm-page-head` | 14 / 14 | Universal — every page's title block. |
| `.fm-section*` | 10 / 14 | The real workhorse for section headers/numbering. |
| `.fm-tile*` | 3 | Home page + a couple others — "the unification target" per its own CSS comment. |
| `.fm-table*` | 2 | |
| `.fm-prose` | 2 | |
| `.fm-tier`, `.fm-pill` | 1 each | |
| `.fm-card`, `.fm-cross`, `.fm-label`, `.fm-eyebrow` | **0** | Defined, never used. Every page that wants a card, a cross-reference link, or a mono eyebrow label hand-rolls its own local version instead (`op-tier`, `av-constraint-row`, `cs-*` blocks, `tr-lane-head`, `hw-cat`, `ppl-count` — each independently implementing the same "mono, uppercase, tracked, muted" eyebrow recipe under a different class name). |

**Treat `.fm-page-head` and `.fm-section*` as the only truly enforced shared chrome.** Everything else — cards, eyebrows, tags — is a *recipe* (mono font + uppercase + 0.06–0.14em tracking + accent color, or elev-1 bg + 1px border + 8px radius) that each page currently reimplements locally rather than a class to reuse as-is. When adding a new page, prefer copying the recipe from the nearest sibling page over reaching for `.fm-card`/`.fm-cross` — they exist but nothing currently renders through them, so there's no "does this still look right everywhere" safety net if their behavior needs to change.

### Per-page local prefixes

Every Docs/Trackers page beyond the shared shell scopes its own CSS under a short local prefix, layered on top of the shared `fm-` primitives and tokens:

`op-` (overview, operating-model — tier cards), `av-` (system-design — constraint/axis disclosure rows, also reused by capture-system), `cs-` (capture-system — rig diagram chrome), `hw-` (bom.html — hardware tracker), `tr-` (tracker.html — calendar/roadmap/backlog), `ppl-` (people-view.js — shared roster widget, mounted in both `people.html` and the tracker's People tab).

This is the working convention, not an accident — it's how 14 hand-authored pages avoid class collisions without a build step or CSS modules. New pages should pick their own 2–4 letter prefix rather than extending an existing page's prefix or adding more to the shared `fm-` layer.

### Buttons

There is no shared `.fm-btn`. `web/bom.html`'s `.hw-btn` and `web/styles.css`'s `.ppl-btn` are **byte-for-byte identical** (same padding `9px 18px`, `border-radius: 999px`, mono 700 uppercase, `.primary` variant = sage fill + `#2a3a2c` text, hover = `filter: brightness(1.06)`). Treat this recipe as the de facto standard button when adding a new interactive surface: pill radius, mono uppercase label, neutral `elev-2` bg + `border-strong` by default, sage fill for the one primary/constructive action per view. Don't invent a third variant of this same button — copy the existing recipe.

### Tags, pills, and status chips

Mono, uppercase, tracked, small (10–13px), usually pill-radius. Used for tier codes (`.fm-tier-t1..t4`), status ("we are here" / northstar / future / warn via `.fm-pill-*`), and Tracker-specific status (`.ppl-st-*`, `.tr-week-block`). **Listed-row patterns (mono tag · name · description · status) scale better than cards for scannable comparisons** — used on Tiers, Constraints, Considered-and-Rejected, and Risks; reach for this over a card grid whenever the content is a comparison list rather than a set of independent reads.

### Disclosure

Expandable rows (constraint rows on System Design, month/week rows on the tracker calendar) use a chevron (`›`) that rotates 90° open, with `aria-expanded` wired on the interactive element (`av-constraint-row` is a `<button>`) — keep this pattern (real button + aria-expanded), not a bare `<div onclick>`, for any new disclosure.

### Tiers

Active tier = sage-tinted background + border + a `Target` pill; inactive tiers stay neutral (`.op-tier` vs `.op-tier.target`). Used on Overview and System Design — the one place in the codebase a single accent color (sage) is hardwired to mean "this is the one that's active," independent of the general "sage = internal process" rule elsewhere.

### Accessibility & States

Computed directly from the token values against `--fm-bg` (#433b47):

| Pair | Contrast | WCAG AA (normal text, 4.5:1) |
|---|---|---|
| `--fm-text` on bg | 8.33:1 | Pass (AAA too) |
| `--fm-text-muted` (72%) on bg | 5.20:1 | Pass |
| `--fm-sage` on bg | 4.99:1 | Pass |
| `--fm-coral` on bg | 4.66:1 | Pass |
| `--fm-steel` on bg | **4.23:1** | **Fails** normal-text AA (passes 3:1 large-text) |
| `--fm-lilac` on bg | **3.59:1** | **Fails** normal-text AA (passes 3:1 large-text) |
| `--fm-text-subtle` (50%) on bg | **3.37:1** | **Fails** normal-text AA (passes 3:1 large-text) |
| `--fm-text-faint` (32%) on bg | **2.25:1** | **Fails** even large-text AA — decorative use only |

Filled-pill/button pairs (dark text on a light accent fill) are comfortably safe: `on-primary` on steel 5.64:1, `on-sage` on sage 5.61:1, `on-coral` on coral 6.05:1 — all pass AA for normal text. The failures above are specifically accent/muted colors used *as text on the aubergine surface*, not the inverse (accent-as-background) pairs.

Steel and lilac are both used as small (~12–13px, not "large text" by WCAG's definition) foreground text in several places — `.fm-cross a` links, `.fm-section-num`, `.tr-week-label`, `.av-constraint-axis-key` — where they read below AA for normal text. This is existing, shipped behavior, not a regression to fix reflexively; flagged in Open Questions rather than Do's/Don'ts because reflowing every steel/lilac text instance to `--fm-text-muted` would be a real visual change, not a bug fix.

**Focus states mostly suppress the native outline and rely on a border-color change instead** (`outline: none; border-color: var(--fm-border-accent)` — seen in `.hw-search`, `.hw-in`, `.ppl-in`, `.tr-edit-in`, and the person/role pickers across both Docs and Trackers). A handful of components do the more visible thing correctly: `.fm-page-back`, `.tr-switch`, and `.fm-copy` (agent-mode.html) use `:focus-visible { outline: 2px solid var(--fm-steel); outline-offset: 2px; }`. When adding a new focusable control, prefer the visible-outline pattern over the border-color-only one — see Open Questions.

## Voice & Content

Governed primarily by `CONTRIBUTING.md` — read it in full before writing any UI copy. Visual-layer specifics observed in shipped pages:

- Empty/placeholder states use italic, faint text (`.placeholder` modifier classes: `tr-month-title.placeholder`, `tr-week-title.placeholder`, `tr-day-goal.placeholder`) rather than a dedicated empty-state illustration or block.
- A first-run empty database renders an inline action inside the banner itself — `banner("info", 'Database is empty. <button id="hw-seed">Initialize with seed data</button>')` — not a separate empty-state screen.
- Read-only/error/info states share one `.banner`/`.tr-banner`/`.ppl-banner` pattern: hidden by default, coral border for errors, steel border for info, dismiss/action button inline on the right.
- Numbers: investor-facing figures round (`<$40k`, per `CONTRIBUTING.md`); spec- and tracker-facing figures stay precise and right-aligned with `font-variant-numeric: tabular-nums`.
- Button/action copy is short, imperative, Title Case where it's a UI label (`Save to Database`, `Discard`, `Add Item`) — matches the heading Title Case rule, not the sentence-case body-prose rule.

## Do's and Don'ts

- **Do** offset new Docs content with `.fm-section-num` + `.fm-section-title`, not a bare `<h2>` — it's the one primitive 10/14 pages already share.
- **Do** pick a new 2–4 letter local class prefix for a new page's own styling; don't extend `fm-` or another page's prefix.
- **Do** use `clamp(min, Nvw, max)` for new spacing/type sizing; don't hardcode a fixed px value where the surrounding code uses a fluid one.
- **Do** reuse the `.hw-btn`/`.ppl-btn` button recipe (pill, mono uppercase, sage-fill primary) for any new interactive surface.
- **Do** keep new sticky/fixed elements inside the existing z-index order (sidebar 30 > backdrop 25 > bars 20 > Agent Mode pill 15).
- **Don't** pre-color a chip or border with sage/steel/lilac/coral unless the data is actually tier/status/warning-typed — color carries meaning here.
- **Don't** assume `.fm-card`, `.fm-cross`, `.fm-label`, or `.fm-eyebrow` are the way something is currently rendered — they exist in `styles.css` but zero shipped pages use them; check the nearest sibling page's local classes instead.
- **Don't** add scroll-triggered reveals, entrance animation, or decorative loops — the entire site currently has none.
- **Don't** leave dead CSS/JS behind when removing the markup that used it (existing repo convention, `CLAUDE.md`).
- **Don't** widen a Docs page past `.fm-container`'s 1280px or narrow a Trackers page below its 1400px wrapper without a specific reason — the split is deliberate (reading vs. data-density).

## Open Questions

- **Button consolidation.** `.hw-btn` (bom.html) and `.ppl-btn` (styles.css) are identical. If a third tracker-style surface is added, promote this to a shared `.fm-btn` in `styles.css` rather than a third copy-paste — currently there's no single source of truth to edit if the recipe needs to change (e.g. a hover-state or contrast fix).
- **Dead shared primitives.** `.fm-card`, `.fm-cross`, `.fm-label`, `.fm-eyebrow` are defined but unused in any shipped page. Either retire them or point at least one live example at each — otherwise they'll drift silently out of sync with the recipes pages actually hand-roll.
- **Steel/lilac as small body text.** Both read below WCAG AA (4.23:1 / 3.59:1) for normal-size text and are used that way in several places (cross-ref links, section numbers, mono labels). Needs a human call: accept as an intentional low-emphasis/accent-only text tier, or bump the color/size in those specific spots.
- **Focus-visible coverage.** Most form inputs across Docs and Trackers suppress `outline` in favor of a subtle border-color change; only three components use a real visible-outline `:focus-visible`. Worth a deliberate pass to standardize on the visible-outline pattern, especially for Trackers where keyboard-only editing is a realistic path.
- **Reduced-motion coverage on page-local styles.** Every per-page `<style>` block defines its own transitions with no `prefers-reduced-motion` guard (only the shared `styles.css` has one). Given how subtle the existing motion already is, this may be a non-issue in practice — worth a human call on whether it's worth the boilerplate to guard each one.
