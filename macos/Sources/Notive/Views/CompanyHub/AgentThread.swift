import NotiveCore
import SwiftUI

/// The company-visible chat thread for the selected agent.
struct AgentThread: View {
    @Environment(CompanyHubStore.self) private var hub
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            if let agent = hub.selectedAgent {
                header(agent)
                Divider()
                messages(agent)
                Divider()
                composer(agent)
            }
        }
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12).stroke(palette.border, lineWidth: 1)
        }
    }

    private func header(_ agent: HubAgent) -> some View {
        HStack(spacing: 10) {
            HubAvatar(initials: agent.initials, tint: agent.tint, size: 28, cornerRadius: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(agent.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(agent.role) · visible to the whole company")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            HubStatusDot(title: agent.status.title, color: agent.status.color(palette))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func messages(_ agent: HubAgent) -> some View {
        if hub.thread.isEmpty {
            ContentUnavailableView(
                "No messages",
                systemImage: "bubble.left.and.text.bubble.right",
                description: Text("Messages to \(agent.name) are visible to the whole company.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(hub.thread) { message in
                        AgentChatBubble(message: message)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func composer(_ agent: HubAgent) -> some View {
        HStack(spacing: 10) {
            TextField(
                "Message \(agent.name)",
                text: $draft,
                prompt: Text("Message \(agent.name) — the whole team can see this thread")
            )
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(palette.raisedSurface, in: RoundedRectangle(cornerRadius: 9))
            .overlay {
                RoundedRectangle(cornerRadius: 9).stroke(palette.border, lineWidth: 1)
            }
            .onSubmit(send)
            .disabled(!hub.isConnected)

            Button("Send", systemImage: "arrow.up", action: send)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!hub.isConnected || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(14)
        .help(hub.isConnected ? "" : "Connect the Company Hub to message agents.")
    }

    private func send() {
        let message = draft
        draft = ""
        Task { await hub.send(message) }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
