import SwiftUI

/// Column heading strip for the table-style Company Hub panels.
///
/// `columns` and `widths` must hold the same number of entries. A `nil` width makes that
/// column flexible.
struct HubTableHeader: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let columns: [String]
    let widths: [CGFloat?]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, title in
                Text(title.uppercased())
                    .font(.caption2.weight(.heavy))
                    .tracking(0.5)
                    .foregroundStyle(palette.secondaryText.opacity(0.7))
                    .frame(
                        maxWidth: widths[index] ?? .infinity,
                        alignment: .leading
                    )
                    .frame(width: widths[index], alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .accessibilityHidden(true)
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
