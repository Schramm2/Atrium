@preconcurrency import Speech

public enum SpeechAuthorization {
    public nonisolated static func request() async -> SFSpeechRecognizerAuthorizationStatus {
        let current = SFSpeechRecognizer.authorizationStatus()
        guard current == .notDetermined else { return current }
        return await request(timeout: .seconds(15)) { completion in
            SFSpeechRecognizer.requestAuthorization { status in
                completion(status)
            }
        }
    }

    static func request(
        timeout: Duration,
        using request: (@escaping @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void) -> Void
    ) async -> SFSpeechRecognizerAuthorizationStatus {
        await BoundedAuthorizationRequest.run(
            timeout: timeout,
            fallback: .denied,
            using: request
        )
    }
}
