import NotiveCore
import SwiftUI

/// Scrollable list of agent cards.
struct AgentRoster: View {
    @Environment(CompanyHubStore.self) private var hub

    var body: some View {
        @Bindable var hub = hub

        ScrollView {
            VStack(spacing: 10) {
                ForEach(hub.agents) { agent in
                    AgentRosterCard(
                        agent: agent,
                        isSelected: agent.id == hub.selectedAgent?.id
                    ) {
                        hub.selectedAgentID = agent.id
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .onChange(of: hub.selectedAgentID) {
            Task { await hub.loadThread() }
        }
    }
}
