# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Atrium serves Ubundi and First Motive team members who start with company context, work with agents, capture meetings when useful, review results, and keep private work on a Mac. The primary workspace must give Company Hub, My Workspace, Local Dictation, and Ask Atrium clear structural importance.

## Product Purpose

Atrium is a privacy-first, local-first native macOS company intelligence workspace. It connects company context, agents, approved shared knowledge, and private local work. Meeting capture, transcription, notes, summaries, Local Dictation, and evidence-backed Ask remain local capabilities that support the wider company operating loop. Success means that users can move between shared context and private work without losing control of their data.

## Positioning

Atrium keeps recording, transcription, storage, retrieval, citation construction, and default answer generation on the Mac. External AI use is optional, named, and confirmed before meeting evidence leaves the device.

## Operating Context

Atrium is an internal desktop workspace used during and after meetings. It supports live capture, imported audio, timed transcripts, meeting-scoped speaker aliases, summaries, Markdown notes, evidence citations, playback, global Local Dictation, native notifications, and a menu-bar control surface. It reads and writes the local database under `~/Library/Application Support/Notive/`, can restore data from the earlier `~/Library/Application Support/com.ubundi.meet/` folder, and stores recordings locally.

## Capabilities and Constraints

- The product is the native Swift 6.1 and SwiftUI application in `macos/`.
- Preserve bundle identifier `com.ubundi.meet` and the existing database and recording contracts.
- Use Apple frameworks and the authenticated GitHub CLI release path before adding production dependencies.
- Preserve all current workflows, states, permissions, accessibility labels, keyboard operation, and system light/dark appearance behavior.
- The interface has two brand themes — Ubundi and First Motive — with one shared information architecture and interaction model. Ubundi is the default.
- Do not infer speaker identity or send meeting evidence externally without explicit user action.

## Brand Commitments

The product name is **Atrium**. Ubundi and First Motive are selectable theme identities, not separate products or tenants. Use the canonical company-media brand assets and the contracts in:

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
