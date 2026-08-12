import NotiveCore
import SwiftUI

/// Company Hub landing screen.
struct CompanyDashboardView: View {
    @Bindable var store: AppStore
    @Environment(CompanyHubStore.self) private var hub

    var body: some View {
        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    NotivePageHeader(
                        "Company today",
                        detail: "What Ubundi and First Motive shared, decided, and ran — across people and agents."
                    ) {
                        BrandStatusLabel(
                            title: hub.isConnected ? "Shared workspace" : "Not connected",
                            systemImage: hub.isConnected ? "square.stack.3d.up" : "square.stack.3d.up.slash",
                            kind: hub.isConnected ? .local : .warning
                        )
                    }

                    if hub.stats.isEmpty {
                        HubEmptyState.notConnected(
                            "No company activity yet",
                            systemImage: "chart.line.uptrend.xyaxis",
                            appears: "Shared meetings, agent runs, and open action items across both companies appear here.",
                            minHeight: 280
                        )
                    } else {
                        CompanyStatStrip(stats: hub.stats)
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: 24) {
                                SharedTodayPanel(store: store)
                                    .frame(maxWidth: .infinity)
                                CompanyAgentColumn(store: store)
                                    .frame(width: 380)
                            }
                            VStack(alignment: .leading, spacing: 24) {
                                SharedTodayPanel(store: store)
                                CompanyAgentColumn(store: store)
                            }
                        }
                    }

                    HubPrivacyFootnote(
                        text: "Only meetings and notes their owners chose to share appear here. Everything else stays on each person's Mac."
                    )
                }
                .padding(32)
                .frame(maxWidth: 1_280, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Company")
        .task { await hub.loadCompanyScreen() }
    }
}
