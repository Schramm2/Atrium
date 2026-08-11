import AppKit
import NotiveCore
import SwiftUI
import UserNotifications

@main
struct NotiveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store: AppStore?
    @State private var startupError: String?
    private let updater = UpdaterService()

    init() {
        do {
            _store = State(initialValue: try AppStore())
        } catch {
            _startupError = State(initialValue: error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup("Notive", id: "workspace") {
            Group {
                if let store {
                    ContentView(store: store)
                        .task { store.start() }
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
                Button("Check for Updates…") {
                    updater.checkForUpdates()
                }
                .disabled(!updater.canCheckForUpdates)
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
