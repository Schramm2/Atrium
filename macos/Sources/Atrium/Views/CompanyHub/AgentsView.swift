import SwiftUI

/// Placeholder for the office-local Bongi agent.
struct BongiLocalAgentView: View {
    @State private var message = ""

    var body: some View {
        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AtriumPageHeader(
                        "Bongi - Local Agent",
                        detail: "Message the office-local agent from Atrium when its connection is set up."
                    ) {
                        BrandStatusLabel(
                            title: "Setup required",
                            systemImage: "desktopcomputer",
                            kind: .warning
                        )
                    }

                    BrandPanel {
                        VStack(alignment: .leading, spacing: 20) {
                            ContentUnavailableView(
                                "Bongi is not connected",
                                systemImage: "server.rack",
                                description: Text("Configure the office connection to start a private conversation with Bongi. Cloud company agents are not available here.")
                            )
                            .frame(maxWidth: .infinity, minHeight: 220)

                            Divider()

                            HStack(spacing: 12) {
                                TextField("Message Bongi", text: $message)
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(true)

                                Button("Send", systemImage: "arrow.up") {}
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.large)
                                    .disabled(true)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Bongi message composer, unavailable until Bongi is connected")
                        }
                    }
                }
                .padding(32)
                .frame(maxWidth: 1_080, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Bongi - Local Agent")
    }
}
