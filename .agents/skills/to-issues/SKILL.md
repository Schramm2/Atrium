---
name: to-issues
description: Converts a plan, spec, PRD, or conversation into tracer-bullet Markdown tickets with blocking edges. Use when work must be captured as agent-ready documents.
disable-model-invocation: true
---

# To Issues

This compatibility alias follows the current `/to-tickets` behavior. Break a plan, spec, PRD, or conversation into a set of **Markdown tickets** — tracer-bullet vertical slices, each declaring the tickets that **block** it.

Use local Markdown files only. Store work under `.scratch/<feature-slug>/`; the spec is `spec.md` and tickets are one file per item under `issues/`. Do not publish tickets to GitHub Issues or another external tracker.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference, read the local Markdown path. For a feature reference, read `.scratch/<feature-slug>/spec.md` and the relevant ticket files, including their `## Comments` sections.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Ticket titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) — vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any prefactoring should be done first

</vertical-slice-rules>

Give each ticket its **blocking edges** — the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change — rename a column, retype a shared symbol — whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand–contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a ticket blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket — green is promised only there.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct — does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

### 5. Write the tickets to Markdown files

After the user approves the breakdown, write one Markdown file per ticket:

- Path: `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order.
- Each file must include `Status: ready-for-agent` and a `Blocked by:` line with the numbers and titles of its blockers.
- Create the directory if needed. Do not create a combined `tickets.md` file.

Do not modify a parent document.

<local-ticket-template>

# 01 — <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective — not a layer-by-layer implementation list.

**Blocked by:** the titles of the tickets that gate this one, or "None — can start immediately".

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

# <Ticket title>

...

</local-ticket-template>

Do not include external tracker IDs, labels, comments, or URLs. Local
`## Comments` sections and relative Markdown links are allowed. Avoid specific
implementation file paths or code snippets unless a prototype produced a
decision that needs the exact shape.

Work the frontier one ticket at a time with `/implement`, clearing context between tickets.
</content>
