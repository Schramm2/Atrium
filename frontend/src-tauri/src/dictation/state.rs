use std::fmt;
use std::sync::atomic::{AtomicU64, Ordering};

static NEXT_SESSION_ID: AtomicU64 = AtomicU64::new(1);

/// Identifies one dictation attempt across capture, transcription, and events.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct SessionId(u64);

impl SessionId {
    pub(crate) fn next() -> Self {
        Self(NEXT_SESSION_ID.fetch_add(1, Ordering::Relaxed))
    }

    pub fn get(self) -> u64 {
        self.0
    }
}

impl fmt::Display for SessionId {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.0.fmt(formatter)
    }
}

/// The externally visible state of a dictation session.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DictationStatus {
    Idle,
    Recording { session_id: SessionId },
    Processing { session_id: SessionId },
}

impl DictationStatus {
    pub fn session_id(self) -> Option<SessionId> {
        match self {
            Self::Idle => None,
            Self::Recording { session_id } | Self::Processing { session_id } => Some(session_id),
        }
    }
}

#[derive(Debug)]
pub(crate) struct SessionState {
    status: DictationStatus,
}

impl Default for SessionState {
    fn default() -> Self {
        Self {
            status: DictationStatus::Idle,
        }
    }
}

impl SessionState {
    pub fn status(&self) -> DictationStatus {
        self.status
    }

    pub fn start(&mut self, session_id: SessionId) -> Result<(), DictationStatus> {
        if self.status != DictationStatus::Idle {
            return Err(self.status);
        }

        self.status = DictationStatus::Recording { session_id };
        Ok(())
    }

    pub fn begin_processing(&mut self) -> Result<SessionId, DictationStatus> {
        match self.status {
            DictationStatus::Recording { session_id } => {
                self.status = DictationStatus::Processing { session_id };
                Ok(session_id)
            }
            current => Err(current),
        }
    }

    pub fn finish(&mut self) {
        self.status = DictationStatus::Idle;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn follows_the_serial_state_path() {
        let id = SessionId::next();
        let mut state = SessionState::default();

        assert_eq!(state.status(), DictationStatus::Idle);
        state.start(id).expect("start");
        assert_eq!(
            state.status(),
            DictationStatus::Recording { session_id: id }
        );
        assert_eq!(state.begin_processing(), Ok(id));
        assert_eq!(
            state.status(),
            DictationStatus::Processing { session_id: id }
        );
        state.finish();
        assert_eq!(state.status(), DictationStatus::Idle);
    }

    #[test]
    fn rejects_non_serial_transitions() {
        let id = SessionId::next();
        let mut state = SessionState::default();

        assert_eq!(state.begin_processing(), Err(DictationStatus::Idle));
        state.start(id).expect("first start");
        assert_eq!(
            state.start(SessionId::next()),
            Err(DictationStatus::Recording { session_id: id })
        );
    }
}
