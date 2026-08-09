use std::error::Error;
use std::fmt;

use super::state::{DictationStatus, SessionId, SessionState};

/// Audio captured from the microphone. System audio has no place in this type.
#[derive(Clone, Debug, PartialEq)]
pub struct CapturedAudio {
    pub samples: Vec<f32>,
    pub sample_rate_hz: u32,
}

#[derive(Clone, Debug, PartialEq)]
pub struct Transcript {
    pub text: String,
    pub confidence: Option<f32>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PersistenceReceipt {
    pub key: String,
}

#[derive(Clone, Debug, PartialEq)]
pub struct DictationResult {
    pub session_id: SessionId,
    pub transcript: Transcript,
    /// `None` means that the transcript was not stored.
    pub persistence: Option<PersistenceReceipt>,
}

#[derive(Clone, Debug, PartialEq)]
pub enum DictationEvent {
    Started { session_id: SessionId },
    Processing { session_id: SessionId },
    Completed { result: DictationResult },
    Cancelled { session_id: SessionId },
}

#[derive(Clone, Debug, PartialEq)]
pub struct StartResult {
    pub session_id: SessionId,
    pub event: DictationEvent,
}

#[derive(Clone, Debug, PartialEq)]
pub struct StopResult {
    pub result: DictationResult,
    /// The ordered state events produced by stop.
    pub events: Vec<DictationEvent>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum AvailabilityConflict {
    MeetingInProgress,
    Unavailable(String),
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum FailureStage {
    CaptureStart,
    CaptureStop,
    CaptureCancel,
    Transcription,
    Persistence,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DictationAdapterError {
    message: String,
}

impl DictationAdapterError {
    pub fn new(message: impl Into<String>) -> Self {
        Self {
            message: message.into(),
        }
    }

    pub fn message(&self) -> &str {
        &self.message
    }
}

impl fmt::Display for DictationAdapterError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.message)
    }
}

impl Error for DictationAdapterError {}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DictationError {
    Conflict(AvailabilityConflict),
    AlreadyActive(DictationStatus),
    NoActiveSession,
    Adapter {
        session_id: SessionId,
        stage: FailureStage,
        message: String,
    },
}

impl fmt::Display for DictationError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Conflict(AvailabilityConflict::MeetingInProgress) => {
                formatter.write_str("A meeting recording is in progress")
            }
            Self::Conflict(AvailabilityConflict::Unavailable(reason)) => {
                write!(formatter, "Dictation is unavailable: {reason}")
            }
            Self::AlreadyActive(status) => write!(formatter, "Dictation is already {status:?}"),
            Self::NoActiveSession => formatter.write_str("No dictation session is active"),
            Self::Adapter {
                session_id,
                stage,
                message,
            } => write!(
                formatter,
                "Dictation session {session_id} failed during {stage:?}: {message}"
            ),
        }
    }
}

impl Error for DictationError {}

/// Rejects dictation when another exclusive activity, such as a meeting, runs.
pub trait AvailabilityCheck {
    fn check(&self) -> Result<(), AvailabilityConflict>;
}

/// Owns one local microphone capture. An adapter must not add system audio.
pub trait MicrophoneCapture {
    fn start(&mut self, session_id: SessionId) -> Result<(), DictationAdapterError>;
    fn stop(&mut self, session_id: SessionId) -> Result<CapturedAudio, DictationAdapterError>;
    fn cancel(&mut self, session_id: SessionId) -> Result<(), DictationAdapterError>;
}

/// Adapts a local transcription engine to one completed microphone buffer.
pub trait Transcriber {
    fn transcribe(
        &mut self,
        session_id: SessionId,
        audio: CapturedAudio,
    ) -> Result<Transcript, DictationAdapterError>;
}

/// Optional transcript storage. The standard constructor does not use storage.
pub trait TranscriptPersistence {
    fn persist(
        &mut self,
        result: &DictationResult,
    ) -> Result<PersistenceReceipt, DictationAdapterError>;
}

#[derive(Debug, Default)]
pub struct NoPersistence;

impl TranscriptPersistence for NoPersistence {
    fn persist(
        &mut self,
        _result: &DictationResult,
    ) -> Result<PersistenceReceipt, DictationAdapterError> {
        unreachable!("NoPersistence is never called")
    }
}

/// Coordinates one serial push-to-talk dictation session at a time.
pub struct DictationSession<C, T, A, P = NoPersistence> {
    capture: C,
    transcriber: T,
    availability: A,
    persistence: Option<P>,
    state: SessionState,
}

impl<C, T, A> DictationSession<C, T, A, NoPersistence>
where
    C: MicrophoneCapture,
    T: Transcriber,
    A: AvailabilityCheck,
{
    /// Creates a session that never writes audio or transcripts to storage.
    pub fn new(capture: C, transcriber: T, availability: A) -> Self {
        Self {
            capture,
            transcriber,
            availability,
            persistence: None,
            state: SessionState::default(),
        }
    }
}

