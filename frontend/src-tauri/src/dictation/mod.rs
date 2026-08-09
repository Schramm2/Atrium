//! Local microphone-only dictation session orchestration.
//!
//! The module does not depend on Tauri. Integration code can adapt the existing
//! audio and transcription services without coupling the session state machine
//! to commands, windows, or storage.

mod session;
mod state;

pub use session::{
    AvailabilityCheck, AvailabilityConflict, CapturedAudio, DictationAdapterError, DictationError,
    DictationEvent, DictationResult, DictationSession, FailureStage, MicrophoneCapture,
    NoPersistence, PersistenceReceipt, StartResult, StopResult, Transcriber, Transcript,
    TranscriptPersistence,
};
pub use state::{DictationStatus, SessionId};
