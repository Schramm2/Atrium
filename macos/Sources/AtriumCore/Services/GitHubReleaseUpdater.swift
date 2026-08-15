import Foundation

public struct GitHubReleaseUpdater: Sendable {
    public enum Status: Equatable, Sendable {
        case upToDate
        case updateAvailable(version: String, releaseURL: URL)
        case unknown
    }

    public struct CommandResult: Sendable {
        public let exitCode: Int32
        public let standardOutput: String
        public let standardError: String

        public init(exitCode: Int32, standardOutput: String, standardError: String) {
            self.exitCode = exitCode
            self.standardOutput = standardOutput
            self.standardError = standardError
        }

        public var succeeded: Bool { exitCode == 0 }
        public var trimmedOutput: String {
            standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    public enum UpdateError: Error, Equatable, Sendable {
        case invalidVersion
        case downloadFailed(String)
        case mountFailed(String)
        case appNotFound
        case installFailed(String)
    }

    public typealias Run = @Sendable ([String]) -> CommandResult

    public static let appName = "Atrium.app"
    public static let appTarget = "/Applications/Atrium.app"
    public static let legacyAppName = "Notive.app"
    public static let legacyAppTarget = "/Applications/Notive.app"

    public let repository: String
    public let installationTarget: String
    private let installationName: String
    private let run: Run

    public init(
        repository: String = "Schramm2/notive",
        legacyInstallation: Bool = false,
        run: @escaping Run
    ) {
        self.repository = repository
        installationName = legacyInstallation ? Self.legacyAppName : Self.appName
        installationTarget = legacyInstallation ? Self.legacyAppTarget : Self.appTarget
        self.run = run
    }

    public static func live(repository: String = "Schramm2/notive") -> Self {
        Self(
            repository: repository,
            legacyInstallation: Bundle.main.bundleURL.lastPathComponent == legacyAppName,
            run: execute
        )
    }

    public func latestVersion() -> String? {
        let result = run([
            "gh", "release", "view",
            "--repo", repository,
            "--json", "tagName",
            "--jq", ".tagName",
        ])
        guard result.succeeded else { return nil }
        let tag = result.trimmedOutput
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        return Self.isValidVersion(version) ? version : nil
    }

    public func check(currentVersion: String) -> Status {
        guard let latestVersion = latestVersion() else { return .unknown }
        guard Self.isNewer(latestVersion, than: currentVersion) else { return .upToDate }
        guard let releaseURL = URL(
            string: "https://github.com/\(repository)/releases/tag/v\(latestVersion)"
        ) else { return .unknown }
        return .updateAvailable(version: latestVersion, releaseURL: releaseURL)
    }

    public func install(version: String) throws {
        guard Self.isValidVersion(version) else { throw UpdateError.invalidVersion }

        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
            .appending(path: "atrium-update-\(version)-\(UUID().uuidString)")
        let diskImage = temporaryDirectory.appending(path: diskImageName(version: version))
        let mountDirectory = temporaryDirectory.appending(path: "mount")
        let installIdentifier = UUID().uuidString
        let hiddenTarget = installationTarget.replacingOccurrences(
            of: "/Applications/",
            with: "/Applications/."
        )
        let stagedApp = "\(hiddenTarget).installing.\(installIdentifier)"
        let backupApp = "\(hiddenTarget).backup.\(installIdentifier)"

        try fileManager.createDirectory(at: mountDirectory, withIntermediateDirectories: true)
        defer {
            _ = run(["hdiutil", "detach", mountDirectory.path, "-quiet"])
            try? fileManager.removeItem(at: temporaryDirectory)
            try? fileManager.removeItem(atPath: stagedApp)
        }

        let download = run([
            "gh", "release", "download", "v\(version)",
            "--repo", repository,
            "--pattern", diskImage.lastPathComponent,
            "--output", diskImage.path,
        ])
        guard download.succeeded else {
            throw UpdateError.downloadFailed(Self.reason(download))
        }

        let mount = run([
            "hdiutil", "attach", diskImage.path,
            "-nobrowse", "-quiet", "-mountpoint", mountDirectory.path,
        ])
        guard mount.succeeded else { throw UpdateError.mountFailed(Self.reason(mount)) }

        let sourceApp = mountDirectory.appending(path: installationName)
        guard fileManager.fileExists(atPath: sourceApp.path) else {
            throw UpdateError.appNotFound
        }

        let stage = run(["ditto", "--rsrc", "--extattr", "--acl", sourceApp.path, stagedApp])
        guard stage.succeeded else { throw UpdateError.installFailed(Self.reason(stage)) }
        let stagedVerification = run(["codesign", "--verify", "--deep", "--strict", stagedApp])
        guard stagedVerification.succeeded else {
            throw UpdateError.installFailed(Self.reason(stagedVerification))
        }

        let targetExists = fileManager.fileExists(atPath: installationTarget)
        if targetExists {
            let backup = run(["mv", installationTarget, backupApp])
            guard backup.succeeded else { throw UpdateError.installFailed(Self.reason(backup)) }
        }

        let install = run(["mv", stagedApp, installationTarget])
        guard install.succeeded else {
            if targetExists { _ = run(["mv", backupApp, installationTarget]) }
            throw UpdateError.installFailed(Self.reason(install))
        }

        let verification = run(["codesign", "--verify", "--deep", "--strict", installationTarget])
        guard verification.succeeded else {
            _ = run(["rm", "-rf", installationTarget])
            if targetExists { _ = run(["mv", backupApp, installationTarget]) }
            throw UpdateError.installFailed(Self.reason(verification))
        }

        if targetExists { _ = run(["rm", "-rf", backupApp]) }
        _ = run(["xattr", "-dr", "com.apple.quarantine", installationTarget])
    }

    func diskImageName(version: String) -> String {
        "\(installationName.dropLast(4))-\(version)-arm64.dmg"
    }

    public static func isValidVersion(_ version: String) -> Bool {
        version.range(of: #"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$"#, options: .regularExpression) != nil
    }

    public static func isNewer(_ candidate: String, than current: String) -> Bool {
        guard let candidateParts = versionParts(candidate), let currentParts = versionParts(current) else {
            return false
        }
        for (candidatePart, currentPart) in zip(candidateParts, currentParts) {
            if candidatePart != currentPart { return candidatePart > currentPart }
        }
        return false
    }

    private static func versionParts(_ version: String) -> [Int]? {
        let bareVersion = version.hasPrefix("v") ? String(version.dropFirst()) : version
        let components = bareVersion.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count == 3 else { return nil }
        let values = components.compactMap { Int($0) }
        return values.count == components.count ? values : nil
    }

    private static func reason(_ result: CommandResult) -> String {
        let error = result.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
        if !error.isEmpty { return error }
        return result.trimmedOutput.isEmpty ? "exit \(result.exitCode)" : result.trimmedOutput
    }

    static func execute(_ arguments: [String]) -> CommandResult {
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
            return CommandResult(exitCode: -1, standardOutput: "", standardError: error.localizedDescription)
        }
        defer { try? fileManager.removeItem(at: captureDirectory) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments

        var environment = ProcessInfo.processInfo.environment
        let standardPaths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        environment["PATH"] = (standardPaths + [environment["PATH"] ?? ""]).joined(separator: ":")
        process.environment = environment

        do {
            let outputHandle = try FileHandle(forWritingTo: outputURL)
            let errorHandle = try FileHandle(forWritingTo: errorURL)
            process.standardOutput = outputHandle
            process.standardError = errorHandle
            try process.run()
            process.waitUntilExit()
            try outputHandle.close()
            try errorHandle.close()
            return CommandResult(
                exitCode: process.terminationStatus,
                standardOutput: String(decoding: try Data(contentsOf: outputURL), as: UTF8.self),
                standardError: String(decoding: try Data(contentsOf: errorURL), as: UTF8.self)
            )
        } catch {
            return CommandResult(exitCode: -1, standardOutput: "", standardError: error.localizedDescription)
        }
    }
}