impl<C, T, A, P> DictationSession<C, T, A, P>
where
    C: MicrophoneCapture,
    T: Transcriber,
    A: AvailabilityCheck,
    P: TranscriptPersistence,
{
    /// Enables transcript storage. Calling this method is the opt-in boundary.
    pub fn with_persistence<P2>(self, persistence: P2) -> DictationSession<C, T, A, P2>
    where
        P2: TranscriptPersistence,
    {
        DictationSession {
            capture: self.capture,
            transcriber: self.transcriber,
            availability: self.availability,
            persistence: Some(persistence),
            state: self.state,
        }
    }

    pub fn status(&self) -> DictationStatus {
        self.state.status()
    }

    pub fn start(&mut self) -> Result<StartResult, DictationError> {
        if self.status() != DictationStatus::Idle {
            return Err(DictationError::AlreadyActive(self.status()));
        }
        self.availability
            .check()
            .map_err(DictationError::Conflict)?;

        let session_id = SessionId::next();
        self.capture
            .start(session_id)
            .map_err(|error| adapter_error(session_id, FailureStage::CaptureStart, error))?;
        self.state
            .start(session_id)
            .expect("the idle state was checked before microphone capture started");

        Ok(StartResult {
            session_id,
            event: DictationEvent::Started { session_id },
        })
    }

    pub fn stop(&mut self) -> Result<StopResult, DictationError> {
        let session_id = match self.status() {
            DictationStatus::Recording { session_id } => session_id,
            DictationStatus::Idle => return Err(DictationError::NoActiveSession),
            status @ DictationStatus::Processing { .. } => {
                return Err(DictationError::AlreadyActive(status));
            }
        };

        self.state
            .begin_processing()
            .expect("the recording state was checked before processing");

        let outcome = self.process(session_id);
        self.state.finish();
        outcome
    }

    pub fn cancel(&mut self) -> Result<DictationEvent, DictationError> {
        let session_id = match self.status() {
            DictationStatus::Recording { session_id }
            | DictationStatus::Processing { session_id } => session_id,
            DictationStatus::Idle => return Err(DictationError::NoActiveSession),
        };

        let outcome = self
            .capture
            .cancel(session_id)
            .map_err(|error| adapter_error(session_id, FailureStage::CaptureCancel, error));
        self.state.finish();
        outcome.map(|()| DictationEvent::Cancelled { session_id })
    }

    fn process(&mut self, session_id: SessionId) -> Result<StopResult, DictationError> {
        let processing = DictationEvent::Processing { session_id };
        let audio = self
            .capture
            .stop(session_id)
            .map_err(|error| adapter_error(session_id, FailureStage::CaptureStop, error))?;
        let transcript = self
            .transcriber
            .transcribe(session_id, audio)
            .map_err(|error| adapter_error(session_id, FailureStage::Transcription, error))?;

        let mut result = DictationResult {
            session_id,
            transcript,
            persistence: None,
        };
        if let Some(persistence) = self.persistence.as_mut() {
            result.persistence =
                Some(persistence.persist(&result).map_err(|error| {
                    adapter_error(session_id, FailureStage::Persistence, error)
                })?);
        }

        let completed = DictationEvent::Completed {
            result: result.clone(),
        };
        Ok(StopResult {
            result,
            events: vec![processing, completed],
        })
    }
}

