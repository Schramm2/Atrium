import AtriumCore
import SwiftUI

/// Divider-separated stat cells for `CompanyStatStrip`.
struct CompanyStatCells: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let stats: [HubStat]

    var body: some View {
        ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.label.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(.secondary)
                Text(stat.value)
                    .font(.largeTitle.weight(.heavy).monospacedDigit())
                Text(stat.delta)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(stat.tone.color(palette))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .accessibilityElement(children: .combine)

            if index < stats.count - 1 {
                Divider().padding(.vertical, 12)
            }
        }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
