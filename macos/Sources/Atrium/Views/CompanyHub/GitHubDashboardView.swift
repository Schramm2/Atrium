import AtriumCore
import SwiftUI

struct GitHubDashboardView: View {
    @Environment(GitHubRepositoryStore.self) private var github
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let error = github.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(palette.warning)
            }

            sectionFailure(.attention)
            GitHubAttentionView(
                items: github.attention,
                favoriteFullNames: github.favoriteFullNames
            )

            sectionFailure(.notifications)
            GitHubNotificationsView(notifications: github.notifications)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    favorites
                        .frame(maxWidth: .infinity)
                    recentDelivery
                        .frame(maxWidth: .infinity)
                }
                VStack(alignment: .leading, spacing: 24) {
                    favorites
                    recentDelivery
                }
            }

            sectionFailure(.repositories)
            GitHubRepositoryHealthView()
        }
    }

    private var favorites: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionFailure(.repositories)
            GitHubFavoritesView(
                repositories: github.favoriteRepositories,
                onToggle: github.toggleFavorite
            )
        }
    }

    private var recentDelivery: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionFailure(.recentDelivery)
            GitHubRecentDeliveryView(
                items: github.recentDelivery,
                favoriteFullNames: github.favoriteFullNames
            )
        }
    }

    @ViewBuilder
    private func sectionFailure(_ section: GitHubSnapshotSection) -> some View {
        if let message = github.failureMessage(for: section) {
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(palette.warning)
        }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
