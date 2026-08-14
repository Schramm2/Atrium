import NotiveCore
import SwiftUI

/// The newest activity lines, with a link to the full feed.
struct LatestActivityPanel: View {
    @Bindable var store: AppStore
    @Environment(CompanyHubStore.self) private var hub
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        BrandPanel(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Latest activity".uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.4)
                    .foregroundStyle(.secondary)

                if hub.activity.isEmpty {
                    Text("Shared workspace activity appears here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(hub.activity.prefix(3)) { event in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(event.tint.color(palette))
                                .frame(width: 7, height: 7)
                                .padding(.top, 5)
                            Text("\(line(for: event))")
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                Button("All activity", action: openActivity)
                    .buttonStyle(.link)
                    .font(.caption.weight(.semibold))
            }
        }
    }

    private func line(for event: HubActivityEvent) -> Text {
        let who = Text(event.who).fontWeight(.semibold)
        let what = Text(" \(event.what) · ").foregroundStyle(palette.secondaryText)
        let when = Text(event.occurredAt, format: .relative(presentation: .numeric))
            .foregroundStyle(palette.secondaryText.opacity(0.7))
        return Text("\(who)\(what)\(when)")
    }

    private func openActivity() {
        store.select(.activity)
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
