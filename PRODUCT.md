# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Notive serves Ubundi and First Motive team members who capture meetings, dictate text, review transcripts, keep notes, and recall past conversation evidence on a Mac. The primary workspace must give meeting capture, notes, saved meetings, Local Dictation, and Ask Notive equal structural importance.

## Product Purpose

Notive is a privacy-first, local-first native macOS meeting assistant. It records microphone and system audio, transcribes speech on the Mac, keeps meeting evidence in a local workspace, supports direct notes and summaries, and lets users ask evidence-backed questions across saved meetings. Success means that users can move between capture, review, recall, and writing without losing context or control of their data.

## Positioning

Notive keeps recording, transcription, storage, retrieval, citation construction, and default answer generation on the Mac. External AI use is optional, named, and confirmed before meeting evidence leaves the device.

## Operating Context

Notive is an internal desktop workspace used during and after meetings. It supports live capture, imported audio, timed transcripts, meeting-scoped speaker aliases, summaries, Markdown notes, evidence citations, playback, global Local Dictation, native notifications, and a menu-bar control surface. It reads and writes the existing local database under `~/Library/Application Support/com.ubundi.meet/` and stores recordings locally.

## Capabilities and Constraints

- The product is the native Swift 6.1 and SwiftUI application in `macos/`.
- Preserve bundle identifier `com.ubundi.meet` and the existing database and recording contracts.
- Use Apple frameworks before adding production dependencies. Sparkle is the only production Swift package dependency.
- Preserve all current workflows, states, permissions, accessibility labels, keyboard operation, and system light/dark appearance behavior.
- The interface has two brand themes, Ubundi and First Motive, but one shared information architecture and interaction model.
- Do not infer speaker identity or send meeting evidence externally without explicit user action.

## Brand Commitments

The product name is **Notive**. Ubundi and First Motive remain distinct selectable theme identities. Use the canonical company-media brand assets and the contracts in:

- `/Users/matthew-schramm-ubundi/Workspace.nosync/Work/Company Media:Assets/Ubundi/01_Brand/Guideline-Reference/DESIGN.md`
- `/Users/matthew-schramm-ubundi/Workspace.nosync/Work/Company Media:Assets/First Motive/01_Brand/Guideline-Reference/DESIGN.md`

Ubundi must feel precise, open, human, curious, and quietly confident. First Motive must retain its dark aubergine, warm-ivory, steel, sage, lilac, and coral identity. Both use Manrope as the preferred brand typeface with native system fallbacks.

## Evidence on Hand

- Native product behavior and compatibility are documented in `docs/architecture.md` and the accepted records in `docs/decisions/`.
- Canonical Ubundi and First Motive design contracts, logos, marks, wordmarks, icon assets, and reference screenshots are available in the company media library.
- The repository contains an existing local meeting database with representative meetings and transcripts for interface verification.
- No fabricated testimonials, benchmarks, external customer claims, or cloud-processing claims are allowed.

## Product Principles

- Keep capture, review, recall, and writing equally easy to find.
- Make local processing and external-sharing boundaries clear at the point of action.
- Use native macOS structure, behavior, keyboard access, and accessibility semantics.
- Let each company theme feel authentic without changing how the workspace works.
- Keep dense operational screens calm, legible, and evidence-led.

## Accessibility & Inclusion

Support macOS keyboard navigation, VoiceOver semantics, increased contrast, reduced motion, light and dark appearance where the brand permits it, legible type at native control sizes, and non-color state indicators. Avoid hover-only actions and preserve visible focus and disabled states.
