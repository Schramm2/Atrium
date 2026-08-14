import AtriumCore
import SwiftUI

/// Shared work that waits for a decision from the person at this Mac.
struct HomeAttentionPanel: View {
    @Bindable var store: AppStore
    @Environment(CompanyHubStore.self) private var hub
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader(title: "Needs your attention") {
                Text("\(hub.attention.count) item\(hub.attention.count == 1 ? "" : "s")")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HubRowPanel(items: hub.attention) { item in
                HubRowButton(action: { open(item) }) {
                    HStack(spacing: 12) {
                        Image(systemName: item.symbolName)
                            .font(.body)
                            .foregroundStyle(item.tone.color(palette))
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        Text(item.tag)
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(item.tone.color(palette))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .overlay { Capsule().stroke(palette.border, lineWidth: 1) }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func open(_ item: HubAttentionItem) {
        store.select(item.destination.selection)
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}

extension HubAttentionDestination {
    /// The workspace screen this attention item opens.
    var selection: WorkspaceSelection {
        switch self {
        case .agents: .agents
        case .sharedContext: .sharedContext
        case .activity: .activity
        }
    }
}
