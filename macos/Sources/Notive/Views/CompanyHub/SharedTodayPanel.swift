import NotiveCore
import SwiftUI

/// Items the team shared to the hub today.
struct SharedTodayPanel: View {
    @Bindable var store: AppStore
    @Environment(CompanyHubStore.self) private var hub

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader(title: "Shared today") {
                Button("Open Shared Context", action: openSharedContext)
                    .buttonStyle(.link)
                    .font(.callout.weight(.semibold))
            }

            if hub.sharedToday.isEmpty {
                HubEmptyState.notConnected(
                    "Nothing shared today",
                    systemImage: "square.stack.3d.up",
                    appears: "Meetings, notes, and agent output the team shares appear here.",
                    minHeight: 180
                )
            } else {
                HubRowPanel(items: hub.sharedToday) { item in
                    HubRowButton(action: openSharedContext) {
                        SharedTodayRow(item: item)
                    }
                }
            }
        }
    }

    private func openSharedContext() {
        store.select(.sharedContext)
    }
}
