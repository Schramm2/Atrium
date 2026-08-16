import Foundation
import Testing
@testable import AtriumCore

@Suite("GitHub release updater")
struct GitHubReleaseUpdaterTests {
    @Test("Updates follow the installed application bundle")
    func applicationTarget() {
        let atrium = GitHubReleaseUpdater(run: unusedRun)
        let legacy = GitHubReleaseUpdater(legacyInstallation: true, run: unusedRun)

        #expect(atrium.installationTarget == "/Applications/Atrium.app")
        #expect(atrium.diskImageName(version: "0.9.3") == "Atrium-0.9.3-arm64.dmg")
        #expect(legacy.installationTarget == "/Applications/Notive.app")
        #expect(legacy.diskImageName(version: "0.9.3") == "Notive-0.9.3-arm64.dmg")
    }

    @Test("Latest release tags are parsed")
    func latestVersion() {
        #expect(updater(tag: "v0.6.0").latestVersion() == "0.6.0")
        #expect(updater(tag: "0.6.1").latestVersion() == "0.6.1")
        #expect(updater(tag: "nightly").latestVersion() == nil)
        #expect(updater(tag: nil).latestVersion() == nil)
    }

    @Test("Only a newer release is offered")
    func updateStatus() {
        let newer = updater(tag: "v0.6.0").check(currentVersion: "0.5.0")
        guard case .updateAvailable(let version, let releaseURL) = newer else {
            Issue.record("Expected an available update")
            return
        }
        #expect(version == "0.6.0")
        #expect(releaseURL.absoluteString == "https://github.com/Schramm2/Atrium/releases/tag/v0.6.0")
        #expect(updater(tag: "v0.5.0").check(currentVersion: "0.5.0") == .upToDate)
        #expect(updater(tag: "v0.4.9").check(currentVersion: "0.5.0") == .upToDate)
        #expect(updater(tag: nil).check(currentVersion: "0.5.0") == .unknown)
    }

    @Test("Stable versions compare numerically")
    func versionComparison() {
        #expect(GitHubReleaseUpdater.isNewer("0.5.1", than: "0.5.0"))
        #expect(GitHubReleaseUpdater.isNewer("0.10.0", than: "0.9.9"))
        #expect(GitHubReleaseUpdater.isNewer("1.0.0", than: "0.99.99"))
        #expect(!GitHubReleaseUpdater.isNewer("0.5.0", than: "0.5.0"))
        #expect(!GitHubReleaseUpdater.isNewer("0.4.9", than: "0.5.0"))
        #expect(!GitHubReleaseUpdater.isNewer("nightly", than: "0.5.0"))
    }

    @Test("Only stable semantic versions are accepted")
    func versionValidation() {
        #expect(GitHubReleaseUpdater.isValidVersion("0.6.0"))
        #expect(!GitHubReleaseUpdater.isValidVersion("v0.6.0"))
        #expect(!GitHubReleaseUpdater.isValidVersion("0.6.0-rc.1"))
        #expect(!GitHubReleaseUpdater.isValidVersion("../etc"))
    }

    private var unusedRun: GitHubReleaseUpdater.Run {
        { _ in .init(exitCode: 1, standardOutput: "", standardError: "unused") }
    }

    private func updater(tag: String?) -> GitHubReleaseUpdater {
        GitHubReleaseUpdater { arguments in
            guard arguments.starts(with: ["gh", "release", "view"]), let tag else {
                return .init(exitCode: 1, standardOutput: "", standardError: "not authenticated")
            }
            return .init(exitCode: 0, standardOutput: "\(tag)\n", standardError: "")
        }
    }
}
