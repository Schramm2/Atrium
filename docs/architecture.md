# System Architecture

Ubundi Meet is a self-contained desktop application built with [Tauri](https://tauri.app/). It combines a Rust-based backend with a Next.js frontend into a single, efficient, and cross-platform application.

## High-Level Architecture Diagram

```mermaid
graph TD
    subgraph User Interface
        A[Next.js Frontend]
    end

    subgraph "Core Logic (Rust)"
        B[Tauri Core]
        C[Audio Engine]
        D[Transcription and Speaker Labelling]
        E[Database]
        F[Summary Engine]
    end

    A -- Tauri Commands --> B
    B -- Manages --> C
    B -- Manages --> D
    B -- Manages --> E
    B -- Manages --> F
```

## Component Details

### Frontend (Next.js)

*   Provides the user interface for managing meetings, displaying transcriptions, and configuring the application.
*   Communicates with the Rust core through Tauri's command system.

### Backend (Rust Core)

*   **Tauri Core:** The heart of the application, responsible for managing the window, handling events, and exposing the Rust core to the frontend.
*   **Audio Engine:** Captures audio from the microphone and system, processes it, and prepares it for transcription.
*   **Transcription and Speaker Labelling:** Uses local speech-to-text models (Whisper or Parakeet) to transcribe captured audio. During a recording, a local speaker-embedding model groups speech segments by voice and adds anonymous labels such as `Speaker 1`. The app stores these labels in the transcript. It keeps per-recording voice profiles and embeddings in memory and discards them when recording stops. It does not infer identity or match voices across meetings. Transcription can use GPU acceleration.
*   **Database:** A local SQLite database stores meeting metadata, transcripts, summaries, and meeting-scoped speaker aliases. An alias maps a user-entered name to an original diarization label without changing the source transcript row. Deleting a meeting also deletes its aliases.
*   **Resolved Transcript Names:** The frontend resolves an alias for saved transcript display and copied text while it retains the original label as context. The same resolution is used for the next explicit summary generation or regeneration. An alias change does not change an existing summary.
*   **Summary Engine:** Generates meeting summaries with different Large Language Models (LLMs), including local models through Ollama. The selected model receives user-confirmed speaker aliases in the resolved transcript input.
