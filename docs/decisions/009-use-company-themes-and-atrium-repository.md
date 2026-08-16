# ADR-009: Use company themes and the Atrium repository

## Status

Accepted

## Date

2026-08-16

## Context

Atrium serves Ubundi and First Motive. The third Atrium theme was adapted from AuthKit and added another visual identity that did not represent either company. The GitHub repository still used the retired `notive` name even though the product, application bundle, and Swift targets use Atrium.

Existing installations can contain `atrium` in the preserved theme and application-icon preference keys. GitHub redirects renamed repository URLs, but the updater and release workflow should use the current repository name directly.

## Decision

Keep only the Ubundi and First Motive interface themes. Make Ubundi the default. Treat a stored theme or application-icon value that is no longer valid as Ubundi.

Remove the AuthKit-derived palette, selectable Atrium identity, and its runtime PNG assets. Keep `Atrium.icns` because Atrium remains the product and application name.

Rename the GitHub repository from `Schramm2/notive` to `Schramm2/Atrium`. Update the release script, updater default, tests, and current documentation to use the new repository name.

## Alternatives considered

### Keep Atrium as a third theme

This keeps the previous default but adds a non-company identity to a workspace intended for two companies.

### Rename the product theme but keep its palette

A different label would hide the AuthKit source without reducing theme choice or maintenance.

### Keep the old repository name

GitHub compatibility made this possible, but the repository would continue to disagree with the product and source names.

## Consequences

- Theme selection, onboarding, application-icon selection, and verification cover two themes.
- Existing `atrium` preference values move to Ubundi when Atrium next runs.
- First Motive remains dark-only. Ubundi follows the selected macOS appearance.
- Existing clone and release URLs redirect through GitHub after the repository rename.
- Bundle identifiers, local data paths, preference keys, recordings paths, and the legacy update channel do not change.

## Supersedes

This decision supersedes the Atrium-theme and repository-name decisions in ADR-007. ADR-008 remains accepted.
