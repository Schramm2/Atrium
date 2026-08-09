/// Return whether macOS trusts this process to listen for and post input events.
pub fn accessibility_is_trusted() -> bool {
    cidre::ax::is_process_trusted()
        && cidre::cg::event::access::listen_preflight()
        && cidre::cg::event::access::post_preflight()
}

/// Ask macOS to show the Accessibility consent prompt.
///
/// The return value is the current trust state. A new grant can require the app
/// to restart before event taps work.
pub fn request_accessibility() -> bool {
    cidre::ax::is_process_trusted_with_prompt(true)
}
