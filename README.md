<div align="center">
    <h1>Ubundi Meet</h1>
    <p><strong>Privacy-First AI Meeting Assistant</strong></p>
    <p>
        <img alt="License" src="https://img.shields.io/badge/License-MIT-blue">
        <img alt="Supported OS" src="https://img.shields.io/badge/Supported_OS-macOS,_Windows,_Linux-white">
    </p>
    <p>Open Source • Privacy-First • Local-First</p>
</div>

A privacy-first AI meeting assistant that captures, transcribes, and summarizes meetings entirely on your local infrastructure. No data leaves your machine unless you choose an external AI provider for summaries.

Ubundi Meet is a personal fork of [Meetily](https://github.com/Zackriya-Solutions/meetily), maintained as its own product while keeping the original MIT license and attribution.

---

<details>
<summary>Table of Contents</summary>

- [Introduction](#introduction)
- [Why Ubundi Meet?](#why-ubundi-meet)
- [Features](#features)
- [Installation](#installation)
- [System Architecture](#system-architecture)
- [For Developers](#for-developers)
- [Local macOS Updates](docs/LOCAL_MACOS_UPDATES.md)
- [License & Attribution](#license--attribution)

</details>

## Introduction

Ubundi Meet is a privacy-first AI meeting assistant that runs entirely on your local machine. It captures your meetings, transcribes them in real-time, and generates summaries — all without sending your audio or transcripts to the cloud. This makes it a good fit for professionals and organizations that need complete control over sensitive information.

## Why Ubundi Meet?

- **Privacy First:** All processing happens locally on your device.
- **Cost-Effective:** Uses open-source AI models instead of expensive APIs.
- **Flexible:** Works offline and supports multiple meeting platforms.
- **Customizable:** Self-host and modify for your specific needs.

## Features

- **Local First:** All processing is done on your machine. No data ever leaves your computer.
- **Real-time Transcription:** Get a live transcript of your meeting as it happens.
- **AI-Powered Summaries:** Generate summaries of your meetings using powerful language models.
- **Multi-Platform:** Works on macOS, Windows, and Linux.
- **Open Source:** Ubundi Meet is open source and free to use.
- **Flexible AI Provider Support:** Choose from Ollama (local), Claude, Groq, OpenRouter, or your own OpenAI-compatible endpoint.
- **Professional Audio Mixing:** Microphone and system audio captured simultaneously with intelligent ducking and clipping prevention.
- **GPU Acceleration:** Metal (macOS), CUDA/Vulkan (Windows/Linux), automatically enabled at build time.
- **Import & Enhance:** Import existing audio files to generate transcripts, or re-transcribe recorded meetings with a different model or language.

## Installation

### 🍎 macOS

1. Download the latest `.dmg` from [Releases](https://github.com/Schramm2/meetily/releases)
2. Open the downloaded `.dmg` file
3. Drag **Ubundi Meet** to your Applications folder
4. Open **Ubundi Meet** from Applications folder

### 🪟 Windows

1. Download the latest `x64-setup.exe` from [Releases](https://github.com/Schramm2/meetily/releases)
2. Run the installer

### 🐧 Linux

Build from source following our detailed guides:

- [Building on Linux](docs/building_in_linux.md)
- [General Build Instructions](docs/BUILDING.md)

## System Architecture

Ubundi Meet is a single, self-contained desktop application built with [Tauri](https://tauri.app/). It uses a Rust-based backend to handle audio capture, mixing, transcription, and storage, with a Next.js frontend for the user interface.

For more details, see the [Architecture documentation](docs/architecture.md).

## For Developers

You'll need Rust and Node.js (pnpm) installed to build from source. See the [Building from Source guide](docs/BUILDING.md) and the [GPU Acceleration guide](docs/GPU_ACCELERATION.md).

```bash
git clone https://github.com/Schramm2/meetily
cd meetily/frontend
pnpm install
pnpm run tauri:dev
```

For the short local macOS update path, use [`scripts/update-local-macos.sh`](scripts/update-local-macos.sh). It builds the current checkout and updates `/Applications/Ubundi Meet.app` without a GitHub release. See the [Local macOS Updates guide](docs/LOCAL_MACOS_UPDATES.md) for verification and data-directory details.

## License & Attribution

Ubundi Meet is distributed under the [MIT License](LICENSE.md).

This project is a fork of [Meetily](https://github.com/Zackriya-Solutions/meetily), originally created by Zackriya Solutions (MIT, © 2024). The original copyright notice and license are preserved in [LICENSE.md](LICENSE.md), as required by the MIT license.

Acknowledgments:

- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) — local transcription engine
- [Screenpipe](https://github.com/mediar-ai/screenpipe) — borrowed code
- [transcribe-rs](https://crates.io/crates/transcribe-rs) — borrowed code
- **NVIDIA** for the **Parakeet** model
- [istupakov](https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx) for the ONNX conversion of the Parakeet model
