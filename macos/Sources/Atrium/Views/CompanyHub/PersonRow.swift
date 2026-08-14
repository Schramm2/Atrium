import AtriumCore
import SwiftUI

/// One row in the People directory.
struct PersonRow: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let person: HubPerson

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                HubAvatar(initials: person.initials, tint: person.tint, size: 30)
                Text(person.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if person.isAgent {
                    Text("AGENT")
                        .font(.caption2.weight(.heavy))
                        .tracking(0.4)
                        .foregroundStyle(palette.ai)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .overlay { Capsule().stroke(palette.border, lineWidth: 1) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(person.role)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 160, alignment: .leading)

            HubTag(title: person.company)
                .frame(width: 120, alignment: .leading)

            Text(person.focus)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 200, alignment: .leading)

            HubStatusDot(title: person.status, color: person.statusTone.color(palette))
                .frame(width: 110, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
