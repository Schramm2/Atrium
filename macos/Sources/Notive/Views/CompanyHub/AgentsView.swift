import NotiveCore
import SwiftUI

/// Agent roster beside a shared chat thread.
struct AgentsView: View {
    @Environment(CompanyHubStore.self) private var hub

    var body: some View {
        BrandScreen {
            VStack(alignment: .leading, spacing: 20) {
                NotivePageHeader(
                    "Agents",
                    detail: "Company agents work alongside the team. Chat with them, watch their runs, and review their output."
                ) {
                    BrandStatusLabel(
                        title: agentSummary,
                        systemImage: "sparkles",
                        kind: hub.agents.isEmpty ? .warning : .processing
                    )
                }

                if hub.agents.isEmpty {
                    HubEmptyState.notConnected(
                        "No agents",
                        systemImage: "bolt",
                        appears: "Company agents, their runs, and their company-visible chat threads appear here.",
                        minHeight: 360
                    )
                } else {
                    HStack(alignment: .top, spacing: 20) {
                        AgentRoster()
                            .frame(minWidth: 230, idealWidth: 300, maxWidth: 320)
                        AgentThread()
                            .frame(minWidth: 360, maxWidth: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .padding(32)
            .frame(maxWidth: 1_360, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("Agents")
        .task { await hub.loadAgents() }
    }

    private var agentSummary: String {
        guard !hub.agents.isEmpty else { return "Not connected" }
        return "\(hub.agents.count) agents · \(hub.runningAgentCount) running"
    }
}
