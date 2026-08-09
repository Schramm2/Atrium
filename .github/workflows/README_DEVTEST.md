# DevTest Build Workflow

`build-devtest.yml` is a manually dispatched build workflow for development checks. It has two inputs:

- **Sign the build**: disabled by default.
- **Upload build artifacts**: enabled by default.

The workflow currently defines these build matrix entries:

| Runner | Target | Bundle argument |
| --- | --- | --- |
| macOS | `aarch64-apple-darwin` | default Tauri bundle |
| Windows | `x86_64-pc-windows-msvc` | default Tauri bundle |
| Ubuntu 22.04 | `x86_64-unknown-linux-gnu` | `deb` |
| Ubuntu 24.04 | `x86_64-unknown-linux-gnu` | `appimage,rpm` |

It installs frontend dependencies, builds the `llama-helper` sidecar, runs the Tauri build, and uploads artifacts only when the upload input is enabled. The repository's supported development target remains macOS; the other matrix entries are CI configuration, not a supported local setup guide.

Run it from GitHub Actions by selecting **Build and Test - DevTest**, choosing a branch, setting the two inputs, and selecting **Run workflow**.
