import Foundation

public enum GitHubCommandExecutor {
    public typealias Run = @Sendable ([String]) async -> GitHubReleaseUpdater.CommandResult

    public static func execute(_ arguments: [String]) async -> GitHubReleaseUpdater.CommandResult {
        let fileManager = FileManager.default
        let captureDirectory = fileManager.temporaryDirectory
            .appending(path: "atrium-command-\(UUID().uuidString)")
        let outputURL = captureDirectory.appending(path: "stdout")
        let errorURL = captureDirectory.appending(path: "stderr")

        do {
            try fileManager.createDirectory(at: captureDirectory, withIntermediateDirectories: true)
            guard fileManager.createFile(atPath: outputURL.path, contents: nil),
                  fileManager.createFile(atPath: errorURL.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
        } catch {
            return .init(exitCode: -1, standardOutput: "", standardError: error.localizedDescription)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        var environment = ProcessInfo.processInfo.environment
        let standardPaths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        environment["PATH"] = (standardPaths + [environment["PATH"] ?? ""]).joined(separator: ":")
        process.environment = environment

        let commandProcess = GitHubCommandProcess()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                do {
                    let outputHandle = try FileHandle(forWritingTo: outputURL)
                    let errorHandle = try FileHandle(forWritingTo: errorURL)
                    process.standardOutput = outputHandle
                    process.standardError = errorHandle
                    process.terminationHandler = { process in
                        try? outputHandle.close()
                        try? errorHandle.close()
                        let result = GitHubReleaseUpdater.CommandResult(
                            exitCode: process.terminationStatus,
                            standardOutput: String(
                                decoding: (try? Data(contentsOf: outputURL)) ?? Data(),
                                as: UTF8.self
                            ),
                            standardError: String(
                                decoding: (try? Data(contentsOf: errorURL)) ?? Data(),
                                as: UTF8.self
                            )
                        )
                        try? FileManager.default.removeItem(at: captureDirectory)
                        continuation.resume(returning: result)
                    }
                    try process.run()
                    if !commandProcess.install(process) { process.terminate() }
                } catch {
                    try? fileManager.removeItem(at: captureDirectory)
                    continuation.resume(returning: .init(
                        exitCode: -1,
                        standardOutput: "",
                        standardError: error.localizedDescription
                    ))
                }
            }
        } onCancel: {
            commandProcess.cancel()
        }
    }
}
