import NotiveCore
import SwiftUI

/// One row in the Shared Context table.
struct SharedContextRow: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let item: HubItem

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: item.kind.symbolName)
                    .foregroundStyle(item.tint.color(palette))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(item.excerpt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.sharedBy)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)

            HubTag(title: item.kind.title)
                .frame(width: 110, alignment: .leading)

            Text(item.sharedAt, format: .relative(presentation: .numeric))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.tertiary)
                .frame(width: 90, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
