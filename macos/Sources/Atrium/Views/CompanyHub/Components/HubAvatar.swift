import AtriumCore
import SwiftUI

/// Initials badge used for people and agents across the Company Hub.
struct HubAvatar: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let initials: String
    var tint: HubTint = .accent
    var size: CGFloat = 30
    var cornerRadius: CGFloat?

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .heavy))
            .foregroundStyle(palette.onAccent)
            .frame(width: size, height: size)
            .background(
                tint.color(palette),
                in: RoundedRectangle(cornerRadius: cornerRadius ?? size / 2)
            )
            .accessibilityHidden(true)
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
