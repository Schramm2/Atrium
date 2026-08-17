import CoreGraphics
import Foundation

/// Screen Recording access, which macOS requires before Atrium can capture the
/// audio of the other people in a meeting.
///
/// A locally built copy of Atrium loses this access whenever its code signature
/// changes, so the state is read before every recording rather than once at
/// onboarding.
public enum ScreenRecordingAuthorization {
    /// Reads the current state without showing a prompt.
    public static var isGranted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Asks macOS for access. macOS shows its prompt and adds Atrium to the
    /// Screen Recording list; the grant applies after Atrium starts again.
    @discardableResult
    public static func request() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    /// The System Settings destination for the Screen Recording list.
    public static let settingsURLString =
        "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
}
