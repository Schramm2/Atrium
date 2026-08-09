use objc2_app_kit::NSWorkspace;

/// Identifies the application that had focus when dictation started.
///
/// This token never activates an application. The paste adapter uses it only
/// to fail safely if focus moved while transcription was in progress.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct FocusToken {
    process_id: i32,
}

impl FocusToken {
    pub fn capture() -> Option<Self> {
        let application = NSWorkspace::sharedWorkspace().frontmostApplication()?;
        Some(Self {
            process_id: application.processIdentifier(),
        })
    }

    pub fn is_still_frontmost(&self) -> bool {
        Self::capture() == Some(*self)
    }

    pub fn process_id(&self) -> i32 {
        self.process_id
    }
}
