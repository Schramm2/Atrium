@preconcurrency import AVFAudio

public enum MicrophoneAuthorizationStatus: Equatable, Sendable {
    case authorized
    case denied
    case notDetermined
}

public enum MicrophoneAuthorization {
    public static var currentStatus: MicrophoneAuthorizationStatus {
        status(for: AVAudioApplication.shared.recordPermission)
    }

    public static func request() async -> Bool {
        switch currentStatus {
        case .authorized:
            true
        case .denied:
            false
        case .notDetermined:
            await request(timeout: .seconds(15)) { completion in
                AVAudioApplication.requestRecordPermission { granted in
                    completion(granted)
                }
            }
        }
    }

    static func request(
        timeout: Duration,
        using request: (@escaping @Sendable (Bool) -> Void) -> Void
    ) async -> Bool {
        await BoundedAuthorizationRequest.run(
            timeout: timeout,
            fallback: false,
            using: request
        )
    }

    static func status(
        for permission: AVAudioApplication.recordPermission
    ) -> MicrophoneAuthorizationStatus {
        switch permission {
        case .granted:
            .authorized
        case .denied:
            .denied
        case .undetermined:
            .notDetermined
        @unknown default:
            .denied
        }
    }
}
