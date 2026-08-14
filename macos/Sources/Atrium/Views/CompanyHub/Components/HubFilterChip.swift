import SwiftUI

/// A selectable pill used for the Shared Context filters.
struct HubFilterChip: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.caption.weight(.bold))
            .foregroundStyle(isSelected ? palette.onAccent : palette.secondaryText)
            .padding(.horizontal, 13)
            .padding(.vertical, 5)
            .background(isSelected ? palette.accent : Color.clear, in: Capsule())
            .overlay {
                Capsule().stroke(isSelected ? palette.accent : palette.border, lineWidth: 1)
            }
            .contentShape(Capsule())
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
