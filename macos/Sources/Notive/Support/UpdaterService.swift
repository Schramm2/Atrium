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
        case installing(String)
        case failed(String)
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
    private var performedAutomaticCheck = false
    private static let automaticChecksKey = "notive.updates.automatic"

    init(updater: GitHubReleaseUpdater = .live()) {
        self.updater = updater
        let defaults = UserDefaults.standard
        automaticallyChecksForUpdates = defaults.object(forKey: Self.automaticChecksKey) == nil
            ? true
            : defaults.bool(forKey: Self.automaticChecksKey)
    }

    var canPerformPrimaryAction: Bool {
        switch phase {
        case .checking, .installing: false
        case .idle, .upToDate, .available, .failed: true
        }
    }

    var primaryActionTitle: String {
        if case .available(let version) = phase {
            "Install Update v\(version)…"
        } else {
            "Check for Updates…"
        }
    }

    var statusText: String {
        switch phase {
        case .idle: "Updates use the authenticated GitHub CLI."
        case .checking: "Checking GitHub Releases…"
        case .upToDate: "Notive \(AppVersion.current) is current."
        case .available(let version): "Notive \(version) is available."
        case .installing(let message): message
        case .failed(let message): message
        }
    }

    func checkAutomaticallyIfEnabled() async {
        guard automaticallyChecksForUpdates, !performedAutomaticCheck else { return }
        performedAutomaticCheck = true
        await checkForUpdates()
    }

    func performPrimaryAction() async {
        if case .available = phase {
            await installAvailableUpdate()
        } else {
            await checkForUpdates()
        }
    }

    func checkForUpdates() async {
        guard canPerformPrimaryAction else { return }
        phase = .checking
        let updater = updater
        let currentVersion = AppVersion.current
        let status = await Task.detached(priority: .utility) {
            updater.check(currentVersion: currentVersion)
        }.value
        switch status {
        case .upToDate:
            phase = .upToDate
        case .updateAvailable(let version, _):
            phase = .available(version)
        case .unknown:
            phase = .failed("Could not check releases. Install GitHub CLI and sign in with access to Schramm2/notive.")
        }
    }

    private func installAvailableUpdate() async {
        guard case .available(let version) = phase else { return }
        phase = .installing("Downloading Notive \(version)…")
        let updater = updater
        do {
            try await Task.detached(priority: .userInitiated) {
                try updater.install(version: version)
            }.value
            phase = .installing("Relaunching Notive \(version)…")
            relaunch()
        } catch {
            phase = .failed(Self.message(for: error))
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
