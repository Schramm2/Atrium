import AtriumCore
import SwiftUI

struct GitHubWorkItemRow: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let item: GitHubWorkItem
    let isFavorite: Bool

    var body: some View {
        Link(destination: item.url) {
            HStack(spacing: 12) {
                Image(systemName: item.kind.systemImage)
                    .foregroundStyle(tint)
                    .frame(width: 18)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text("\(item.repositoryFullName) #\(item.number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(metadata)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(palette.accent)
                        .accessibilityLabel("Favourite repository")
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.kind.title)
                        .font(.caption.weight(.semibold))
                    Text(item.updatedAt, format: .relative(presentation: .numeric))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens on GitHub")
    }

    private var tint: Color {
        switch item.kind {
        case .reviewRequested, .assignedIssue: palette.accent
        case .changesRequested, .failedChecks, .stalePullRequest: palette.warning
        case .approvedToMerge, .mergedPullRequest: palette.success
        }
    }

    private var metadata: String {
        var values = [item.state.capitalized]
        if let author = item.authorLogin { values.append("@\(author)") }
        values.append("\(item.commentsCount) \(item.commentsCount == 1 ? "comment" : "comments")")
        values += item.labelNames.prefix(3)
        if item.labelNames.count > 3 { values.append("+\(item.labelNames.count - 3)") }
        return values.joined(separator: " · ")
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
