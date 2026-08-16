import AppKit
import AtriumCore
import SwiftUI

struct GitHubRepositoryTable: View {
    @Environment(GitHubRepositoryStore.self) private var github
    @State private var selection = Set<GitHubRepository.ID>()
    @State private var selectedRepository: GitHubRepository?
    @State private var sortOrder = [
        KeyPathComparator(\GitHubRepository.updatedAt, order: .reverse),
    ]
    let repositories: [GitHubRepository]

    var body: some View {
        Table(sortedRepositories, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("") { repository in
                Button(
                    github.isFavorite(repository) ? "Remove from favourites" : "Add to favourites",
                    systemImage: github.isFavorite(repository) ? "star.fill" : "star"
                ) {
                    github.toggleFavorite(repository)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor.opacity(github.isFavorite(repository) ? 1 : 0.55))
                .help(github.isFavorite(repository) ? "Remove from favourites" : "Add to favourites")
            }
            .width(28)

            TableColumn("Repository", value: \GitHubRepository.fullName) { repository in
                Button(repository.fullName) {
                    selectedRepository = repository
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .help(repository.description ?? repository.fullName)
            }
            .width(min: 220, ideal: 340)

            TableColumn("Language", value: \GitHubRepository.languageTitle)
                .width(min: 80, ideal: 110)

            TableColumn("Open items", value: \GitHubRepository.openItemCount) { repository in
                Text(repository.openItemCount, format: .number)
                    .monospacedDigit()
            }
            .width(min: 80, ideal: 90)

            TableColumn("Visibility", value: \GitHubRepository.visibilityTitle)
                .width(min: 80, ideal: 100)

            TableColumn("Updated", value: \GitHubRepository.updatedAt) { repository in
                Text(repository.updatedAt, format: .relative(presentation: .numeric))
                    .monospacedDigit()
            }
            .width(min: 100, ideal: 120)
        }
        .frame(minHeight: 360, idealHeight: 520, maxHeight: 720)
        .contextMenu(forSelectionType: GitHubRepository.ID.self) { identifiers in
            if let repository = repository(for: identifiers) {
                Button("Copy URL", systemImage: "link") {
                    copy(repository.url.absoluteString)
                }
                Button("Copy clone command", systemImage: "terminal") {
                    copy("gh repo clone \(repository.fullName)")
                }
                Divider()
                Button("Open in browser", systemImage: "safari") {
                    NSWorkspace.shared.open(repository.url)
                }
            }
        } primaryAction: { identifiers in
            selectedRepository = repository(for: identifiers)
        }
        .sheet(item: $selectedRepository) { repository in
            GitHubRepositoryDetailView(repository: repository)
        }
    }

    private var sortedRepositories: [GitHubRepository] {
        repositories.sorted(using: sortOrder)
    }

    private func repository(for identifiers: Set<GitHubRepository.ID>) -> GitHubRepository? {
        guard let id = identifiers.first else { return nil }
        return repositories.first { $0.id == id }
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
