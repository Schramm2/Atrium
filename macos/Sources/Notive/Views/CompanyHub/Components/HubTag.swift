import SwiftUI

/// An outlined capsule used for item kinds and company names.
struct HubTag: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let title: String

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(palette.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .overlay { Capsule().stroke(palette.border, lineWidth: 1) }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
