import AtriumCore
import SwiftUI

struct GitHubDetailItemList: View {
    let title: String
    let emptyTitle: String
    let systemImage: String
    let items: [GitHubRepositoryDetailItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            BrandPanel(padding: 0) {
                if items.isEmpty {
                    ContentUnavailableView(emptyTitle, systemImage: systemImage)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        Link(destination: item.url) {
                            HStack(spacing: 12) {
                                Text("#\(item.number)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Text(item.title)
                                    .lineLimit(1)
                                Spacer()
                                Text(item.updatedAt, format: .relative(presentation: .numeric))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if index < items.count - 1 { Divider() }
                    }
                }
            }
        }
    }
}
