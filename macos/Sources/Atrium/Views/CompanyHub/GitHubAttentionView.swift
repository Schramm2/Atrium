import AtriumCore
import SwiftUI

struct GitHubAttentionView: View {
    let items: [GitHubWorkItem]
    let favoriteFullNames: Set<String>
    @State private var showsAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader(title: "Needs your attention") {
                BrandStatusLabel(
                    title: items.isEmpty ? "All clear" : "\(items.count) open",
                    systemImage: items.isEmpty ? "checkmark.circle" : "exclamationmark.circle",
                    kind: items.isEmpty ? .success : .warning
                )
            }

            BrandPanel(padding: 0) {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Nothing needs your attention",
                        systemImage: "checkmark.circle",
                        description: Text("Reviews, requested changes, merge-ready work, assigned issues, failed checks, and stale pull requests appear here.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                            GitHubWorkItemRow(
                                item: item,
                                isFavorite: favoriteFullNames.contains(item.repositoryFullName)
                            )
                            if index < visibleItems.count - 1 || items.count > visibleItems.count { Divider() }
                        }
                        if items.count > 12 {
                            Button(showsAll ? "Show fewer" : "Show all \(items.count)") {
                                showsAll.toggle()
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.tint)
                            .padding(16)
                        }
                    }
                }
            }
        }
    }

    private var visibleItems: ArraySlice<GitHubWorkItem> {
        items.prefix(showsAll ? items.count : 12)
    }
}
