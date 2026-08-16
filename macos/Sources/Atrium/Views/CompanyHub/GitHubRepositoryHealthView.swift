import AtriumCore
import SwiftUI

struct GitHubRepositoryHealthView: View {
    @Environment(GitHubRepositoryStore.self) private var github
    @State private var query = ""
    @State private var organization = "All"
    @State private var showArchived = false
    @State private var favoritesOnly = false

    var body: some View {
        let repositories = visibleRepositories

        VStack(alignment: .leading, spacing: 24) {
            HubSectionHeader("Repository health")
            GitHubRepositorySummary(
                repositories: github.repositories,
                favoriteCount: github.favoriteRepositories.count
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    TextField("Filter repositories", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 420)
                    Spacer()
                    Text("\(repositories.count) shown")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    Picker("Organization", selection: $organization) {
                        Text("All").tag("All")
                        ForEach(GitHubIdentityService.companyOrganizations, id: \.self) { organization in
                            Text(organization.caseInsensitiveCompare("first-motive") == .orderedSame ? "First Motive" : organization)
                                .tag(organization)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 420)

                    Toggle("Favourites only", isOn: $favoritesOnly)
                        .toggleStyle(.checkbox)
                    Toggle("Show archived", isOn: $showArchived)
                        .toggleStyle(.checkbox)
                }
            }

            if repositories.isEmpty {
                HubEmptyState(
                    title: "No matching repositories",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: "Change the organization or favourites filter, or include archived repositories.",
                    minHeight: 240
                )
            } else {
                GitHubRepositoryTable(repositories: repositories)
            }
        }
    }

    private var visibleRepositories: [GitHubRepository] {
        github.repositories
            .filter { repository in
                let text = [
                    repository.fullName,
                    repository.description ?? "",
                    repository.language ?? "",
                ].joined(separator: " ")
                return (query.isEmpty || text.localizedCaseInsensitiveContains(query))
                    && (organization == "All" || repository.organization.caseInsensitiveCompare(organization) == .orderedSame)
                    && (showArchived || !repository.isArchived)
                    && (!favoritesOnly || github.isFavorite(repository))
            }
            .sorted { lhs, rhs in
                let lhsFavorite = github.isFavorite(lhs)
                let rhsFavorite = github.isFavorite(rhs)
                if lhsFavorite != rhsFavorite { return lhsFavorite }
                return lhs.updatedAt > rhs.updatedAt
            }
    }
}
