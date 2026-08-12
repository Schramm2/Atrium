import NotiveCore
import SwiftUI

/// One search across the local workspace and the shared hub.
struct SearchEverythingView: View {
    @Environment(CompanyHubStore.self) private var hub
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        @Bindable var hub = hub

        BrandScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    NotivePageHeader(
                        "Search everything",
                        detail: "One search across your meetings, the shared hub, people, and agent runs."
                    )

                    field(query: $hub.searchQuery)

                    if hub.searchGroups.isEmpty {
                        HubEmptyState(
                            title: emptyTitle,
                            systemImage: "magnifyingglass",
                            description: emptyDescription,
                            minHeight: 300
                        )
                    } else {
                        ForEach(hub.searchGroups) { group in
                            SearchResultGroup(group: group)
                        }
                    }

                    HubPrivacyFootnote(
                        text: "Search covers your local workspace plus items shared to the hub. Nothing local is exposed to others."
                    )
                }
                .padding(32)
                .frame(maxWidth: 1_080, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .navigationTitle("Search")
        .onAppear { isFieldFocused = true }
    }

    private var emptyTitle: String {
        hub.searchQuery.isEmpty ? "Search the workspace and the hub" : "No results"
    }

    private var emptyDescription: String {
        if hub.searchQuery.isEmpty {
            "Type a question or a phrase. Results group by meetings, shared context, people, and agent runs."
        } else {
            "Nothing matched. The Company Hub is not connected, so only your local workspace can match."
        }
    }

    private func field(query: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
            TextField("Search everything", text: query)
                .textFieldStyle(.plain)
                .font(.title3.weight(.semibold))
                .focused($isFieldFocused)
                .onSubmit { Task { await hub.search() } }
            Text("⇧⌘K")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .overlay {
                    RoundedRectangle(cornerRadius: 5).stroke(palette.border, lineWidth: 1)
                }
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12).stroke(palette.border, lineWidth: 1)
        }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
