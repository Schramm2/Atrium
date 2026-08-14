@testable import AtriumCore
import Testing
import UserNotifications

@Suite("Notification preferences")
struct NotificationServiceTests {
    @Test("Disabled notification categories stay disabled")
    func disabledCategory() {
        #expect(!NotificationService.shouldSend(
            paused: false,
            preferenceKey: "notive.notifications.recording",
            enabled: false
        ))
    }

    @Test("Pause suppresses ordinary notifications")
    func pausedOrdinaryNotification() {
        #expect(!NotificationService.shouldSend(
            paused: true,
            preferenceKey: "notive.notifications.recording",
            enabled: true
        ))
    }

    @Test("Errors and explicit tests bypass pause")
    func criticalNotifications() {
        #expect(NotificationService.shouldSend(
            paused: true,
            preferenceKey: NotificationService.errorPreferenceKey,
            enabled: true
        ))
        #expect(NotificationService.shouldSend(
            paused: true,
            preferenceKey: NotificationService.testPreferenceKey,
            enabled: true
        ))
    }

    @Test("Every macOS delivery authorization is accepted")
    func authorizationVariants() {
        #expect(NotificationService.isAuthorized(.authorized))
        #expect(NotificationService.isAuthorized(.provisional))
        #expect(!NotificationService.isAuthorized(.denied))
        #expect(!NotificationService.isAuthorized(.notDetermined))
    }
}
