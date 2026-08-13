import NotiveCore
import SwiftUI

/// Divider-separated tiles for `HomeWorkflowStrip`.
struct HomeWorkflowTiles: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let actions: [HomeWorkflowAction]
    @Bindable var store: AppStore

    var body: some View {
        ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
            Button {
                store.select(action.id)
            } label: {
                HStack(spacing: 11) {
                    Image(systemName: action.systemImage)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(palette.secondaryAccent)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(action.title)
                            .font(.subheadline.weight(.semibold))
                        Text(action.detail)
                            .font(.caption)
                            .foregroundStyle(palette.secondaryText)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if index < actions.count - 1 {
                Divider().padding(.vertical, 12)
            }
        }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
