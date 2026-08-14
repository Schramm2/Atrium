import Foundation

enum BoundedAuthorizationRequest {
    static func run<Value: Sendable>(
        timeout: Duration,
        fallback: Value,
        using request: (@escaping @Sendable (Value) -> Void) -> Void
    ) async -> Value {
        await withCheckedContinuation { continuation in
            let completion = AuthorizationRequestCompletion(continuation: continuation)
            request { value in completion.finish(value) }
            Task {
                try? await Task.sleep(for: timeout)
                completion.finish(fallback)
            }
        }
    }
}

private final class AuthorizationRequestCompletion<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Never>?

    init(continuation: CheckedContinuation<Value, Never>) {
        self.continuation = continuation
    }

    func finish(_ value: Value) {
        lock.lock()
        let continuation = continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: value)
    }
}
