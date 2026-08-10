# GitHub Actions Workflows

Most workflow entry points use `workflow_dispatch`; `build.yml` is reusable only. `release.yml` runs when a release tag is pushed.

| Workflow | Purpose |
| --- | --- |
| `build-devtest.yml` | Manual multi-runner development build with optional signing and artifact upload. |
| `build-macos.yml` | Manual Apple Silicon macOS build. |
| `build-test.yml` | Manual test build that calls the reusable macOS workflow. |
| `build.yml` | Reusable Apple Silicon macOS build used by other workflows. |
| `pr-main-check.yml` | Manual repository and version validation without a full build. |
| `release.yml` | Builds, ad-hoc signs, verifies, and publishes the Apple Silicon macOS release for a `vX.Y.Z` tag. |

The workflow YAML is authoritative for inputs, artifacts, secrets, runner versions, and signing behavior. Review the selected file before a release or any change to CI.

## Release scope

`release.yml` runs only for a pushed `vX.Y.Z` tag. The tag must match every application version and point to a commit on `main`. The workflow creates a draft release, verifies its updater assets, then publishes it. See [Releasing Notive](../../docs/RELEASING.md) before you push a release tag.

## DevTest scope

See [README_DEVTEST.md](README_DEVTEST.md) for the current matrix and inputs. The product's supported development target is macOS even though DevTest defines additional CI matrix entries.
