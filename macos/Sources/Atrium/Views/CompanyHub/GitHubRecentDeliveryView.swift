import AtriumCore
import SwiftUI

struct GitHubRecentDeliveryView: View {
    let items: [GitHubWorkItem]
    let favoriteFullNames: Set<String>
    @State private var showsAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader(title: "Recent delivery") {
                Text("\(items.count) merges · \(repositoryCount) repos")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            BrandPanel(padding: 0) {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No recent merges",
                        systemImage: "arrow.triangle.merge",
                        description: Text("Pull requests merged in the last 14 days appear here.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                            GitHubWorkItemRow(
                                item: item,
                                isFavorite: favoriteFullNames.contains(item.repositoryFullName)
                            )
                            if index < visibleItems.count - 1 || items.count > visibleItems.count { Divider() }
                        }

                        if items.count > 5 {
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
        items.prefix(showsAll ? items.count : 5)
    }

    private var repositoryCount: Int {
        Set(items.map(\.repositoryFullName)).count
    }
}
