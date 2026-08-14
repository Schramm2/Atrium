# Atrium privacy

Last updated: August 11, 2026

Atrium is an internal, local-first application for Ubundi and First Motive. This document states its data boundary.

## Data on the Mac

Atrium keeps these operations on the user's Mac:

- microphone and system-audio capture
- Apple Speech transcription
- meeting, transcript, note, summary, and speaker-alias storage
- meeting search and Ask evidence retrieval
- citation construction
- Apple Intelligence or deterministic local answer generation
- Local Dictation audio and text

Atrium stores active application data under `~/Library/Application Support/Notive/`. It can copy compatible meeting data from the earlier `~/Library/Application Support/com.ubundi.meet/` folder after user confirmation. Recordings use the selected local recording folder. The application does not add encryption at rest; macOS account and file-system controls protect local data.

## External AI providers

External providers are optional. They include OpenAI, Anthropic, Groq, OpenRouter, remote Ollama, and custom OpenAI-compatible endpoints.

Before the first external Ask request to a provider in an application session, Atrium names the provider and asks for confirmation. If the user confirms, Atrium sends the question and selected transcript evidence. An external summary request sends the content required for that selected summary action.

Local Ollama on a loopback address stays on the Mac. Each external provider applies its own data terms.

## Analytics

Atrium does not send product analytics or usage telemetry. It does not send meeting content, recordings, titles, file names, participants, voice profiles, or generated content to Ubundi or First Motive as product analytics.

## User control

Users can view and delete saved meetings in the application. They can use normal macOS file controls for recording folders and application data. Deleting Atrium does not automatically delete its application-support folder.

## Changes

Material privacy-boundary changes must be recorded in this repository and in release notes before distribution.
