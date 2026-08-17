import AtriumCore
import SwiftUI

/// Entry point for the office-local Bongi agent.
struct CompanyAgentPanel: View {
    @Bindable var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader(title: "Bongi - Local Agent") {
                Button("Open Bongi", action: openBongi)
                    .buttonStyle(.link)
                    .font(.callout.weight(.semibold))
            }

            BrandPanel(padding: 0) {
                ContentUnavailableView(
                    "Bongi is not connected",
                    systemImage: "desktopcomputer",
                    description: Text("Set up the office connection to begin using Bongi.")
                )
                .frame(maxWidth: .infinity, minHeight: 160)
            }
        }
    }

    private func openBongi() {
        store.select(.agents)
    }
}
