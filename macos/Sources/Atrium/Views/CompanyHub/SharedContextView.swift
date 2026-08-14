import AtriumCore
import SwiftUI

/// Shared Context list — meetings, notes, and agent output the team chose to share.
struct SharedContextView: View {
    @Environment(CompanyHubStore.self) private var hub
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        @Bindable var hub = hub

        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AtriumPageHeader(
                        "Shared Context",
                        detail: "Meetings, notes, and agent output the team chose to share — the company's working memory."
                    ) {
                        Button("Share from my workspace", systemImage: "plus") {}
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .disabled(!hub.isConnected)
                            .help(hub.isConnected ? "" : "Connect the Company Hub to share items.")
                    }

                    filters(selection: $hub.itemFilter)

                    if hub.visibleSharedItems.isEmpty {
                        HubEmptyState.notConnected(
                            "Nothing shared",
                            systemImage: "square.stack.3d.up",
                            appears: "Items the team shares from their own Macs appear here, with who shared them and when.",
                            minHeight: 300
                        )
                    } else {
                        itemTable(items: hub.visibleSharedItems)
                    }

                    HubPrivacyFootnote(
                        text: "Sharing is always a per-item choice by its owner, and can be withdrawn at any time."
                    )
                }
                .padding(32)
                .frame(maxWidth: 1_280, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Shared Context")
        .task { await hub.loadSharedItems() }
    }

    private func filters(selection: Binding<HubItemFilter>) -> some View {
        HStack(spacing: 8) {
            ForEach(HubItemFilter.allCases) { filter in
                HubFilterChip(title: filter.title, isSelected: filter == selection.wrappedValue) {
                    selection.wrappedValue = filter
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filter shared items")
    }

    private func itemTable(items: [HubItem]) -> some View {
        VStack(spacing: 0) {
            HubTableHeader(
                columns: ["Item", "Shared by", "Source", "Shared"],
                widths: [nil, 110, 110, 90]
            )
            Divider()
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                SharedContextRow(item: item)
                if index < items.count - 1 { Divider() }
            }
        }
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12).stroke(palette.border, lineWidth: 1)
        }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
