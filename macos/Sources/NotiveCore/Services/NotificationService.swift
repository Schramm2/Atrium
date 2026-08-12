import Foundation
import UserNotifications

public actor NotificationService {
    static let errorPreferenceKey = "notive.notifications.errors"
    static let testPreferenceKey = "notive.notifications.test"

    public init() {}

    @discardableResult
    public func send(
        title: String,
        body: String,
        preferenceKey: String,
        defaultEnabled: Bool
    ) async -> Bool {
        let defaults = UserDefaults.standard
        let enabled = defaults.object(forKey: preferenceKey) == nil
            ? defaultEnabled
            : defaults.bool(forKey: preferenceKey)
        guard Self.shouldSend(
            paused: defaults.bool(forKey: "notive.notifications.paused"),
            preferenceKey: preferenceKey,
            enabled: enabled
        ) else { return false }
        // UserNotifications requires an application bundle. SwiftPM tests and
        // command-line launches do not have one and can raise an Objective-C
        // exception before the async API can return an error.
        guard Bundle.main.bundleURL.pathExtension == "app" else { return false }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        var authorized = Self.isAuthorized(settings.authorizationStatus)
        if settings.authorizationStatus == .notDetermined {
            authorized = (try? await center.requestAuthorization(options: [.alert, .sound])) == true
        }
        guard authorized else { return false }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if defaults.object(forKey: "notive.notifications.sound") == nil
            || defaults.bool(forKey: "notive.notifications.sound") {
            content.sound = .default
        }
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    public func sendTest() async -> Bool {
        await send(
            title: "Notive notifications are working",
            body: "Recording and transcription updates can appear here.",
            preferenceKey: Self.testPreferenceKey,
            defaultEnabled: true
        )
    }

    static func shouldSend(
        paused: Bool,
        preferenceKey: String,
        enabled: Bool
    ) -> Bool {
        guard enabled else { return false }
        return !paused
            || preferenceKey == errorPreferenceKey
            || preferenceKey == testPreferenceKey
    }

    static func isAuthorized(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            true
        case .denied, .notDetermined:
            false
        @unknown default:
            false
        }
    }
}
