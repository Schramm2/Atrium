import Foundation

public actor AudioImportService {
    public init() {}

    public func copy(from sourceURL: URL, to destinationURL: URL) throws {
        try Task.checkCancellation()
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        if Task.isCancelled {
            try? FileManager.default.removeItem(at: destinationURL)
            throw CancellationError()
        }
    }
}
