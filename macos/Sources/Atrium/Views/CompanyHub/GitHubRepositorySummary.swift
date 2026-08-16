import AtriumCore
import SwiftUI

struct GitHubRepositorySummary: View {
    let repositories: [GitHubRepository]
    let favoriteCount: Int

    var body: some View {
        BrandPanel {
            HStack(spacing: 24) {
                metric("Repositories", value: repositories.count)
                Divider()
                metric("Favourites", value: favoriteCount)
                Divider()
                metric("Active in 30 days", value: activeCount)
                Divider()
                metric("Open items", value: repositories.reduce(0) { $0 + $1.openItemCount })
            }
        }
    }

    private var activeCount: Int {
        let cutoff = Date.now.addingTimeInterval(-30 * 24 * 60 * 60)
        return repositories.count { $0.updatedAt >= cutoff }
    }


    private func metric(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .number)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
