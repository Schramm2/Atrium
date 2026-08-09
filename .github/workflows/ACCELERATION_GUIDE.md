# Historical CI Acceleration Notes

> This document records a retired acceleration proposal. It is not the source of truth for the current workflows or Cargo features.

The maintained macOS application configures Metal and Core ML through `frontend/src-tauri/Cargo.toml`. The workflow files remain the source of truth for CI build arguments. Before changing a workflow, check its target, its requested Cargo features, and the matching Cargo manifest together.

The main Tauri crate exposes `metal` and `coreml` features. `llama-helper` separately exposes CUDA and Vulkan features for CI configuration. The main crate does not define the CUDA, Vulkan, HIPBLAS, or OpenBLAS paths described in older CI notes.
