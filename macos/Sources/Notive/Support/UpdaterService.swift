import AppKit
import NotiveCore
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
            "Checking for Updates…"
        case .available(let version):
            "Update to v\(version)…"
        case .installing:
            "Installing Update…"
        case .failed(_, let version?):
            "Update to v\(version)…"
        case .idle, .upToDate, .failed:
            "Check for Updates…"
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
        case .idle: "Updates use the authenticated GitHub CLI."
        case .checking: "Checking GitHub Releases…"
        case .upToDate: "Notive \(currentVersion) is current."
        case .available(let version): "Notive \(version) is available."
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
        let updater = updater
        let currentVersion = currentVersion
        let status = await Task.detached(priority: .utility) {
            updater.check(currentVersion: currentVersion)
        }.value
        switch status {
        case .upToDate:
            phase = .upToDate
        case .updateAvailable(let version, _):
            phase = .available(version)
        case .unknown:
            phase = .failed(
                message: "Could not check releases. Install GitHub CLI and sign in with access to Schramm2/notive.",
                availableVersion: nil
            )
        }
    }

    private func installAvailableUpdate(version: String) async {
        guard installationBlockReason == nil else { return }
        phase = .installing(version: version, message: "Downloading Notive \(version)…")
        let updater = updater
        do {
            try await Task.detached(priority: .userInitiated) {
                try updater.install(version: version)
            }.value
            phase = .installing(version: version, message: "Relaunching Notive \(version)…")
            relaunch()
        } catch {
            phase = .failed(
                message: Self.message(for: error),
                availableVersion: version
            )
        }
    }

    private func relaunch() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "sleep 1; open '/Applications/Notive.app'"]
        try? process.run()
        NSApp.terminate(nil)
    }

    private static func message(for error: Error) -> String {
        guard let updateError = error as? GitHubReleaseUpdater.UpdateError else {
            return "The update stopped. Notive is still on the current version."
        }
        switch updateError {
        case .invalidVersion:
            return "The release version is invalid."
        case .downloadFailed:
            return "The update could not download. Check GitHub CLI access and try again."
        case .mountFailed:
            return "The downloaded disk image could not open."
        case .appNotFound:
            return "The release does not contain Notive.app."
        case .installFailed:
            return "The update could not replace Notive. The current installation was preserved."
        }
    }
}
