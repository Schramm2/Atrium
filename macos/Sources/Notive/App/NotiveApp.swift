import AppKit
import NotiveCore
import SwiftUI
import UserNotifications

@main
struct NotiveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: AppStore?
    @State private var startupError: String?
    @State private var updater = UpdaterService()

    init() {
        do {
            let store = try AppStore()
            _store = State(initialValue: store)
            _updater = State(initialValue: UpdaterService(
                installationBlocker: { Self.updateInstallationBlockReason(for: store) }
            ))
        } catch {
            _startupError = State(initialValue: error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup("Notive", id: "workspace") {
            Group {
                if let store {
                    ContentView(store: store, updater: updater)
                        .task { store.start() }
                        .task { await updater.checkAutomaticallyIfEnabled() }
                        .onChange(of: scenePhase) { _, phase in
                            guard phase == .active else { return }
                            Task { await updater.checkAutomaticallyIfEnabled() }
                        }
                } else {
                    ContentUnavailableView(
                        "Notive could not open",
                        systemImage: "exclamationmark.triangle",
                        description: Text(startupError ?? "The local database is unavailable.")
                    )
                }
            }
            .frame(minWidth: 960, minHeight: 640)
        }
        .defaultSize(width: 1_100, height: 700)
        .commands {
            CommandGroup(after: .appInfo) {
                Button(updater.primaryActionTitle) {
                    Task { await updater.performPrimaryAction() }
                }
                .disabled(!updater.canPerformPrimaryAction)
            }
            CommandMenu("Meeting") {
                Button("New Meeting") {
                    store?.createMeeting()
                }
                .keyboardShortcut("n")

                Button("Ask Notive") {
                    store?.select(.ask)
                }
                .keyboardShortcut("k")
            }
        }

        Settings {
            SettingsView(store: store, updater: updater)
        }

        MenuBarExtra("Notive", systemImage: "waveform.badge.mic") {
            MenuBarView(store: store)
        }
        .menuBarExtraStyle(.menu)
    }

    private static func updateInstallationBlockReason(for store: AppStore) -> String? {
        switch store.recordingState {
        case .recording, .paused, .transcribing:
            return "Finish the active recording or transcription before updating."
        case .idle, .failed:
            break
        }
        if store.isDictating || store.isPreparingDictation || store.isProcessingDictation {
            return "Finish dictation before updating."
        }
        if store.isImportingAudio || store.isRetranscribing || store.isGeneratingSummary {
            return "Finish the active meeting task before updating."
        }
        return nil
    }
}

private struct MenuBarView: View {
    let store: AppStore?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Notive") {
            openWindow(id: "workspace")
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        if let store {
            switch store.recordingState {
            case .recording, .paused:
                Button("Stop Recording") { Task { await store.stopRecording() } }
            case .transcribing:
                Text("Transcribing…")
            case .idle, .failed:
                Button("Start Recording") { Task { await store.startRecording() } }
            }
            Button("Ask Notive") {
                store.select(.ask)
                openWindow(id: "workspace")
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        Divider()
        Button("Quit Notive") { NSApp.terminate(nil) }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        GlobalDictationShortcut.shared.refreshAccessibility()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
