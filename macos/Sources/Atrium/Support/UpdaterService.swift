import AppKit
import AtriumCore
import Observation

@MainActor
@Observable
final class UpdaterService {
    enum Phase: Equatable {
        case idle
        case checking
        case upToDate
        case available(String)
        case installing(version: String, message: String)
        case failed(message: String, availableVersion: String?)
    }

    private(set) var phase: Phase = .idle
    var automaticallyChecksForUpdates: Bool {
        didSet {
            UserDefaults.standard.set(
                automaticallyChecksForUpdates,
                forKey: Self.automaticChecksKey
            )
        }
    }

    private let updater: GitHubReleaseUpdater
    let currentVersion: String
    private let installationBlocker: @MainActor () -> String?
    private static let automaticChecksKey = "notive.updates.automatic"

    init(
        updater: GitHubReleaseUpdater = .live(),
        currentVersion: String = AppVersion.current,
        installationBlocker: @escaping @MainActor () -> String? = { nil }
    ) {
        self.updater = updater
        self.currentVersion = currentVersion
        self.installationBlocker = installationBlocker
        let defaults = UserDefaults.standard
        automaticallyChecksForUpdates = defaults.object(forKey: Self.automaticChecksKey) == nil
            ? true
            : defaults.bool(forKey: Self.automaticChecksKey)
    }

    var canPerformPrimaryAction: Bool {
        switch phase {
        case .checking, .installing: false
        case .available: installationBlockReason == nil
        case .failed(_, let version): version == nil || installationBlockReason == nil
        case .idle, .upToDate: true
        }
    }

    var primaryActionTitle: String {
        switch phase {
        case .checking:
            "Checking for updates…"
        case .available(let version):
            "Update to \(version)…"
        case .installing:
            "Installing update…"
        case .failed(_, let version?):
            "Update to \(version)…"
        case .idle, .upToDate, .failed:
            "Check for updates…"
        }
    }

    var updateNoticeVersion: String? {
        switch phase {
        case .available(let version), .installing(let version, _): version
        case .failed(_, let version): version
        case .idle, .checking, .upToDate: nil
        }
    }

    var installationBlockReason: String? {
        installationBlocker()
    }

    var statusText: String {
        switch phase {
        case .idle: "Atrium checks for updates automatically when enabled."
        case .checking: "Checking for updates…"
        case .upToDate: "Atrium \(currentVersion) is up to date."
        case .available(let version): "Atrium version \(version) is available."
        case .installing(_, let message): message
        case .failed(let message, _): message
        }
    }

    func checkAutomaticallyIfEnabled() async {
        guard automaticallyChecksForUpdates, updateNoticeVersion == nil else { return }
        await checkForUpdates()
    }

    func performPrimaryAction() async {
        switch phase {
        case .available(let version), .failed(_, .some(let version)):
            await installAvailableUpdate(version: version)
        case .idle, .checking, .upToDate, .installing, .failed:
            await checkForUpdates()
        }
    }

    func checkForUpdates() async {
        guard canPerformPrimaryAction else { return }
        phase = .checking
        DiagnosticLogger.started(
            operation: "update_check",
            context: "current_version=\(currentVersion)"
        )
        let updater = updater
        let currentVersion = currentVersion
        let status = await Task.detached(priority: .utility) {
            updater.check(currentVersion: currentVersion)
        }.value
        switch status {
        case .upToDate:
            phase = .upToDate
            DiagnosticLogger.success(operation: "update_check")
        case .updateAvailable(let version, _):
            phase = .available(version)
            DiagnosticLogger.success(
                operation: "update_check",
                context: "update_available=true target_version=\(version)"
            )
        case .unknown:
            phase = .failed(
                message: "Atrium could not check for updates. Check your internet connection and try again.",
                availableVersion: nil
            )
            DiagnosticLogger.failure(
                operation: "update_check",
                error: UpdateDiagnosticError.statusUnavailable
            )
        }
    }

    private func installAvailableUpdate(version: String) async {
        guard installationBlockReason == nil else { return }
        phase = .installing(version: version, message: "Downloading Atrium \(version)…")
        let updater = updater
        do {
            try await Task.detached(priority: .userInitiated) {
                try updater.install(version: version)
            }.value
            phase = .installing(version: version, message: "Relaunching Atrium \(version)…")
            relaunch()
        } catch {
            DiagnosticLogger.failure(
                operation: "update_install",
                error: error,
                context: "target_version=\(version)"
            )
            phase = .failed(
                message: Self.message(for: error),
                availableVersion: version
            )
        }
    }

    private func relaunch() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "sleep 1; open '\(updater.installationTarget)'"]
        try? process.run()
        NSApp.terminate(nil)
    }

    private static func message(for error: Error) -> String {
        guard let updateError = error as? GitHubReleaseUpdater.UpdateError else {
            return "The update stopped. Atrium is still on the current version. Try again later."
        }
        switch updateError {
        case .invalidVersion:
            return "Atrium cannot use this update. Try again later."
        case .downloadFailed:
            return "The update could not download. Check your internet connection and try again."
        case .mountFailed:
            return "Atrium could not open the downloaded update. Try again."
        case .appNotFound:
            return "This update is incomplete and cannot be installed. Try again later."
        case .installFailed:
            return "Atrium could not install the update. Your current version is unchanged. Quit other copies of Atrium, then try again."
        }
    }
}

private enum UpdateDiagnosticError: LocalizedError {
    case statusUnavailable

    var errorDescription: String? { "The update service returned an unknown status." }
}
