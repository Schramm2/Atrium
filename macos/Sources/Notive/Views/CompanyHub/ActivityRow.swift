import NotiveCore
import SwiftUI

/// One entry in the activity feed.
struct ActivityRow: View {
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    let event: HubActivityEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(event.tint.color(palette))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
                .opacity(event.isRead ? 0.35 : 1)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(headline)")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail = event.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: 640, alignment: .leading)
                        .background(palette.raisedSurface, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8).stroke(palette.border, lineWidth: 1)
                        }
                }
            }

            Spacer(minLength: 8)

            Text(event.occurredAt, format: .relative(presentation: .numeric))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }

    private var headline: Text {
        let who = Text(event.who).fontWeight(.semibold)
        let what = Text(" \(event.what)").foregroundStyle(palette.secondaryText)
        return Text("\(who)\(what)")
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
