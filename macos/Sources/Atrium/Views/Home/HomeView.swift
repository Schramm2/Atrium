import AtriumCore
import SwiftUI

/// The Home screen: local capture and meetings beside what the Company Hub shares.
struct HomeView: View {
    @Bindable var store: AppStore
    @Environment(CompanyHubStore.self) private var hub

    var body: some View {
        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HomeGreetingHeader(store: store)

                    HomeWorkflowStrip(store: store)

                    if !hub.stats.isEmpty {
                        CompanyStatStrip(stats: hub.stats)
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 24) {
                            workspaceColumn
                                .frame(maxWidth: .infinity)
                            companyColumn
                                .frame(width: 380)
                        }
                        VStack(alignment: .leading, spacing: 24) {
                            workspaceColumn
                            companyColumn
                        }
                    }

                    HubPrivacyFootnote(
                        text: "Recordings, transcripts, notes, searches, and citations stay on this Mac. You choose for each meeting what reaches the Company Hub."
                    )
                }
                .padding(32)
                .frame(maxWidth: 1_340, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Home")
        .task { await hub.loadHomeScreen() }
    }

    private var workspaceColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !hub.attention.isEmpty {
                HomeAttentionPanel(store: store)
            }

            if store.searchResults.isEmpty {
                HomeRecentMeetingsPanel(store: store)
            } else {
                HomeSearchResultsPanel(store: store)
            }

            if !hub.sharedToday.isEmpty {
                SharedTodayPanel(store: store)
            }
        }
    }

    @ViewBuilder
    private var companyColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            if hub.hasSharedContent {
                if !hub.agents.isEmpty {
                    CompanyAgentPanel(store: store)
                }
                if !hub.people.isEmpty {
                    HomePeoplePanel(store: store)
                }
                if !hub.activity.isEmpty {
                    LatestActivityPanel(store: store)
                }
            } else {
                HubEmptyState.notConnected(
                    "No company activity",
                    systemImage: "square.stack.3d.up",
                    appears: "Agents, people, and shared items from Ubundi and First Motive appear here.",
                    minHeight: 200
                )
            }
        }
    }
}
