<div align="center">
    <h1>Notive</h1>
    <p><strong>Privacy-First Meetings and Local Dictation</strong></p>
    <p>
        <img alt="License" src="https://img.shields.io/badge/License-MIT-blue">
        <img alt="Supported OS" src="https://img.shields.io/badge/Supported_OS-macOS-white">
    </p>
    <p>Open Source • Privacy-First • Local-First</p>
</div>

A privacy-first desktop assistant that captures and transcribes meetings on your Mac. Local Dictation records speech from a global shortcut, transcribes it on your Mac, and inserts the text into the active app. Meeting evidence leaves your machine only when you confirm an Ask request to an external AI provider or choose an external provider for summaries.

---

<details>
<summary>Table of Contents</summary>

- [Introduction](#introduction)
- [Why Notive?](#why-notive)
- [Features](#features)
- [Installation](#installation)
- [System Architecture](#system-architecture)
- [For Developers](#for-developers)
- [Local macOS Updates](docs/LOCAL_MACOS_UPDATES.md)
- [License](#license)

</details>

## Introduction

Notive is a privacy-first desktop assistant with two main areas: meetings and Local Dictation. The meeting tools capture meetings, transcribe them in real time, and can generate summaries. Local Dictation records speech from a global shortcut, transcribes it on your Mac, and inserts the text into the active app. Dictation audio and transcripts stay on your device.

## Why Notive?

- **Privacy First:** All processing happens locally on your device.
- **Cost-Effective:** Uses open-source AI models instead of expensive APIs.
- **Flexible:** Works offline and supports multiple meeting platforms.
- **Customizable:** Self-host and modify for your specific needs.

## Features

- **Local Dictation:** Hold Option+Space to record speech, then release it to transcribe on your Mac and insert the text into the active app. Dictation audio and transcripts stay on the device.
- **Local First:** Recording, transcription, storage, retrieval, and citation construction stay on your Mac. External AI use is explicit.
- **Real-time Transcription:** Get a live transcript of your meeting as it happens.
- **Automatic Speaker Labels:** During a recording, Notive groups distinct voices and adds private `Speaker 1`, `Speaker 2`, and similar labels to the transcript.
- **Meeting Speaker Aliases:** In a saved meeting, assign a readable name to an anonymous speaker label. The alias stays on the device and applies only to that meeting. Notive keeps the original label and does not infer identity or match voices across meetings.
- **AI-Powered Summaries:** Generate summaries of your meetings using powerful language models.
- **Evidence-backed questions:** Ask across saved meetings and open each cited transcript segment at its recording-relative time.
- **macOS:** Built for macOS.
- **Open Source:** Notive is open source and free to use.
- **Flexible AI Provider Support:** Choose from Ollama (local), Claude, Groq, OpenRouter, or your own OpenAI-compatible endpoint.
- **Professional Audio Mixing:** Microphone and system audio captured simultaneously with intelligent ducking and clipping prevention.
- **GPU Acceleration:** Metal and CoreML are enabled for macOS builds.
- **Import & Enhance:** Import existing audio files to generate transcripts, or re-transcribe recorded meetings with a different model or language.

## Installation

### 🍎 macOS

1. Download the latest `.dmg` from [Releases](https://github.com/Schramm2/ubundi-meet/releases)
2. Open the downloaded `.dmg` file
3. Drag **Notive** to your Applications folder
4. Open **Notive** from Applications folder

## System Architecture

Notive is a single, self-contained desktop application built with [Tauri](https://tauri.app/). It uses a Rust-based backend to handle audio capture, mixing, transcription, and storage, with a Next.js frontend for the user interface.

For more details, see the [Architecture documentation](docs/architecture.md).

Ask Notive retrieves and ranks transcript evidence in the local SQLite database. Citation metadata and meeting navigation stay on the device. Built-in AI and Ollama on a loopback address can answer without an external evidence notice. If the configured endpoint is external, the app names the provider and requires confirmation before it sends the question and selected transcript evidence for the first Ask request in the app session.

## For Developers

You'll need Rust and Node.js (pnpm) installed to build from source. See the [Building from Source guide](docs/BUILDING.md) and the [GPU Acceleration guide](docs/GPU_ACCELERATION.md).

```bash
git clone https://github.com/Schramm2/ubundi-meet
cd ubundi-meet/frontend
pnpm install
pnpm run tauri:dev
```

For the short local macOS update path, use [`scripts/update-local-macos.sh`](scripts/update-local-macos.sh). It builds the current checkout and updates `/Applications/Notive.app` without a GitHub release. See the [Local macOS Updates guide](docs/LOCAL_MACOS_UPDATES.md) for verification and data-directory details.

## License

Notive is distributed under the [MIT License](LICENSE.md).

Required third-party notices are in [NOTICE.md](NOTICE.md).

Local Dictation includes work adapted from [Handy](https://github.com/cjpais/Handy), by CJ Pais. See the [Handy attribution](docs/handy-attribution.md). Notive does not use Handy names, logos, icons, or other brand assets. Speech model licenses are separate and must be checked before distribution.

Acknowledgments:

- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) — local transcription engine
- [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) and [3D-Speaker](https://github.com/modelscope/3D-Speaker) — local speaker embeddings for live speaker labels
- [Screenpipe](https://github.com/mediar-ai/screenpipe) — borrowed code
- [transcribe-rs](https://crates.io/crates/transcribe-rs) — borrowed code
- [Handy](https://github.com/cjpais/Handy) — adapted Local Dictation work, licensed under the MIT License
- **NVIDIA** for the **Parakeet** model
- [istupakov](https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx) for the ONNX conversion of the Parakeet model
