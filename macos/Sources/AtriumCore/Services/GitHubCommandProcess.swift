import Foundation

/// Shares one cancellable `Process` between the async operation and its cancellation handler.
/// Every mutable field is protected by `lock`.
final class GitHubCommandProcess: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var isCancelled = false

    func install(_ process: Process) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !isCancelled else { return false }
        self.process = process
        return true
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        let process = process
        lock.unlock()
        process?.terminate()
    }
}
