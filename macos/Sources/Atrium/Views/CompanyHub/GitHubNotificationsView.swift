import AtriumCore
import SwiftUI

struct GitHubNotificationsView: View {
    let notifications: [GitHubNotification]
    @State private var showsAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader(title: "Notifications") {
                Text("\(notifications.count) unread")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            BrandPanel(padding: 0) {
                if notifications.isEmpty {
                    ContentUnavailableView(
                        "No unread notifications",
                        systemImage: "bell",
                        description: Text("Mentions, review requests, workflow updates, and subscribed activity appear here.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(visibleNotifications.enumerated()), id: \.element.id) { index, notification in
                            Link(destination: notification.url) {
                                HStack(spacing: 12) {
                                    Image(systemName: symbol(for: notification))
                                        .foregroundStyle(.tint)
                                        .frame(width: 18)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(notification.title)
                                            .font(.subheadline.weight(.semibold))
                                            .lineLimit(1)
                                        Text("\(notification.repositoryFullName) · \(notification.reasonTitle)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 8)
                                    Text(notification.updatedAt, format: .relative(presentation: .numeric))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)
                            .accessibilityHint("Opens on GitHub")

                            if index < visibleNotifications.count - 1 || notifications.count > visibleNotifications.count {
                                Divider()
                            }
                        }

                        if notifications.count > 12 {
                            Button(showsAll ? "Show fewer" : "Show all \(notifications.count)") {
                                showsAll.toggle()
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.tint)
                            .padding(16)
                        }
                    }
                }
            }
        }
    }

    private var visibleNotifications: ArraySlice<GitHubNotification> {
        notifications.prefix(showsAll ? notifications.count : 12)
    }

    private func symbol(for notification: GitHubNotification) -> String {
        switch notification.type {
        case "PullRequest": "arrow.triangle.pull"
        case "Issue": "smallcircle.filled.circle"
        case "CheckSuite", "WorkflowRun": "checkmark.circle"
        case "Release": "shippingbox"
        default: "bell"
        }
    }
}
