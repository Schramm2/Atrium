# GPU Acceleration

The supported macOS build configures `whisper-rs` with Metal and Core ML. The relevant dependency is in `frontend/src-tauri/Cargo.toml` under the macOS target dependencies.

No supported GPU-detection path exists for the main Notive desktop bundle. `llama-helper` still exposes CUDA and Vulkan features for CI configuration, but the main Tauri crate does not expose CUDA, Vulkan, ROCm, or OpenBLAS features. Do not use the removed `dev-gpu.sh`, `build-gpu.sh`, or `TAURI_GPU_FEATURE` instructions from older revisions.

Use the normal desktop commands from `frontend/`:

```bash
pnpm run tauri:dev
pnpm run tauri:build
```

The package also defines explicit `tauri:dev:metal`, `tauri:dev:coreml`, `tauri:build:metal`, and `tauri:build:coreml` commands for targeted development checks. They enable the corresponding Cargo feature in addition to the macOS defaults.
