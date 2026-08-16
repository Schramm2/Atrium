import AtriumCore
import SwiftUI

struct GitHubFavoritesView: View {
    let repositories: [GitHubRepository]
    let onToggle: (GitHubRepository) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader(title: "Favourites") {
                Text("\(repositories.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            BrandPanel(padding: 0) {
                if repositories.isEmpty {
                    ContentUnavailableView(
                        "No favourite repositories",
                        systemImage: "star",
                        description: Text("Select the star beside a repository to keep important work here.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 160)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(repositories.enumerated()), id: \.element.id) { index, repository in
                            HStack(spacing: 12) {
                                Link(destination: repository.url) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(repository.organizationTitle) / \(repository.name)")
                                            .font(.subheadline.weight(.semibold))
                                        Text(repository.description ?? "No description")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                Text(repository.updatedAt, format: .relative(presentation: .numeric))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.tertiary)

                                Button("Remove from favourites", systemImage: "star.fill") {
                                    onToggle(repository)
                                }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.plain)
                                .frame(width: 28, height: 28)
                                .foregroundStyle(.tint)
                                .help("Remove from favourites")
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)

                            if index < repositories.count - 1 { Divider() }
                        }
                    }
                }
            }
        }
    }
}
