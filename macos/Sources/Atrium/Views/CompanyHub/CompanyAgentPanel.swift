import AtriumCore
import SwiftUI

/// The agent list, with a link to the Agents screen.
struct CompanyAgentPanel: View {
    @Bindable var store: AppStore
    @Environment(CompanyHubStore.self) private var hub
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader(title: "Agents") {
                Button("Open Agents", action: openAgents)
                    .buttonStyle(.link)
                    .font(.callout.weight(.semibold))
            }

            if hub.agents.isEmpty {
                HubEmptyState.notConnected(
                    "No agents",
                    systemImage: "bolt",
                    appears: "Company agents and their current work appear here.",
                    minHeight: 160
                )
            } else {
                HubRowPanel(items: hub.agents) { agent in
                    HubRowButton(action: openAgents) {
                        HStack(spacing: 12) {
                            HubAvatar(
                                initials: agent.initials,
                                tint: agent.tint,
                                size: 30,
                                cornerRadius: 8
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(agent.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(agent.task)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            HubStatusDot(
                                title: agent.status.title,
                                color: agent.status.color(palette)
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                    }
                }
            }
        }
    }

    private func openAgents() {
        store.select(.agents)
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