fn adapter_error(
    session_id: SessionId,
    stage: FailureStage,
    error: DictationAdapterError,
) -> DictationError {
    DictationError::Adapter {
        session_id,
        stage,
        message: error.message,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[derive(Default)]
    struct FakeCapture {
        active: Option<SessionId>,
        starts: usize,
        stops: usize,
        cancels: usize,
        fail_start: bool,
        fail_stop: bool,
    }

    impl MicrophoneCapture for FakeCapture {
        fn start(&mut self, session_id: SessionId) -> Result<(), DictationAdapterError> {
            self.starts += 1;
            if self.fail_start {
                return Err(DictationAdapterError::new("microphone denied"));
            }
            self.active = Some(session_id);
            Ok(())
        }

        fn stop(&mut self, session_id: SessionId) -> Result<CapturedAudio, DictationAdapterError> {
            self.stops += 1;
            if self.fail_stop {
                return Err(DictationAdapterError::new("microphone disconnected"));
            }
            assert_eq!(self.active.take(), Some(session_id));
            Ok(CapturedAudio {
                samples: vec![0.25, -0.25],
                sample_rate_hz: 16_000,
            })
        }

        fn cancel(&mut self, session_id: SessionId) -> Result<(), DictationAdapterError> {
            self.cancels += 1;
            assert_eq!(self.active.take(), Some(session_id));
            Ok(())
        }
    }

    #[derive(Default)]
    struct FakeTranscriber {
        calls: usize,
        fail: bool,
    }

    impl Transcriber for FakeTranscriber {
        fn transcribe(
            &mut self,
            _session_id: SessionId,
            audio: CapturedAudio,
        ) -> Result<Transcript, DictationAdapterError> {
            self.calls += 1;
            if self.fail {
                return Err(DictationAdapterError::new("model unavailable"));
            }
            assert_eq!(audio.sample_rate_hz, 16_000);
            Ok(Transcript {
                text: "hello".to_string(),
                confidence: Some(0.9),
            })
        }
    }

    struct FakeAvailability(Result<(), AvailabilityConflict>);

    impl AvailabilityCheck for FakeAvailability {
        fn check(&self) -> Result<(), AvailabilityConflict> {
            self.0.clone()
        }
    }

    #[derive(Default)]
    struct FakePersistence {
        calls: usize,
    }

    impl TranscriptPersistence for FakePersistence {
        fn persist(
            &mut self,
            result: &DictationResult,
        ) -> Result<PersistenceReceipt, DictationAdapterError> {
            self.calls += 1;
            Ok(PersistenceReceipt {
                key: format!("dictation-{}", result.session_id),
            })
        }
    }

    fn session() -> DictationSession<FakeCapture, FakeTranscriber, FakeAvailability> {
        DictationSession::new(
            FakeCapture::default(),
            FakeTranscriber::default(),
            FakeAvailability(Ok(())),
        )
    }

    #[test]
    fn start_stop_moves_through_processing_and_returns_to_idle() {
        let mut session = session();
        let started = session.start().expect("start");

        assert_eq!(
            session.status(),
            DictationStatus::Recording {
                session_id: started.session_id
            }
        );
        let stopped = session.stop().expect("stop");
        assert_eq!(session.status(), DictationStatus::Idle);
        assert_eq!(stopped.result.transcript.text, "hello");
        assert_eq!(stopped.result.persistence, None);
        assert_eq!(
            stopped.events[0],
            DictationEvent::Processing {
                session_id: started.session_id
            }
        );
        assert!(matches!(
            stopped.events[1],
            DictationEvent::Completed { .. }
        ));
    }

    #[test]
    fn repeated_start_and_stop_are_rejected() {
        let mut session = session();
        let started = session.start().expect("first start");

        assert_eq!(
            session.start(),
            Err(DictationError::AlreadyActive(DictationStatus::Recording {
                session_id: started.session_id
            }))
        );
        session.stop().expect("first stop");
        assert_eq!(session.stop(), Err(DictationError::NoActiveSession));
    }

    #[test]
    fn cancel_discards_capture_and_returns_to_idle() {
        let mut session = session();
        let started = session.start().expect("start");

        assert_eq!(
            session.cancel(),
            Ok(DictationEvent::Cancelled {
                session_id: started.session_id
            })
        );
        assert_eq!(session.status(), DictationStatus::Idle);
        assert_eq!(session.stop(), Err(DictationError::NoActiveSession));
        assert_eq!(session.capture.cancels, 1);
        assert_eq!(session.transcriber.calls, 0);
    }

    #[test]
    fn meeting_conflict_is_rejected_before_microphone_start() {
        let mut session = DictationSession::new(
            FakeCapture::default(),
            FakeTranscriber::default(),
            FakeAvailability(Err(AvailabilityConflict::MeetingInProgress)),
        );

        assert_eq!(
            session.start(),
            Err(DictationError::Conflict(
                AvailabilityConflict::MeetingInProgress
            ))
        );
        assert_eq!(session.status(), DictationStatus::Idle);
        assert_eq!(session.capture.starts, 0);
    }

    #[test]
    fn adapter_errors_reset_the_session_to_idle() {
        let mut session = DictationSession::new(
            FakeCapture {
                fail_stop: true,
                ..FakeCapture::default()
            },
            FakeTranscriber::default(),
            FakeAvailability(Ok(())),
        );
        let id = session.start().expect("start").session_id;

        assert_eq!(
            session.stop(),
            Err(DictationError::Adapter {
                session_id: id,
                stage: FailureStage::CaptureStop,
                message: "microphone disconnected".to_string(),
            })
        );
        assert_eq!(session.status(), DictationStatus::Idle);
    }

    #[test]
    fn capture_start_error_does_not_commit_recording_state() {
        let mut session = DictationSession::new(
            FakeCapture {
                fail_start: true,
                ..FakeCapture::default()
            },
            FakeTranscriber::default(),
            FakeAvailability(Ok(())),
        );

        assert!(matches!(
            session.start(),
            Err(DictationError::Adapter {
                stage: FailureStage::CaptureStart,
                message,
                ..
            }) if message == "microphone denied"
        ));
        assert_eq!(session.status(), DictationStatus::Idle);
    }

    #[test]
    fn transcription_error_returns_the_session_to_idle() {
        let mut session = DictationSession::new(
            FakeCapture::default(),
            FakeTranscriber {
                fail: true,
                ..FakeTranscriber::default()
            },
            FakeAvailability(Ok(())),
        );
        let id = session.start().expect("start").session_id;

        assert_eq!(
            session.stop(),
            Err(DictationError::Adapter {
                session_id: id,
                stage: FailureStage::Transcription,
                message: "model unavailable".to_string(),
            })
        );
        assert_eq!(session.status(), DictationStatus::Idle);
    }

    #[test]
    fn persistence_requires_explicit_opt_in() {
        let mut session = session().with_persistence(FakePersistence::default());
        session.start().expect("start");
        let stopped = session.stop().expect("stop");

        assert_eq!(session.persistence.as_ref().expect("enabled").calls, 1);
        assert!(stopped.result.persistence.is_some());
    }
}
