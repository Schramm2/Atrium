# GitHub Actions Workflows

All workflow entry points use `workflow_dispatch`; `build.yml` is reusable only.

| Workflow | Purpose |
| --- | --- |
| `build-devtest.yml` | Manual multi-runner development build with optional signing and artifact upload. |
| `build-macos.yml` | Manual Apple Silicon macOS build. |
| `build-test.yml` | Manual test build that calls the reusable macOS workflow. |
| `build.yml` | Reusable Apple Silicon macOS build used by other workflows. |
| `pr-main-check.yml` | Manual repository and version validation without a full build. |
| `release.yml` | Manual release preparation that creates a draft GitHub release and calls the reusable macOS workflow. |

The workflow YAML is authoritative for inputs, artifacts, secrets, runner versions, and signing behavior. Review the selected file before a release or any change to CI.

## Release scope

`release.yml` reads the version from `frontend/src-tauri/tauri.conf.json`, creates or selects a version tag, then prepares a draft release. It can affect GitHub state. Do not run it for ordinary local verification.

## DevTest scope

See [README_DEVTEST.md](README_DEVTEST.md) for the current matrix and inputs. The product's supported development target is macOS even though DevTest defines additional CI matrix entries.
