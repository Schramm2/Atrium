# DESIGN.md Format Reference

Read this file for Create, Update, Audit, and any Apply work that touches document structure, tokens, or validation.

## Compatibility baseline

Use the [Google Labs DESIGN.md specification](https://github.com/google-labs-code/design.md/blob/main/docs/spec.md) as the authority when it is available. `DESIGN.md` is an evolving Google Labs/Stitch alpha format, not a settled standard; this baseline was checked on 2026-07-31.

A compatible file contains optional YAML front matter for machine-readable tokens followed by Markdown rationale. Use `version: alpha` when the repo has no other compatible convention.

Prefer the top-level token groups `version`, `name`, `description`, `omitted`, `colors`, `typography`, `rounded`, `spacing`, and `components`.

## Token rules

- Use any valid CSS color supported by the target implementation, including hex, `rgb()`, `hsl()`, `oklch()`, and `color-mix()`. Prefer `#RRGGBB` when it represents the implementation and broad tooling support matters.
- Use semantic lowercase kebab-case names that match implementation roles.
- Use `omitted` only for intentionally inapplicable token sections. Keep unresolved values out of typed token slots and explain the decision under `## Open Questions`.
- Resolve references such as `{colors.primary}` and `{typography.label}`.
- Reference shared tokens from component variants instead of repeating raw values.
- Express component states as related variants such as `button-primary-hover` or `input-error`.
- Keep component properties close to `backgroundColor`, `textColor`, `typography`, `rounded`, `padding`, `size`, `height`, and `width`.
- Keep implementation behavior that has no compatible token representation, such as CSS custom-property resolution or gradients, in the relevant Markdown section.

```yaml
---
version: alpha
name: Example Product
description: Repo-local visual design contract for coding agents.
colors:
  primary: "#3367D6"
  on-primary: "#FFFFFF"
  surface: "#FFFFFF"
  on-surface: "#202124"
typography:
  body:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: "24px"
  label:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: "20px"
rounded:
  sm: "4px"
  md: "8px"
  lg: "16px"
spacing:
  sm: "8px"
  md: "16px"
  lg: "24px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
---
```

## Markdown order

Use recognized `##` headings in this order when they apply:

1. `Overview` or `Brand & Style`
2. `Colors`
3. `Typography`
4. `Layout` or `Layout & Spacing`
5. `Elevation & Depth` or `Elevation`
6. `Shapes`
7. `Components`
8. `Do's and Don'ts`

Keep each recognized heading unique. Place local guidance where its context stays clear:

- Put `Evidence Sources`, `Surface Map`, and `Voice & Content` under `Overview`.
- Put `Motion & Interaction` and `Accessibility & States` under `Components`.
- Put a local `## Open Questions` section after the recognized sections.

## Verification

Use the CLI when it is already available or network access is allowed. Record the package version or pinned dependency used, then inspect the JSON findings rather than treating a zero exit code as a clean review:

```sh
npx @google/design.md spec --rules
npx @google/design.md lint --format json DESIGN.md
npx @google/design.md diff --format json OLD_DESIGN.md DESIGN.md
npx @google/design.md export --format json-tailwind DESIGN.md
npx @google/design.md export --format dtcg DESIGN.md
```

The linter reports errors, warnings, and informational findings; a successful exit only means it found no errors. For repeatable CI, pin the package in the repository toolchain instead of resolving the latest alpha through `npx`.

When the CLI is unavailable, inspect YAML parsing, broken references, `colors.primary`, typography tokens, intentional omissions, duplicate headings, canonical section order, component token reuse, and WCAG AA text/background contrast manually. Record the gap instead of reporting a tool pass.
