import Combine
import Sparkle

@MainActor
final class UpdaterService: ObservableObject {
    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var automaticallyChecksForUpdates = true

    let controller: SPUStandardUpdaterController
    private var cancellables: Set<AnyCancellable> = []

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        let updater = controller.updater
        updater.publisher(for: \.canCheckForUpdates)
            .sink { [weak self] value in
                self?.canCheckForUpdates = value
            }
            .store(in: &cancellables)
        updater.publisher(for: \.automaticallyChecksForUpdates)
            .sink { [weak self] value in
                self?.automaticallyChecksForUpdates = value
            }
            .store(in: &cancellables)

        migrateLegacyPreferenceIfNeeded(updater: updater)
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }

    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
        controller.updater.automaticallyChecksForUpdates = enabled
    }

    private func migrateLegacyPreferenceIfNeeded(updater: SPUUpdater) {
        let defaults = UserDefaults.standard
        let migrationKey = "notive.updates.sparkle-preference-migrated"
        guard !defaults.bool(forKey: migrationKey) else { return }
        if defaults.object(forKey: "notive.updates.automatic") != nil {
            updater.automaticallyChecksForUpdates = defaults.bool(
                forKey: "notive.updates.automatic"
            )
        }
        defaults.set(true, forKey: migrationKey)
    }
}
