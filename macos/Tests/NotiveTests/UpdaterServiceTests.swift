import Foundation
import NotiveCore
import Testing
@testable import Notive

@MainActor
@Suite("Update presentation")
struct UpdaterServiceTests {
    @Test("A newer release creates a visible update notice")
    func availableNotice() async {
        let service = UpdaterService(
            updater: updater(sequence: ["v0.5.2"]),
            currentVersion: "0.5.1"
        )

        await service.checkForUpdates()

        #expect(service.phase == .available("0.5.2"))
        #expect(service.updateNoticeVersion == "0.5.2")
        #expect(service.primaryActionTitle == "Update to v0.5.2…")
    }

    @Test("Automatic checks can discover a release published after launch")
    func automaticRefresh() async {
        let service = UpdaterService(
            updater: updater(sequence: ["v0.5.1", "v0.5.2"]),
            currentVersion: "0.5.1"
        )
        service.automaticallyChecksForUpdates = true

        await service.checkAutomaticallyIfEnabled()
        #expect(service.phase == .upToDate)

        await service.checkAutomaticallyIfEnabled()
        #expect(service.phase == .available("0.5.2"))
    }

    @Test("Active work keeps the update visible but blocks installation")
    func activeWorkBlocksInstallation() async {
        let service = UpdaterService(
            updater: updater(sequence: ["v0.5.2"]),
            currentVersion: "0.5.1",
            installationBlocker: { "Finish recording before updating." }
        )

        await service.checkForUpdates()

        #expect(service.updateNoticeVersion == "0.5.2")
        #expect(!service.canPerformPrimaryAction)
        #expect(service.installationBlockReason == "Finish recording before updating.")
    }

    private func updater(sequence: [String]) -> GitHubReleaseUpdater {
        let releases = ReleaseSequence(sequence)
        return GitHubReleaseUpdater { arguments in
            guard arguments.starts(with: ["gh", "release", "view"]),
                  let release = releases.next() else {
                return .init(exitCode: 1, standardOutput: "", standardError: "No release")
            }
            return .init(exitCode: 0, standardOutput: "\(release)\n", standardError: "")
        }
    }
}

private final class ReleaseSequence: @unchecked Sendable {
    private let lock = NSLock()
    private var releases: [String]

    init(_ releases: [String]) {
        self.releases = releases
    }

    func next() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return releases.isEmpty ? nil : releases.removeFirst()
    }
}
