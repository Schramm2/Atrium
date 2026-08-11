# Notive privacy

Last updated: August 11, 2026

Notive is an internal, local-first application for Ubundi and First Motive. This document states its data boundary.

## Data on the Mac

Notive keeps these operations on the user's Mac:

- microphone and system-audio capture
- Apple Speech transcription
- meeting, transcript, note, summary, and speaker-alias storage
- meeting search and Ask evidence retrieval
- citation construction
- Apple Intelligence or deterministic local answer generation
- Local Dictation audio and text

Notive stores application data under `~/Library/Application Support/com.ubundi.meet/`. Recordings use the selected local recording folder. The application does not add encryption at rest; macOS account and file-system controls protect local data.

## External AI providers

External providers are optional. They include OpenAI, Anthropic, Groq, OpenRouter, remote Ollama, and custom OpenAI-compatible endpoints.

Before the first external Ask request to a provider in an application session, Notive names the provider and asks for confirmation. If the user confirms, Notive sends the question and selected transcript evidence. An external summary request sends the content required for that selected summary action.

Local Ollama on a loopback address stays on the Mac. Each external provider applies its own data terms.

## Analytics

Notive does not send product analytics or usage telemetry. It does not send meeting content, recordings, titles, file names, participants, voice profiles, or generated content to Ubundi or First Motive as product analytics.

## User control

Users can view and delete saved meetings in the application. They can use normal macOS file controls for recording folders and application data. Deleting Notive does not automatically delete its application-support folder.

## Changes

Material privacy-boundary changes must be recorded in this repository and in release notes before distribution.
