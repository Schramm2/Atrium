import AtriumCore
import SwiftUI

/// A short People list with a link to the full directory.
struct HomePeoplePanel: View {
    @Bindable var store: AppStore
    @Environment(CompanyHubStore.self) private var hub
    @Environment(\.brandTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    private var people: [HubPerson] {
        Array(hub.people.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HubSectionHeader(title: "People") {
                Button("All people") { store.select(.people) }
                    .buttonStyle(.link)
                    .font(.callout.weight(.semibold))
            }

            HubRowPanel(items: people) { person in
                HubRowButton(action: { store.select(.people) }) {
                    HStack(spacing: 12) {
                        HubAvatar(initials: person.initials, tint: person.tint, size: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(person.name)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text(person.role)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        HubStatusDot(
                            title: person.status,
                            color: person.statusTone.color(palette)
                        )
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                }
            }
        }
    }

    private var palette: BrandPalette {
        BrandPalette.palette(for: theme, colorScheme: colorScheme)
    }
}
