---
name: create-design-md
description: Create, update, audit, and apply repo-local DESIGN.md contracts grounded in repository UI evidence. Use for meaningful frontend work without a design contract, design-system drift, or UI reviews that need stable product taste across agent sessions.
disable-model-invocation: true
---

# Create DESIGN.md

Build and enforce an agent-readable design contract from product evidence.

## Route the work

1. Read the nearest repo instructions, existing `DESIGN.md`, README, and frontend guidance.
2. Select the Create, Update, Audit, or Apply branch below.
3. For Create, Update, Audit, or an Apply change that alters tokens or document structure, read [references/design-md-format.md](references/design-md-format.md) before working with the contract.
4. When screenshots, generated drafts, reference sites, or external `DESIGN.md` files shape the result, read [references/reference-design-review.md](references/reference-design-review.md).

## Create

1. Inspect the implemented UI, screenshots, routes, CSS variables, theme files, Tailwind configuration, component examples, brand rules, and explicit product direction that exist. Record each inspected source and its consequence for the contract.
2. Name each product surface, its role, and any intentional exception before deriving shared rules.
3. Extract only supported tokens from implementation. Omit unresolved values and record the decision needed under `Open Questions`; use the compatible `omitted` field for intentionally inapplicable token sections.
4. Draft the YAML tokens and Markdown rationale in the compatible format.
5. Add `DESIGN.md` to the repo's frontend instruction path.
6. Run the available linter and compare meaningful visual rules against real screens.

Complete when every applicable Quality Gate item passes or appears as an explicit open question, and the verification evidence names the command, screen, screenshot, or manual check used.

## Update

1. Compare the current `DESIGN.md` with the current implementation and evidence.
2. Preserve supported decisions and change tokens or guidance only where evidence changed.
3. Record design-impacting changes and put unresolved durable contradictions under `Open Questions`.
4. Run the available linter and compare affected rules against affected screens.

Complete when the contract matches current evidence, every changed decision is accounted for, every applicable Quality Gate item passes or becomes an open question, and verification evidence is recorded.

## Audit

1. Run the available linter and inspect every error, warning, and informational finding.
2. Evaluate every Quality Gate item against the file and repository evidence.
3. Report each failure with its evidence, affected surface, severity, and smallest useful remedy.

Complete when every Quality Gate item has a recorded result and every failure has actionable evidence. State any lint or inspection gap.

## Apply

1. Read `DESIGN.md` and identify the rules and surface exceptions that govern the requested UI change.
2. Change the smallest relevant theme, CSS, or component files.
3. Check the result against the named rules, supported states, responsive behavior, and affected real screens.
4. Update `DESIGN.md` when the implementation establishes or changes a durable design decision; put unresolved durable gaps under `Open Questions` and report transient gaps in the handoff.

Complete when the implementation follows the applicable contract, new patterns are documented or flagged, and relevant tests, browser checks, or screenshot checks have recorded results.

## Quality Gate

- Evidence sources name the files, routes, screenshots, Figma nodes, commands, or references inspected.
- The surface map preserves distinct marketing, auth, dashboard, admin, studio, docs, mobile, or embedded roles that the product exposes.
- YAML tokens use semantic names, portable values, resolved references, and implemented component roles.
- Intentionally inapplicable token sections use the compatible `omitted` field; unresolved values never occupy typed token slots.
- Recognized Google-compatible sections follow canonical order; local guidance uses clear subsections or the final `Open Questions` section.
- Colors, typography, spacing, shapes, elevation, components, responsive behavior, interaction, and motion match available evidence.
- Components define relevant hover, focus, active, selected, disabled, loading, empty, and error behavior.
- Text and background pairs meet the required contrast, focus remains visible, and reduced-motion behavior preserves state clarity.
- Operational screens retain task-focused scale, density, and copy; marketing treatment stays tied to marketing surfaces.
- UI copy covers labels, casing, errors, empty states, loading text, toasts, destructive confirmations, numerals, and product terms where relevant.
- Generated or external drafts remain provisional until the target product's evidence confirms them.
- Durable uncertainty appears under `Open Questions` with enough context for a human decision.
- Meaningful visual changes have a browser, screenshot, or human-review path.
- Linter findings are recorded and resolved, accepted with rationale, or carried as an explicit open question.
- Repo instructions direct frontend agents to read `DESIGN.md` before edits.
