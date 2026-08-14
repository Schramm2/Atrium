import NotiveCore
import SwiftUI

/// One labelled group of search results.
struct SearchResultGroup: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let group: HubSearchGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(group.label.uppercased())
                    .font(.caption.weight(.heavy))
                    .tracking(0.5)
                    .foregroundStyle(.secondary)
                Text("^[\(group.results.count) result](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HubRowPanel(items: group.results) { result in
                HStack(spacing: 12) {
                    Image(systemName: result.symbolName)
                        .foregroundStyle(palette.secondaryAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.title)
                            .font(.subheadline.weight(.semibold))
                        Text(result.snippet)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Text(result.source)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
