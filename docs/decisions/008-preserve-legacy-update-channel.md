# ADR-008: Preserve the legacy Notive update channel

## Status

Accepted

## Date

2026-08-15

## Context

Atrium 0.9.2 completed the application rebrand described in ADR-007. Notive 0.9.1 installations still request `Notive-<version>-arm64.dmg`, expect `Notive.app` inside the disk image, replace `/Applications/Notive.app`, and relaunch that path. The 0.9.2 release published only Atrium-named artifacts, so the automatic update failed before users could reach the new updater.

A one-time manual installation is avoidable. Existing installations can remain compatible without changing the visible product name, bundle identifier, executable, source targets, or local data paths.

## Decision

Publish one additional update-only disk image with every release: `Notive-<version>-arm64.dmg`. It contains the signed Atrium application bundle under the compatibility filename `Notive.app`.

The updater selects its channel from the running bundle path:

- `/Applications/Atrium.app` downloads Atrium-named assets and replaces Atrium.
- `/Applications/Notive.app` downloads Notive-named assets and replaces Notive.

Both channels run the same Atrium binary and show the Atrium product name. The Notive disk image is an updater compatibility artifact, not a second product or manual installer.

## Alternatives considered

### Keep the manual transition

ADR-007 accepted one manual update. The released transition instead looked like an internet failure and broke the established in-application update path.

### Rename all release artifacts back to Notive

This would keep old installations working but would make new Atrium installations and manual downloads use the retired product name.

### Move a legacy installation to Atrium.app during an update

The running 0.9.1 updater controls the replacement and relaunch paths. Changing those paths requires code that 0.9.1 does not contain. Keeping the installed outer bundle filename is the smallest reliable bridge.

## Consequences

- Existing Notive installations update automatically and remain at `/Applications/Notive.app`.
- New Atrium installations use `/Applications/Atrium.app` and Atrium-named release assets.
- Release packaging, CI, and release verification must produce and verify both versioned disk images.
- The release has one extra private asset and no second build.
- The clean-break updater transition in ADR-007 is superseded. The rest of ADR-007 remains accepted.

## Supersedes

This decision supersedes only the clean-break updater transition in ADR-007.
